from fastapi import FastAPI, UploadFile, File, HTTPException, Query
from fastapi.responses import Response
from pydantic import BaseModel
import torch
import torchaudio
import io
import os
import uvicorn
import numpy as np
from contextlib import asynccontextmanager
from collections import OrderedDict

# Global model variable
tts_model = None
MODEL_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# ─── Word-level TTS cache (LRU, max 500 entries) ───────────────────
_WORD_CACHE_MAX = 500
_word_audio_cache: OrderedDict[str, bytes] = OrderedDict()

def _cache_key(text: str, lang: str) -> str:
    return f"{lang}:{text.lower().strip()}"

def _cache_put(key: str, audio_bytes: bytes):
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


# Mock Class
class MockTTS:
    def __init__(self):
        self.sr = 24000
    
    def generate(self, text: str, **kwargs):
        print(f"[MOCK] Generating audio for: {text}")
        return torch.zeros(1, 24000)  # 1 second of silence

import os
from huggingface_hub import login

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Authenticate with Hugging Face if token is present
    hf_token = os.getenv("HF_TOKEN")
    if hf_token and hf_token != "your_hugging_face_token_here":
        print("Found HF_TOKEN, authenticating...")
        try:
            login(token=hf_token)
            print("Successfully authenticated with Hugging Face.")
        except Exception as e:
            print(f"Warning: Failed to authenticate with Hugging Face: {e}")
    else:
        print("No valid HF_TOKEN found in environment. Model loading might fail if it is gated.")

    # Load TTS model on startup — Chatterbox Multilingual
    global tts_model, stt_model
    print(f"Loading Chatterbox on {MODEL_DEVICE}...")
    try:
        from chatterbox.tts import ChatterboxTTS
        tts_model = ChatterboxTTS.from_pretrained(device=MODEL_DEVICE)
        print("Chatterbox (Multilingual) loaded successfully.")
        try:
            with torch.inference_mode():
                _ = tts_model.generate("System ready.")
            print("Chatterbox warmup completed.")
        except Exception as warmup_error:
            print(f"Chatterbox warmup skipped: {warmup_error}")
    except Exception as e:
        print(f"Failed to load Chatterbox model: {e}")
        print("Running in MOCK mode for TTS.")
        tts_model = MockTTS()

    # Load STT model (Whisper)
    print(f"Loading Faster-Whisper (tiny) on {MODEL_DEVICE}...")
    try:
        from faster_whisper import WhisperModel
        stt_compute_type = "int8" if MODEL_DEVICE == "cpu" else "float16"
        stt_model = WhisperModel("tiny", device=MODEL_DEVICE, compute_type=stt_compute_type)
        print("Faster-Whisper loaded successfully.")
    except Exception as e:
        print(f"Failed to load Whisper model: {e}")
        stt_model = None

    yield

app = FastAPI(lifespan=lifespan, title="Voice Service using Chatterbox")

# Global STT model
stt_model = None

class SpeakRequest(BaseModel):
    text: str
    language: str = "en"

@app.get("/health")
def health_check():
    return {
        "status": "ok", 
        "device": MODEL_DEVICE, 
        "tts_loaded": tts_model is not None,
        "stt_loaded": stt_model is not None,
        "tts_sample_rate": 24000
    }

import wave
import logging
import traceback
import sys
import threading

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
tts_lock = threading.Lock()


