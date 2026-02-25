from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import Response, StreamingResponse
from pydantic import BaseModel
import torch
import io
import os
import uvicorn
import numpy as np
import audioop
import wave
import logging
import traceback
from contextlib import asynccontextmanager

from config import USE_EDGE_TTS, USE_EN_TURBO, MODEL_DEVICE, STREAM_CHUNK_BYTES, STT_MODEL_REPO, SILENCE_RMS_THRESHOLD
from tts_providers import TTSProvider, EdgeTTSProvider, ChatterboxProvider
from tts_providers.voice_mapping import normalize_lang

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global TTS:
# - edge_tts_provider: Edge-TTS for multi-language (always available when USE_EDGE_TTS=True)
# - en_turbo_provider: Chatterbox Turbo for EN-only (optional, when USE_EN_TURBO=True)
# - tts_provider: legacy/global provider for /synthesize/raw (Chatterbox path when USE_EDGE_TTS=False)
tts_provider: TTSProvider | None = None
edge_tts_provider: TTSProvider | None = None
en_turbo_provider: TTSProvider | None = None
chatterbox_model = None
stt_model = None


class MockTTS:
    def __init__(self):
        self.sr = 24000

    def generate(self, text: str):
        logger.info("[MOCK] Generating audio for: %s", text[:80])
        return torch.zeros(1, 24000)


@asynccontextmanager
async def lifespan(app: FastAPI):
    global tts_provider, edge_tts_provider, en_turbo_provider, chatterbox_model, stt_model
    hf_token = os.getenv("HF_TOKEN")
    if hf_token and hf_token != "your_hugging_face_token_here":
        try:
            from huggingface_hub import login
            login(token=hf_token)
            logger.info("Successfully authenticated with Hugging Face.")
        except Exception as e:
            logger.warning("Failed to authenticate with Hugging Face: %s", e)
    else:
        logger.info("No valid HF_TOKEN found.")

    if USE_EDGE_TTS:
        # Always load Edge-TTS for all languages
        edge_tts_provider = EdgeTTSProvider()
        tts_provider = edge_tts_provider  # for health_check compatibility
        logger.info("TTS provider: Edge-TTS (USE_EDGE_TTS=True)")

        # Optionally load English-only Turbo TTS for higher-quality EN voice
        if USE_EN_TURBO:
            logger.info("Loading English-only Turbo TTS on %s...", MODEL_DEVICE)
            try:
                from chatterbox.tts_turbo import ChatterboxTurboTTS
                chatterbox_model = ChatterboxTurboTTS.from_pretrained(device=MODEL_DEVICE)
                with torch.inference_mode(), torch.no_grad():
                    _ = chatterbox_model.generate("System ready.")
                en_turbo_provider = ChatterboxProvider(chatterbox_model)
                logger.info("English Turbo TTS loaded for 'en' only.")
            except Exception as e:
                logger.warning("Failed to load English Turbo TTS: %s", e)
                en_turbo_provider = None
    else:
        logger.info("Loading Chatterbox-Turbo on %s...", MODEL_DEVICE)
        try:
            from chatterbox.tts_turbo import ChatterboxTurboTTS
            chatterbox_model = ChatterboxTurboTTS.from_pretrained(device=MODEL_DEVICE)
            with torch.inference_mode(), torch.no_grad():
                _ = chatterbox_model.generate("System ready.")
            tts_provider = ChatterboxProvider(chatterbox_model)
            logger.info("TTS provider: Chatterbox-Turbo")
        except Exception as e:
            logger.warning("Failed to load Chatterbox: %s. Using MOCK TTS.", e)
            chatterbox_model = MockTTS()
            tts_provider = ChatterboxProvider(chatterbox_model)

    # STT
    logger.info("Loading mlx-whisper (%s)...", STT_MODEL_REPO)
    try:
        import mlx_whisper
        stt_model = mlx_whisper
        logger.info("mlx-whisper loaded.")
    except Exception as e:
        logger.warning("Failed to load Whisper: %s", e)
        stt_model = None

    yield
    if hasattr(torch, "mps") and hasattr(torch.mps, "empty_cache"):
        torch.mps.empty_cache()


app = FastAPI(title="Voice Service", lifespan=lifespan)


class SpeakRequest(BaseModel):
    text: str
    language: str = "en"
    languageCode: str | None = None


def _collapse_repeated_words(text: str) -> str:
    """Collapse consecutive repeated words (e.g. 'defeating defeating' -> 'defeating')."""
    if not text or not text.strip():
        return text
    words = text.strip().split()
    if not words:
        return text.strip()
    out = [words[0]]
    for w in words[1:]:
        if w != out[-1]:
            out.append(w)
    return " ".join(out)


