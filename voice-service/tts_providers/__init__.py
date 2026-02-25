"""
TTS provider interface and implementations.
Edge-TTS: default, fast, multi-language.
Chatterbox: optional, higher quality, single-language.
"""
from .base import TTSProvider
from .edge_tts_provider import EdgeTTSProvider
from .chatterbox_provider import ChatterboxProvider

__all__ = ["TTSProvider", "EdgeTTSProvider", "ChatterboxProvider"]
