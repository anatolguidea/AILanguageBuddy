"""
ELingo Voice Service — Low-latency TTS + STT powered by Chatterbox & Whisper.

Key design decisions:
  • TTS endpoints use StreamingResponse (chunked PCM16) for minimal TTFB.
  • Transcribe endpoints are plain `def` so FastAPI runs them in a threadpool,
    keeping the async event loop free for health checks and concurrent requests.
  • STT backend is selected at startup: mlx-whisper on Apple Silicon (MPS),
    faster-whisper on CUDA/CPU.
  • Input validation returns 400 (not 422) for empty/whitespace-only text.
"""

from __future__ import annotations

import io
import re
import logging
import os
import shutil
import sys
import threading
import traceback
import wave
from collections import OrderedDict
from contextlib import asynccontextmanager
from typing import Callable, Generator

import numpy as np
import torch
import torchaudio  # noqa: F401 — needed for Chatterbox internals
import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, Query, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response, StreamingResponse
from pydantic import BaseModel, field_validator

# ─── Logging ────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("voice-service")

# ─── Device selection ───────────────────────────────────────────────

def _select_device() -> str:
    """Pick the best available torch device: cuda > mps > cpu."""
    if torch.cuda.is_available():
        return "cuda"
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return "mps"
    return "cpu"

MODEL_DEVICE = _select_device()

# faster-whisper only supports cuda/cpu — mlx-whisper handles MPS natively
STT_BACKEND: str = "none"  # set during lifespan
FIRST_AUDIO_BURST_BYTES = 4 * 1024

# ─── Module-level state (replaces scattered globals) ────────────────
tts_model = None
stt_model = None
tts_lock = threading.Lock()
tts_state_lock = threading.Lock()
is_synthesizing = False
_tts_warmup_lock = threading.Lock()
_tts_last_warmup_at = 0.0
_TTS_WARMUP_COOLDOWN_S = 15.0

# ─── Supported languages (ISO 639-1 codes) ─────────────────────────
# Chatterbox Multilingual v1 supports 23 languages.
# This set is used for validation — unsupported codes fall back to "en".
SUPPORTED_LANGUAGES: frozenset[str] = frozenset({
    "en", "es", "fr", "de", "it", "pt", "nl", "pl", "ro", "sv",
    "da", "fi", "hu", "cs", "sk", "bg", "hr", "sl", "uk", "ru",
    "ja", "zh", "ko",
})

def _validate_language(lang: str) -> str:
    """Return a valid language_id, falling back to 'en' with a warning."""
    code = lang.strip().lower()[:2]
    if code in SUPPORTED_LANGUAGES:
        return code
    logger.warning(f"Unsupported language '{lang}' — falling back to 'en'.")
    return "en"


def _maybe_empty_mps_cache(reason: str) -> None:
    """Free MPS cache opportunistically to reduce memory pressure stalls."""
    try:
        if MODEL_DEVICE == "mps" and hasattr(torch, "mps") and hasattr(torch.mps, "empty_cache"):
            torch.mps.empty_cache()
            logger.info(f"[ailanguagebuddy-perf] torch.mps.empty_cache() after {reason}")
    except Exception as e:
        logger.warning(f"[ailanguagebuddy-perf] Failed to empty MPS cache ({reason}): {e}")


def _enable_tts_use_cache(model: object) -> None:
    """Best-effort cache enabling for faster autoregressive generation."""
    try:
        cfg = getattr(model, "config", None)
        if cfg is not None and hasattr(cfg, "use_cache"):
            cfg.use_cache = True
        inner_model = getattr(model, "model", None)
        if inner_model is not None:
            inner_cfg = getattr(inner_model, "config", None)
            if inner_cfg is not None and hasattr(inner_cfg, "use_cache"):
                inner_cfg.use_cache = True
        logger.info("[ailanguagebuddy-perf] Enabled use_cache=True for TTS model (best effort)")
    except Exception as e:
        logger.warning(f"[ailanguagebuddy-perf] Could not enable use_cache on TTS model: {e}")