def _wav_bytes_to_float32(wav_bytes: io.BytesIO) -> np.ndarray:
    """Decode WAV bytes to mono float32 @16k for mlx-whisper."""
    with wave.open(wav_bytes, "rb") as wf:
        channels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        rate = wf.getframerate()
        raw = wf.readframes(wf.getnframes())
    if sampwidth == 2:
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    elif sampwidth == 4:
        samples = np.frombuffer(raw, dtype=np.int32).astype(np.float32) / 2147483648.0
    else:
        raise ValueError(f"Unsupported WAV sample width: {sampwidth}")
    if channels > 1:
        samples = samples.reshape(-1, channels).mean(axis=1)
    if rate != 16000:
        duration = len(samples) / float(rate)
        target_len = max(1, int(duration * 16000))
        samples = np.interp(
            np.linspace(0, len(samples) - 1, target_len),
            np.arange(len(samples)),
            samples,
        ).astype(np.float32)
    return samples


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "device": MODEL_DEVICE,
        "use_edge_tts": USE_EDGE_TTS,
        "tts_loaded": tts_provider is not None,
        "stt_loaded": stt_model is not None,
    }


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...), language: str = "en"):
    if not stt_model:
        logger.warning("STT not loaded. Returning mock.")
        return {"text": "Hello AI, how are you?"}
    try:
        contents = await file.read()
        lang_code = normalize_lang(language or "en")
        logger.info("Transcribe: %s bytes (lang=%s)", len(contents), lang_code)
        if contents.startswith(b"RIFF"):
            audio_data = io.BytesIO(contents)
        else:
            audio_data = io.BytesIO()
            with wave.open(audio_data, "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(16000)
                wav_file.writeframes(contents)
            audio_data.seek(0)
        try:
            if contents.startswith(b"RIFF"):
                with wave.open(io.BytesIO(contents), "rb") as wf:
                    rms = audioop.rms(
                        wf.readframes(wf.getnframes()), wf.getsampwidth()
                    )
            else:
                rms = audioop.rms(contents, 2)
            if rms < SILENCE_RMS_THRESHOLD:
                logger.info("Silence detected, skipping STT.")
                return {"text": ""}
        except Exception as e:
            logger.warning("Silence gate failed: %s", e)
        audio_np = _wav_bytes_to_float32(audio_data)
        try:
            result = stt_model.transcribe(
                audio_np,
                path_or_hf_repo=STT_MODEL_REPO,
                language=lang_code,
                condition_on_previous_text=False,
            )
        except TypeError:
            result = stt_model.transcribe(
                audio_np,
                path_or_hf_repo=STT_MODEL_REPO,
                language=lang_code,
            )
        text = (
            result.get("text", "") if isinstance(result, dict) else str(result)
        ).strip()
        text = _collapse_repeated_words(text)
        logger.info("Transcription: '%s'", text)
        return {"text": text}
    except Exception as e:
        logger.error("Transcription error: %s", e)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/synthesize/raw")
def synthesize_raw(request: SpeakRequest):
    """Streaming PCM TTS; only available when USE_EDGE_TTS=False (Chatterbox)."""
    if tts_provider is None:
        raise HTTPException(status_code=503, detail="TTS not loaded")
    if USE_EDGE_TTS:
        raise HTTPException(
            status_code=503,
            detail="Use /synthesize/instant when Edge-TTS is enabled.",
        )
    try:
        logger.info("Synthesize raw: '%s'", request.text[:80])
        audio_bytes = tts_provider.synthesize(request.text, normalize_lang(request.languageCode or request.language))
        logger.info("Generated %s bytes", len(audio_bytes))

        def iter_chunks():
            try:
                for i in range(0, len(audio_bytes), STREAM_CHUNK_BYTES):
                    yield audio_bytes[i : i + STREAM_CHUNK_BYTES]
            finally:
                if hasattr(torch, "mps") and hasattr(torch.mps, "empty_cache"):
                    torch.mps.empty_cache()

        return StreamingResponse(
            iter_chunks(),
            media_type=tts_provider.media_type,
            headers={
                "X-Audio-Codec": tts_provider.codec,
                "X-Audio-Sample-Rate": str(tts_provider.sample_rate),
            },
        )
    except Exception as e:
        logger.error("Synthesis raw error: %s", e)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/synthesize/instant")
async def synthesize_instant(request: SpeakRequest):
    """Instant TTS; routes by language:
    - EN: use Turbo (Chatterbox) when available.
    - Other languages: use Edge-TTS.
    """
    if edge_tts_provider is None and en_turbo_provider is None and tts_provider is None:
        raise HTTPException(status_code=503, detail="TTS not loaded")
    selected_lang = normalize_lang(request.languageCode or request.language)
    text = (request.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")
    try:
        # Choose provider: Turbo for EN (if available), Edge for everything else.
        provider: TTSProvider | None
        if USE_EDGE_TTS:
            if selected_lang.startswith("en") and en_turbo_provider is not None:
                provider = en_turbo_provider
                engine_name = "Turbo-EN"
            else:
                provider = edge_tts_provider
                engine_name = "Edge"
        else:
            # Legacy path: global tts_provider (Chatterbox) when USE_EDGE_TTS=False
            provider = tts_provider
            engine_name = "Chatterbox-global"

        if provider is None:
            raise HTTPException(status_code=503, detail="No TTS engine available for this language")

        logger.info(
            "Instant synthesis lang=%s using %s: '%s'",
            selected_lang,
            engine_name,
            text[:80] + ("..." if len(text) > 80 else ""),
        )
        return StreamingResponse(
            provider.stream(text, selected_lang),
            media_type=provider.media_type,
            headers={
                "X-Audio-Codec": provider.codec,
                "X-Audio-Sample-Rate": str(provider.sample_rate),
            },
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error("Instant synthesis error: %s", e)
        traceback.print_exc()
        raise HTTPException(
            status_code=503,
            detail="TTS temporarily unavailable. Please try again.",
        )


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