async def _transcribe_internal(file: UploadFile, beam_size: int, max_words: int | None = None):
    """
    Shared transcription path for full and partial endpoints.
    Handles both Raw PCM (16k/16bit/mono) and WAV files.
    """
    global stt_model
    if not stt_model:
        logger.warning("STT Model not loaded. Returning mock text.")
        return {"text": "Hello AI, how are you?"}
    
    try:
        contents = await file.read()
        logger.info(f"Received audio for transcription. Size: {len(contents)} bytes")
        
        # Check for WAV header (RIFF)
        if contents.startswith(b'RIFF'):
            logger.info("Detected WAV header in input. Using directly.")
            audio_data = io.BytesIO(contents)
        else:
            logger.info("No WAV header detected. Treating as Raw PCM (16kHz, 16-bit, Mono).")
            audio_data = io.BytesIO()
            try:
                with wave.open(audio_data, 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)
                    wav_file.setframerate(16000)
                    wav_file.writeframes(contents)
                audio_data.seek(0)
            except Exception as e:
                logger.error(f"Failed to wrap PCM data: {e}")
                raise HTTPException(status_code=400, detail=f"Failed to wrap PCM: {e}")

        # Transcribe
        segments, info = stt_model.transcribe(audio_data, beam_size=beam_size)
        
        transcribed_text = " ".join([segment.text for segment in segments]).strip()
        if max_words is not None and max_words > 0 and transcribed_text:
            words = transcribed_text.split()
            transcribed_text = " ".join(words[:max_words])
        logger.info(f"Transcription success: '{transcribed_text}'")
        
        return {"text": transcribed_text}

    except Exception as e:
        logger.error(f"Transcription critical error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    return await _transcribe_internal(file=file, beam_size=5)

@app.post("/transcribe/partial")
async def transcribe_partial(file: UploadFile = File(...), max_words: int = Query(default=20, ge=3, le=60)):
    return await _transcribe_internal(file=file, beam_size=1, max_words=max_words)


def _synthesize_to_pcm16(text: str) -> bytes:
    """Generate TTS audio and return raw PCM16 mono bytes at 24kHz."""
    global tts_model
    if not tts_model:
        raise HTTPException(status_code=503, detail="TTS Model not loaded")

    with tts_lock:
        with torch.inference_mode():
            wav = tts_model.generate(text)

    if hasattr(wav, 'cpu'):
        wav = wav.cpu()
    if hasattr(wav, 'numpy'):
        wav_numpy = wav.numpy()
    else:
        wav_numpy = np.array(wav)

    wav_numpy = wav_numpy.squeeze()
    wav_int16 = (np.clip(wav_numpy, -1, 1) * 32767).astype(np.int16)
    return wav_int16.tobytes()


@app.post("/synthesize/raw")
def synthesize_raw(request: SpeakRequest):
    try:
        logger.info(f"Synthesizing text: '{request.text}'")
        audio_bytes = _synthesize_to_pcm16(request.text)
        logger.info(f"Generated audio bytes: {len(audio_bytes)}")
        
        return Response(
            content=audio_bytes,
            media_type="application/octet-stream",
            headers={"X-Audio-Sample-Rate": "24000", "X-Audio-Format": "pcm16le-mono"},
        )
        
    except Exception as e:
        logger.error(f"Synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/synthesize/word")
def synthesize_word(text: str = Query(..., min_length=1, max_length=100),
                    lang: str = Query(default="en", min_length=2, max_length=5)):
    """
    Fast, cacheable word/phrase TTS endpoint for lessons.
    Returns raw PCM16 mono audio at 24kHz.
    """
    key = _cache_key(text, lang)
    cached = _cache_get(key)
    if cached is not None:
        return Response(
            content=cached,
            media_type="application/octet-stream",
            headers={"X-Audio-Sample-Rate": "24000", "X-Audio-Format": "pcm16le-mono", "X-Cache": "HIT"},
        )

    try:
        logger.info(f"Synthesizing word: '{text}' lang={lang}")
        audio_bytes = _synthesize_to_pcm16(text)
        _cache_put(key, audio_bytes)
        logger.info(f"Word audio generated: {len(audio_bytes)} bytes")
        
        return Response(
            content=audio_bytes,
            media_type="application/octet-stream",
            headers={"X-Audio-Sample-Rate": "24000", "X-Audio-Format": "pcm16le-mono", "X-Cache": "MISS"},
        )
    except Exception as e:
        logger.error(f"Word synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
