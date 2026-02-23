from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import Response, StreamingResponse
from pydantic import BaseModel
import torch
import torchaudio
import io
import os
import uvicorn
import numpy as np
import audioop
from contextlib import asynccontextmanager
import asyncio
import edge_tts
from edge_tts.exceptions import NoAudioReceived

# Initialize API
app = FastAPI(title="Voice Service using Chatterbox")

# Global model variable
tts_model = None
# Force Apple Silicon acceleration path.
MODEL_DEVICE = "mps"
STREAM_CHUNK_BYTES = 8 * 1024
STT_MODEL_REPO = os.getenv("MLX_WHISPER_MODEL", "mlx-community/whisper-tiny")
SILENCE_RMS_THRESHOLD = 220
EDGE_VOICE_BY_LANGUAGE = {
    "en": "en-US-JennyNeural",
    "fr": "fr-FR-DeniseNeural",
    "es": "es-ES-ElviraNeural",
    "de": "de-DE-KatjaNeural",
    "it": "it-IT-ElsaNeural",
    "pt": "pt-BR-FranciscaNeural",
    "ru": "ru-RU-SvetlanaNeural",
    "zh": "zh-CN-XiaoxiaoNeural",
    "ja": "ja-JP-NanamiNeural",
    "ko": "ko-KR-SunHiNeural",
}
EDGE_FALLBACK_VOICE = "en-US-JennyNeural"

# Mock Class
class MockTTS:
    def __init__(self):
        self.sr = 24000
    
    def generate(self, text: str):
        # Generate 1 second of silence or white noise as placeholder
        print(f"[MOCK] Generating audio for: {text}")
        return torch.zeros(1, 24000) # 1 second of silence

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

    # Load TTS model on startup
    global tts_model, stt_model
    print(f"Loading Chatterbox-Turbo on {MODEL_DEVICE}...")
    try:
        from chatterbox.tts_turbo import ChatterboxTurboTTS
        tts_model = ChatterboxTurboTTS.from_pretrained(device=MODEL_DEVICE)
        print("Chatterbox-Turbo loaded successfully.")
        # Warmup to avoid cold-start penalty on first real request.
        with torch.inference_mode(), torch.no_grad():
            _ = tts_model.generate("System ready.")
        print("Chatterbox-Turbo warmup complete.")
    except Exception as e:
        print(f"Failed to load Chatterbox model: {e}")
        print("Running in MOCK mode for TTS.")
        tts_model = MockTTS()

    # Load STT model (Whisper via MLX on Apple Silicon)
    print(f"Loading mlx-whisper ({STT_MODEL_REPO}) on {MODEL_DEVICE}...")
    try:
        import mlx_whisper
        stt_model = mlx_whisper
        print("mlx-whisper loaded successfully.")
    except Exception as e:
        print(f"Failed to load Whisper model: {e}")
        stt_model = None

    yield
    # Clean up (if needed)

app = FastAPI(lifespan=lifespan)

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
        "stt_loaded": stt_model is not None
    }

import wave
# ...