def _warmup_tts_async(reason: str) -> None:
    """Run a tiny background warmup so TTS is ready right after STT."""
    import time

    global _tts_last_warmup_at
    if tts_model is None:
        return
    now = time.time()
    if now - _tts_last_warmup_at < _TTS_WARMUP_COOLDOWN_S:
        return
    _tts_last_warmup_at = now

    def _runner() -> None:
        try:
            with _tts_warmup_lock:
                if tts_model is None:
                    return
                with tts_lock:
                    with torch.inference_mode(), torch.no_grad():
                        try:
                            _ = tts_model.generate("ready", max_new_tokens=12, use_cache=True)
                        except TypeError:
                            try:
                                _ = tts_model.generate("ready", max_new_tokens=12)
                            except TypeError:
                                _ = tts_model.generate("ready")
            logger.info(f"[ailanguagebuddy-perf] TTS warmup complete ({reason})")
        except Exception as e:
            logger.warning(f"[ailanguagebuddy-perf] TTS warmup skipped ({reason}): {e}")

    threading.Thread(target=_runner, daemon=True, name="tts-warmup").start()

# ─── Word-level TTS cache (LRU, max 500 entries) ───────────────────
_WORD_CACHE_MAX = 500
_word_audio_cache: OrderedDict[str, bytes] = OrderedDict()

_TTS_CHUNK_BYTES = 8192  # streaming chunk size for PCM16


def _cache_key(text: str, lang: str) -> str:
    return f"{lang}:{text.lower().strip()}"


def _cache_put(key: str, audio_bytes: bytes) -> None:
    if key in _word_audio_cache:
        _word_audio_cache.move_to_end(key)
        return
    _word_audio_cache[key] = audio_bytes
    while len(_word_audio_cache) > _WORD_CACHE_MAX:
        _word_audio_cache.popitem(last=False)


def _cache_get(key: str) -> bytes | None:
    if key in _word_audio_cache:
        _word_audio_cache.move_to_end(key)
        return _word_audio_cache[key]
    return None


# ─── Pydantic models ───────────────────────────────────────────────

class SpeakRequest(BaseModel):
    text: str
    language: str = "en"

    @field_validator("text")
    @classmethod
    def text_must_not_be_empty(cls, v: str) -> str:
        stripped = v.strip()
        if not stripped:
            raise ValueError("text must not be empty or whitespace-only")
        return stripped


# ─── STT loader helpers ─────────────────────────────────────────────

def _load_mlx_whisper() -> object | None:
    """Try loading mlx-whisper (Apple Silicon GPU-accelerated STT)."""
    try:
        import mlx_whisper  # noqa: F811
        logger.info("mlx-whisper loaded — Apple Silicon GPU STT active.")
        return mlx_whisper
    except ImportError:
        logger.warning("mlx-whisper not installed; falling back.")
        return None


def _load_faster_whisper(device: str) -> object | None:
    """Try loading faster-whisper (CUDA / CPU STT)."""
    try:
        from faster_whisper import WhisperModel
        compute_type = "int8" if device == "cpu" else "float16"
        model = WhisperModel("tiny", device=device, compute_type=compute_type)
        logger.info(f"faster-whisper loaded on {device} ({compute_type}).")
        return model
    except Exception as e:
        logger.error(f"Failed to load faster-whisper: {e}")
        return None


_FFMPEG_AVAILABLE: bool = False

def _check_ffmpeg() -> bool:
    """Check if ffmpeg is on PATH. Log warning if missing."""
    global _FFMPEG_AVAILABLE
    _FFMPEG_AVAILABLE = shutil.which("ffmpeg") is not None
    if not _FFMPEG_AVAILABLE:
        logger.warning(
            "ffmpeg not found on PATH. "
            "The service will work for WAV/PCM input (decoded in-process), "
            "but exotic formats (mp3, ogg, etc.) won't be supported. "
            "Install with: brew install ffmpeg"
        )
    else:
        logger.info("ffmpeg detected on PATH.")
    return _FFMPEG_AVAILABLE


def _wav_bytes_to_float32(wav_bytes: io.BytesIO) -> np.ndarray:
    """
    Decode WAV bytes to a float32 numpy array at 16 kHz mono.
    This avoids calling ffmpeg for the common WAV/PCM case.
    """
    with wave.open(wav_bytes, "rb") as wf:
        n_channels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        framerate = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)

    # Decode to float32
    if sampwidth == 2:
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    elif sampwidth == 4:
        samples = np.frombuffer(raw, dtype=np.int32).astype(np.float32) / 2147483648.0
    else:
        raise ValueError(f"Unsupported sample width: {sampwidth}")

    # Mix to mono if stereo
    if n_channels > 1:
        samples = samples.reshape(-1, n_channels).mean(axis=1)

    # Resample to 16 kHz if needed (simple linear interpolation)
    if framerate != 16000:
        duration = len(samples) / framerate
        target_len = int(duration * 16000)
        samples = np.interp(
            np.linspace(0, len(samples) - 1, target_len),
            np.arange(len(samples)),
            samples,
        ).astype(np.float32)

    return samples


