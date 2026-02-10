from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import torch
import torchaudio
import io
import os
import uvicorn
import numpy as np
from contextlib import asynccontextmanager

# Initialize API
app = FastAPI(title="Voice Service using Chatterbox")

# Global model variable
tts_model = None
MODEL_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

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
    except Exception as e:
        print(f"Failed to load Chatterbox model: {e}")
        print("Running in MOCK mode for TTS.")
        tts_model = MockTTS()

    # Load STT model (Whisper)
    print(f"Loading Faster-Whisper (tiny) on {MODEL_DEVICE}...")
    try:
        from faster_whisper import WhisperModel
        # Use 'tiny' or 'base' for speed. 'int8' is faster on CPU.
        stt_compute_type = "int8" if MODEL_DEVICE == "cpu" else "float16"
        stt_model = WhisperModel("tiny", device=MODEL_DEVICE, compute_type=stt_compute_type)
        print("Faster-Whisper loaded successfully.")
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

        # Transcribe
        segments, info = stt_model.transcribe(audio_data, beam_size=5)
        
        transcribed_text = " ".join([segment.text for segment in segments]).strip()
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
        
        logger.info(f"Generated audio bytes: {len(wav_int16.tobytes())}")
        
        return Response(content=wav_int16.tobytes(), media_type="application/octet-stream")
        
    except Exception as e:
        logger.error(f"Synthesis error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