import logging
import traceback
import sys

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ... (imports)

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

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    """
    Transcribes uploaded audio file to text.
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
            # Wrap in WAV container
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

        # Strict silence gate to avoid noise hallucinations.
        try:
            if contents.startswith(b"RIFF"):
                with wave.open(io.BytesIO(contents), "rb") as wf:
                    rms = audioop.rms(wf.readframes(wf.getnframes()), wf.getsampwidth())
            else:
                rms = audioop.rms(contents, 2)
            if rms < SILENCE_RMS_THRESHOLD:
                logger.info(f"Silence detected (rms={rms} < {SILENCE_RMS_THRESHOLD}), skipping STT.")
                return {"text": ""}
        except Exception as e:
            logger.warning(f"Silence gate failed, continuing STT: {e}")

        # Transcribe with mlx-whisper, language locked to English.
        audio_np = _wav_bytes_to_float32(audio_data)
        result = stt_model.transcribe(
            audio_np,
            path_or_hf_repo=STT_MODEL_REPO,
            language="en",
        )

        transcribed_text = (result.get("text", "") if isinstance(result, dict) else str(result)).strip()
        logger.info(f"Transcription success: '{transcribed_text}'")
        
        return {"text": transcribed_text}

    except Exception as e:
        logger.error(f"Transcription critical error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/synthesize/raw")
def synthesize_raw(request: SpeakRequest):
    global tts_model
    if not tts_model:
         raise HTTPException(status_code=503, detail="TTS Model not loaded")
    
    try:
        logger.info(f"Synthesizing text: '{request.text}'")
        with torch.inference_mode(), torch.no_grad():
            wav = tts_model.generate(request.text)
        
        # Ensure tensor is on CPU
        if hasattr(wav, 'cpu'):
            wav = wav.cpu()
            
        # Convert to numpy
        if hasattr(wav, 'numpy'):
             wav_numpy = wav.numpy()
        else:
             # Fallback if it's already numpy or list (MockTTS)
             wav_numpy = np.array(wav)

        # Squeeze to remove batch dim if present (1, N) -> (N,)
        wav_numpy = wav_numpy.squeeze()
        
        # Normalize/Clip and Convert to Int16
        # Chatterbox usually outputs float32 in [-1, 1]
        wav_int16 = (np.clip(wav_numpy, -1, 1) * 32767).astype(np.int16)
        audio_bytes = wav_int16.tobytes()

        logger.info(f"Generated audio bytes: {len(audio_bytes)}")

        def iter_audio_chunks():
            try:
                for offset in range(0, len(audio_bytes), STREAM_CHUNK_BYTES):
                    yield audio_bytes[offset:offset + STREAM_CHUNK_BYTES]
            finally:
                # Thermal management: clear MPS cache only after synthesis stream completes.
                if hasattr(torch, "mps") and hasattr(torch.mps, "empty_cache"):
                    torch.mps.empty_cache()

        return StreamingResponse(
            iter_audio_chunks(),
            media_type="application/octet-stream",
        )
        
    except Exception as e:
        logger.error(f"Synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

async def _synthesize_edge_mp3(text: str, language: str, use_fallback_voice: bool = False) -> bytes:
    # Normalize: edge_tts can fail on empty or symbol-only text
    text = (text or "").strip()
    if not text or not any(c.isalnum() for c in text):
        raise ValueError("Text must contain at least one letter or digit for synthesis")

    if use_fallback_voice:
        voice = EDGE_FALLBACK_VOICE
        logger.warning(f"edge-tts using fallback voice {voice} for language={language}")
    else:
        voice = EDGE_VOICE_BY_LANGUAGE.get(language, EDGE_VOICE_BY_LANGUAGE.get("es", EDGE_FALLBACK_VOICE))

    communicate = edge_tts.Communicate(text=text, voice=voice)
    chunks = []
    async for chunk in communicate.stream():
        if chunk.get("type") == "audio":
            chunks.append(chunk["data"])
    result = b"".join(chunks)
    if not result:
        raise NoAudioReceived("No audio chunks received from edge-tts")
    return result

@app.post("/synthesize/instant")
def synthesize_instant(request: SpeakRequest):
    language = (request.language or "en").lower()
    # Normalize to 2-letter code for edge-tts
    lang_code = language if len(language) <= 3 else language[:2]
    text = (request.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    # Use Edge-TTS for all languages (high-speed, consistent latency; no Chatterbox load).
    try:
        logger.info(
            f"Instant edge-tts synthesis ({lang_code}): '{text[:80]}{'...' if len(text) > 80 else ''}'"
        )
        audio_mp3 = asyncio.run(_synthesize_edge_mp3(text, lang_code))
        return Response(
            content=audio_mp3,
            media_type="audio/mpeg",
            headers={"X-Audio-Codec": "mp3", "X-Audio-Sample-Rate": "24000"},
        )
    except NoAudioReceived as e:
        logger.warning(
            f"edge-tts NoAudioReceived for language={lang_code}, retrying with fallback voice: {e}"
        )
        try:
            audio_mp3 = asyncio.run(
                _synthesize_edge_mp3(text, lang_code, use_fallback_voice=True)
            )
            return Response(
                content=audio_mp3,
                media_type="audio/mpeg",
                headers={
                    "X-Audio-Codec": "mp3",
                    "X-Audio-Sample-Rate": "24000",
                    "X-TTS-Fallback": "true",
                },
            )
        except Exception as retry_e:
            logger.error(f"edge-tts fallback synthesis also failed: {retry_e}")
            traceback.print_exc()
            raise HTTPException(
                status_code=503,
                detail="TTS temporarily unavailable for this language. Please try again.",
            )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"edge-tts synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