# ─── Application lifespan ──────────────────────────────────────────

from huggingface_hub import login  # noqa: E402 — after logging setup

@asynccontextmanager
async def lifespan(app: FastAPI):
    global tts_model, stt_model, STT_BACKEND

    # ── System dependency checks ──
    _check_ffmpeg()

    # ── Hugging Face auth ──
    hf_token = os.getenv("HF_TOKEN")
    if hf_token and hf_token != "your_hugging_face_token_here":
        try:
            login(token=hf_token)
            logger.info("Authenticated with Hugging Face.")
        except Exception as e:
            logger.warning(f"HF auth failed: {e}")
    else:
        logger.info("No HF_TOKEN — gated model loading may fail.")

    # ── TTS — Chatterbox Turbo (English-only, fastest) ──
    logger.info(f"Loading ChatterboxTTS (Turbo) on {MODEL_DEVICE}…")
    try:
        from chatterbox.tts import ChatterboxTTS
        tts_model = ChatterboxTTS.from_pretrained(device=MODEL_DEVICE)
        _enable_tts_use_cache(tts_model)
        logger.info("ChatterboxTTS (Turbo) loaded successfully.")

        try:
            with torch.inference_mode():
                _ = tts_model.generate("System ready.")
            logger.info("Chatterbox warmup done.")
        except Exception as e:
            logger.warning(f"Warmup skipped: {e}")
    except ImportError:
        tts_model = None
        logger.error(
            "ChatterboxTTS not found. Reinstall from source:\n"
            "  pip install git+https://github.com/resemble-ai/chatterbox.git\n"
            "TTS unavailable, STT will still work."
        )
    except Exception as e:
        tts_model = None
        if "gated" in str(e).lower() or "401" in str(e) or "403" in str(e):
            logger.error(
                "Chatterbox is a gated model. "
                "Ensure HF_TOKEN has access to 'ResembleAI/chatterbox'. "
                "Request access at: https://huggingface.co/ResembleAI/chatterbox"
            )
        logger.error(f"Chatterbox load failed: {e} — TTS unavailable, STT will still work.")

    # ── STT — pick best backend for the hardware ──
    if MODEL_DEVICE == "mps":
        # Apple Silicon: prefer mlx-whisper (GPU-accelerated via MLX)
        mlx = _load_mlx_whisper()
        if mlx is not None:
            stt_model = mlx
            STT_BACKEND = "mlx-whisper"
        else:
            stt_model = _load_faster_whisper("cpu")
            STT_BACKEND = "faster-whisper" if stt_model else "none"
    elif torch.cuda.is_available():
        stt_model = _load_faster_whisper("cuda")
        STT_BACKEND = "faster-whisper" if stt_model else "none"
    else:
        stt_model = _load_faster_whisper("cpu")
        STT_BACKEND = "faster-whisper" if stt_model else "none"

    logger.info(f"STT backend: {STT_BACKEND}")
    yield


app = FastAPI(lifespan=lifespan, title="ELingo Voice Service")

