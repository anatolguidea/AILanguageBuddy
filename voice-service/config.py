"""
Voice service configuration.
USE_EDGE_TTS = True: use Edge-TTS for speed and multi-language (default).
USE_EDGE_TTS = False: use Chatterbox for higher-quality, single-language synthesis.
"""
import os

# TTS provider: True = Edge-TTS (fast, multi-language), False = Chatterbox (Turbo-only)
USE_EDGE_TTS = os.getenv("USE_EDGE_TTS", "true").lower() in ("true", "1", "yes")

# Enable English-only turbo TTS (Chatterbox) for live speech while using Edge-TTS for other languages.
USE_EN_TURBO = os.getenv("USE_EN_TURBO", "false").lower() in ("true", "1", "yes")

# Device for Chatterbox when used (e.g. "mps", "cuda", "cpu")
MODEL_DEVICE = os.getenv("MODEL_DEVICE", "mps")

# Stream chunk size for raw PCM streaming (Chatterbox path)
STREAM_CHUNK_BYTES = 8 * 1024

# STT
STT_MODEL_REPO = os.getenv("MLX_WHISPER_MODEL", "mlx-community/whisper-tiny")
SILENCE_RMS_THRESHOLD = 220