# ─── Health ─────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "tts_device": MODEL_DEVICE,
        "tts_model": "chatterbox-multilingual-v1",
        "tts_loaded": tts_model is not None,
        "stt_backend": STT_BACKEND,
        "stt_loaded": stt_model is not None,
        "tts_sample_rate": 24000,
        "supported_languages": sorted(SUPPORTED_LANGUAGES),
        "ffmpeg_available": _FFMPEG_AVAILABLE,
    }


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  STT ENDPOINTS (sync `def` — run in threadpool, don't block event loop)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def _wrap_pcm_as_wav(pcm: bytes, sample_rate: int = 16000) -> io.BytesIO:
    """Wrap raw PCM (16-bit, mono) in a WAV container with caller-provided sample rate."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm)
    buf.seek(0)
    return buf


def _transcribe_internal(
    raw_bytes: bytes,
    beam_size: int,
    max_words: int | None = None,
    sample_rate: int = 16000,
) -> dict:
    """
    Shared transcription logic.  Handles both raw PCM and WAV input.
    This is a plain function (not async) — called from sync endpoint handlers
    so FastAPI schedules it in the default threadpool.
    """
    if not stt_model:
        logger.warning("STT not loaded — returning mock.")
        return {"text": "Hello AI, how are you?"}

    logger.info(
        f"Transcribing {len(raw_bytes)} bytes (beam={beam_size}, declared_sample_rate={sample_rate})"
    )

    # Debug: Check audio energy (silence detection)
    try:
        import audioop
        # Assume 16-bit input for energy check. 
        # If raw_bytes has header, skip it roughly (44 bytes), else take whole.
        # This is just for logging, does not affect processing.
        pcm_debug = raw_bytes[44:] if raw_bytes.startswith(b"RIFF") else raw_bytes
        rms = audioop.rms(pcm_debug, 2)
        logger.info(f"[ailanguagebuddy-debug] Audio RMS energy: {rms} (len={len(pcm_debug)})")
        if rms < 100:
            logger.warning("[ailanguagebuddy-debug] Audio is extremely quiet (near silence)!")
    except Exception:
        pass

    def _run_backend(audio_data: io.BytesIO) -> str:
        if STT_BACKEND == "mlx-whisper":
            return _transcribe_mlx(audio_data, beam_size)
        return _transcribe_faster_whisper(audio_data, beam_size)

    # Detect format
    if raw_bytes.startswith(b"RIFF"):
        audio_data = io.BytesIO(raw_bytes)
        transcribed = _run_backend(audio_data)
    else:
        # Raw PCM fallback strategy:
        # 1) Use the caller-declared sample rate.
        # 2) If empty transcript, retry common rates (16k, 24k).
        candidate_rates: list[int] = []
        if sample_rate > 0:
            candidate_rates.append(sample_rate)
        for fallback_rate in (16000, 24000):
            if fallback_rate not in candidate_rates:
                candidate_rates.append(fallback_rate)

        transcribed = ""
        chosen_rate = candidate_rates[0]
        for idx, rate in enumerate(candidate_rates):
            audio_data = _wrap_pcm_as_wav(raw_bytes, sample_rate=rate)
            transcribed = _run_backend(audio_data)
            chosen_rate = rate
            if transcribed.strip():
                if idx > 0:
                    logger.warning(
                        "Raw PCM transcript recovered with fallback sample_rate=%s",
                        rate,
                    )
                break
            logger.warning("Empty transcript for raw PCM with sample_rate=%s; retrying", rate)
        logger.info("Raw PCM decoded using sample_rate=%s", chosen_rate)

    if max_words and transcribed:
        words = transcribed.split()
        transcribed = " ".join(words[:max_words])

    _warmup_tts_async("post-stt")
    logger.info(f"Transcript: '{transcribed}'")
    return {"text": transcribed}


def _transcribe_mlx(audio_data: io.BytesIO, beam_size: int) -> str:
    """
    Transcribe using mlx-whisper (Apple Silicon GPU).
    Passes a float32 numpy array directly — no ffmpeg required.
    Note: mlx-whisper only supports greedy decoding; beam_size is accepted
    for API compatibility but ignored.
    """
    try:
        import mlx_whisper
        audio_np = _wav_bytes_to_float32(audio_data)
        logger.info(f"MLX transcribe: {len(audio_np)} samples ({len(audio_np)/16000:.1f}s)")
        # mlx-whisper does NOT support beam search — use greedy decoding only
        result = mlx_whisper.transcribe(
            audio_np,
            path_or_hf_repo="mlx-community/whisper-tiny",
        )
        return result.get("text", "").strip()
    except FileNotFoundError as e:
        if "ffmpeg" in str(e).lower():
            logger.error(
                "ffmpeg not found. Install with: brew install ffmpeg. "
                "Note: For WAV/PCM input this should not happen — "
                "please report this as a bug."
            )
            raise HTTPException(
                status_code=503,
                detail="STT unavailable: ffmpeg not installed. Run: brew install ffmpeg",
            )
        raise


def _transcribe_faster_whisper(audio_data: io.BytesIO, beam_size: int) -> str:
    """Transcribe using faster-whisper (CUDA / CPU)."""
    segments, _ = stt_model.transcribe(
        audio_data,
        beam_size=beam_size,
        compression_ratio_threshold=2.4,
        no_speech_threshold=0.6,
    )
    return " ".join(seg.text for seg in segments).strip()


@app.post("/transcribe")
def transcribe(
    file: UploadFile = File(...),
    sample_rate: int = Form(default=16000, ge=8000, le=48000),
):
    """Full-quality transcription (beam=5). Sync def → threadpool."""
    try:
        contents = file.file.read()
        return _transcribe_internal(contents, beam_size=5, sample_rate=sample_rate)
    except HTTPException:
        raise
    except FileNotFoundError as e:
        logger.error(f"Missing system binary: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"STT unavailable: missing system dependency ({e}). Install ffmpeg: brew install ffmpeg",
        )
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/transcribe/partial")
def transcribe_partial(
    file: UploadFile = File(...),
    sample_rate: int = Form(default=16000, ge=8000, le=48000),
    max_words: int = Query(default=20, ge=3, le=60),
):
    """Fast partial transcription (beam=1). Sync def → threadpool."""
    try:
        contents = file.file.read()
        return _transcribe_internal(
            contents,
            beam_size=1,
            max_words=max_words,
            sample_rate=sample_rate,
        )
    except HTTPException:
        raise
    except FileNotFoundError as e:
        logger.error(f"Missing system binary: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"STT unavailable: missing system dependency ({e}). Install ffmpeg: brew install ffmpeg",
        )
    except Exception as e:
        logger.error(f"Partial transcription error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  TTS ENDPOINTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TTS_OUTPUT_SAMPLE_RATE = 24000
TTS_OUTPUT_BITS = 16
TTS_OUTPUT_CHANNELS = 1


def _wav_to_pcm16_bytes(wav_tensor: torch.Tensor) -> bytes:
    """Convert a Chatterbox wav tensor to raw PCM16 mono bytes (24kHz, 16-bit, 1ch)."""
    if hasattr(wav_tensor, "cpu"):
        wav_tensor = wav_tensor.cpu()
    arr = wav_tensor.numpy() if hasattr(wav_tensor, "numpy") else np.array(wav_tensor)
    arr = arr.squeeze().astype(np.float32)  # ensure float32 before scaling
    pcm = np.clip(arr, -1.0, 1.0)
    pcm = (pcm * 32767).astype(np.int16)
    return pcm.tobytes()


import struct

def _make_wav_header(
    sample_rate: int = TTS_OUTPUT_SAMPLE_RATE,
    bits_per_sample: int = TTS_OUTPUT_BITS,
    num_channels: int = TTS_OUTPUT_CHANNELS,
    data_size: int = 0xFFFFFFFF,
) -> bytes:
    """
    Build a 44-byte RIFF/WAVE header.

    For streaming, use data_size=0xFFFFFFFF (unknown length).
    For complete files, pass the actual PCM data size.
    """
    byte_rate = sample_rate * num_channels * (bits_per_sample // 8)
    block_align = num_channels * (bits_per_sample // 8)
    # RIFF chunk size = 36 + data_size (capped at 0xFFFFFFFF)
    riff_size = min(36 + data_size, 0xFFFFFFFF)
    return struct.pack(
        '<4sI4s'     # RIFF header
        '4sIHHIIHH'  # fmt  sub-chunk
        '4sI',       # data sub-chunk header
        b'RIFF', riff_size, b'WAVE',
        b'fmt ', 16, 1,  # PCM format
        num_channels, sample_rate, byte_rate, block_align, bits_per_sample,
        b'data', data_size,
    )


_WAV_STREAM_HEADER = _make_wav_header(data_size=0xFFFFFFFF)  # "infinite" streaming WAV


# 0.1s silence buffer at 24kHz PCM16 mono = 2400 samples × 2 bytes
_SILENCE_BUFFER = b'\x00' * (TTS_OUTPUT_SAMPLE_RATE // 10 * (TTS_OUTPUT_BITS // 8))


def _split_for_fast_ttfb(text: str) -> list[str]:
    """
    Lightweight splitter for low TTFB:
      - emits first 5 words immediately
      - then uses simple punctuation split for the remainder.
    """
    stripped = text.strip()
    if not stripped:
        return []
    words = stripped.split()
    if len(words) <= 5:
        return [stripped]

    first = " ".join(words[:5])
    rest = " ".join(words[5:])
    for punct in ("?", "!"):
        rest = rest.replace(punct, ".")
    tail = [p.strip() for p in rest.split(".") if p.strip()]
    return [first, *tail]


def _dynamic_max_new_tokens(segment_text: str) -> int:
    return max(12, min(220, max(1, len(segment_text)) * 2))


def _iter_tts_chunks(segment_text: str, max_new_tokens: int) -> Generator[bytes, None, None]:
    """Yield PCM16 chunks as soon as model produces them."""
    with tts_lock:
        with torch.inference_mode(), torch.no_grad():
            if hasattr(tts_model, "generate_stream"):
                try:
                    stream = tts_model.generate_stream(
                        segment_text,
                        max_new_tokens=max_new_tokens,
                        use_cache=True,
                    )
                except TypeError:
                    try:
                        stream = tts_model.generate_stream(
                            segment_text,
                            max_new_tokens=max_new_tokens,
                        )
                    except TypeError:
                        stream = tts_model.generate_stream(segment_text)
                for chunk_tensor in stream:
                    yield _wav_to_pcm16_bytes(chunk_tensor)
            else:
                try:
                    wav = tts_model.generate(
                        segment_text,
                        max_new_tokens=max_new_tokens,
                        use_cache=True,
                    )
                except TypeError:
                    try:
                        wav = tts_model.generate(segment_text, max_new_tokens=max_new_tokens)
                    except TypeError:
                        wav = tts_model.generate(segment_text)
                yield _wav_to_pcm16_bytes(wav)


# ── Concurrency control: cancel stale TTS requests ──
_tts_cancel_event = threading.Event()  # Set to cancel the current TTS stream


def _try_start_synthesis() -> bool:
    global is_synthesizing
    with tts_state_lock:
        if is_synthesizing:
            return False
        is_synthesizing = True
        return True


def _finish_synthesis() -> None:
    global is_synthesizing
    with tts_state_lock:
        is_synthesizing = False
    # Clear cache only after the whole streaming turn completed.
    _maybe_empty_mps_cache("post-turn")


def _synthesize_stream(
    text: str,
    language: str = "en",
    include_wav_header: bool = True,
) -> Generator[bytes, None, None]:
    """
    Generator that yields low-latency audio chunks.

    Strategy:
      1. Optionally sends WAV header immediately (pre-emptive player warmup).
      2. Splits text with a very lightweight strategy; first 5 words are prioritized.
      3. Yields PCM chunks as soon as generated (no EOS wait).
      4. Inserts tiny silence between segments.
      5. Checks cancel event between segments/chunks.
    """
    import time

    if include_wav_header:
        # Pre-emptive strike: allow clients to start playback before model thinks.
        yield _WAV_STREAM_HEADER

    if not tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")

    lang = _validate_language(language)
    segments = _split_for_fast_ttfb(text)
    if not segments:
        segments = [text]

    stream_start = time.perf_counter()
    first_byte_logged = False
    first_burst = bytearray()

    for idx, segment in enumerate(segments):
        # ── Check if a newer request has cancelled us ──
        if _tts_cancel_event.is_set():
            logger.info(f"[ailanguagebuddy-perf] TTS stream cancelled at segment {idx+1}/{len(segments)}")
            return

        max_new_tokens = 40 if idx == 0 else _dynamic_max_new_tokens(segment)

        try:
            sent_start = time.perf_counter()
            logger.info(
                "[ailanguagebuddy-perf] TTS segment %s/%s (max_new_tokens=%s): %r",
                idx + 1,
                len(segments),
                max_new_tokens,
                segment[:80],
            )

            for chunk_bytes in _iter_tts_chunks(segment, max_new_tokens=max_new_tokens):
                if _tts_cancel_event.is_set():
                    logger.info("[ailanguagebuddy-perf] TTS cancelled mid-stream")
                    return

                if not first_byte_logged:
                    first_burst.extend(chunk_bytes)
                    if len(first_burst) >= FIRST_AUDIO_BURST_BYTES:
                        ttfb = time.perf_counter() - stream_start
                        logger.info(f"[ailanguagebuddy-perf] TTFB(first {FIRST_AUDIO_BURST_BYTES}B): {ttfb:.3f}s")
                        yield bytes(first_burst)
                        first_burst.clear()
                        first_byte_logged = True
                else:
                    yield chunk_bytes

            if not first_byte_logged and first_burst:
                ttfb = time.perf_counter() - stream_start
                logger.info(f"[ailanguagebuddy-perf] TTFB(first bytes): {ttfb:.3f}s")
                yield bytes(first_burst)
                first_burst.clear()
                first_byte_logged = True

            sent_dur = time.perf_counter() - sent_start
            logger.info(f"[ailanguagebuddy-perf] Segment {idx+1} done in {sent_dur:.3f}s")

            # ── Silence buffer between sentences (prevents clipping) ──
            if idx < len(segments) - 1:
                yield _SILENCE_BUFFER

        except Exception as e:
            logger.error(f"[ailanguagebuddy-perf] Segment {idx+1} FAILED for lang={lang}, text={segment[:60]!r}: {e}")
            continue

    total = time.perf_counter() - stream_start
    logger.info(f"[ailanguagebuddy-perf] Total TTS stream: {total:.3f}s for {len(segments)} segment(s)")


def _synthesize_full(text: str, language: str = "en") -> bytes:
    """Full synthesis to bytes with WAV header (used by cached word endpoint)."""
    # _synthesize_stream can include a streaming header; full files need exact-size header.
    all_chunks = list(_synthesize_stream(text, language=language, include_wav_header=False))
    pcm_data = b"".join(all_chunks)
    header = _make_wav_header(data_size=len(pcm_data))
    return header + pcm_data


_TTS_HEADERS = {
    "X-Audio-Sample-Rate": str(TTS_OUTPUT_SAMPLE_RATE),
    "X-Audio-Format": "pcm16le-mono",
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
}


async def _disconnect_aware_stream(
    request: Request,
    gen: Generator[bytes, None, None],
    on_done: Callable[[], None] | None = None,
):
    """Wrap a sync generator; abort if client disconnects."""
    try:
        for chunk in gen:
            if await request.is_disconnected():
                logger.info("[ailanguagebuddy-perf] Client disconnected — aborting TTS stream")
                gen.close()
                return
            yield chunk
    except GeneratorExit:
        logger.info("[ailanguagebuddy-perf] Generator closed (client gone)")
    finally:
        gen.close()
        if on_done is not None:
            try:
                on_done()
            except Exception:
                pass


@app.post("/synthesize/raw")
async def synthesize_raw(request: Request, body: SpeakRequest):
    """
    Streaming multilingual TTS endpoint — returns chunked WAV audio.

    Sends a 44-byte WAV header immediately, then streams PCM16 24kHz mono chunks.
    Accepts `language` field (ISO 639-1, e.g. "ro", "fr", "es").
    Unsupported languages gracefully fall back to "en" with a warning.
    Cancels any in-flight TTS generation to prevent GPU congestion.
    """
    try:
        lang = _validate_language(body.language)
        logger.info(f"Streaming synthesis: '{body.text}' lang={lang}")

        # Prevent overlapping synthesis; a second request is rejected while one is active.
        if not _try_start_synthesis():
            raise HTTPException(status_code=409, detail="TTS already in progress")
        _tts_cancel_event.clear()
        gen = _synthesize_stream(body.text, language=lang)
        return StreamingResponse(
            _disconnect_aware_stream(request, gen, on_done=_finish_synthesis),
            media_type="audio/wav",
            headers={**_TTS_HEADERS, "X-Audio-Language": lang},
        )
    except HTTPException:
        _finish_synthesis()
        raise
    except Exception as e:
        _finish_synthesis()
        logger.error(f"Synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.exception_handler(RequestValidationError)
async def validation_400_handler(request, exc: RequestValidationError):
    """Convert Pydantic validation errors to 400 instead of default 422."""
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)},
    )


@app.get("/synthesize/word")
def synthesize_word(
    text: str = Query(..., min_length=1, max_length=100),
    lang: str = Query(default="en", min_length=2, max_length=5),
):
    """
    Fast, cacheable word/phrase TTS. Returns full PCM16 in one Response
    (small payloads don't benefit from streaming overhead).
    """
    key = _cache_key(text, lang)
    cached = _cache_get(key)
    if cached is not None:
        return Response(
            content=cached,
            media_type="audio/wav",
            headers={**_TTS_HEADERS, "X-Cache": "HIT"},
        )

    try:
        validated_lang = _validate_language(lang)
        logger.info(f"Synthesizing word: '{text}' lang={validated_lang}")
        audio_bytes = _synthesize_full(text, language=validated_lang)
        _cache_put(key, audio_bytes)
        logger.info(f"Word audio: {len(audio_bytes)} bytes")
        return Response(
            content=audio_bytes,
            media_type="audio/wav",
            headers={**_TTS_HEADERS, "X-Cache": "MISS"},
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Word synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ─── Entry point ────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
