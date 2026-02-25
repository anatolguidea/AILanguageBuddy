"""
Edge-TTS provider: fast, multi-language, streams MP3.
"""
import asyncio
import logging
from typing import AsyncIterator

import edge_tts
from edge_tts.exceptions import NoAudioReceived

from .base import TTSProvider
from .voice_mapping import get_edge_voice, EDGE_FALLBACK_VOICE, normalize_lang

logger = logging.getLogger(__name__)


def _clean_tts_text(raw: str) -> str:
    """Strip to plain reply string only: no metadata or language tags."""
    if not raw:
        return ""
    s = raw.strip()
    for prefix in ("[lang=", "[language=", "lang:", "language:"):
        if s.lower().startswith(prefix):
            end = s.find("]") + 1 if "]" in s else len(prefix)
            s = s[end:].strip()
    return s


async def _synthesize_edge_mp3(
    text: str,
    language: str,
    use_fallback_voice: bool = False,
) -> bytes:
    text = (text or "").strip()
    text = _clean_tts_text(text)
    if not text or not any(c.isalnum() for c in text):
        raise ValueError("Text must contain at least one letter or digit for synthesis")

    lang_code = normalize_lang(language)
    if use_fallback_voice:
        voice = EDGE_FALLBACK_VOICE
        logger.warning("edge-tts using fallback voice %s for language=%s", voice, language)
    else:
        voice = get_edge_voice(lang_code)

    communicate = edge_tts.Communicate(text=text, voice=voice)
    chunks = []
    async for chunk in communicate.stream():
        if chunk.get("type") == "audio":
            chunks.append(chunk["data"])
    result = b"".join(chunks)
    if not result:
        raise NoAudioReceived("No audio chunks received from edge-tts")
    return result


class EdgeTTSProvider(TTSProvider):
    """Primary TTS: Edge-TTS, low latency, multi-language, MP3 output."""

    def __init__(self):
        self._sample_rate = 24000
        self._codec = "mp3"
        self._media_type = "audio/mpeg"

    def synthesize(self, text: str, language: str) -> bytes:
        lang_code = normalize_lang(language)
        try:
            return asyncio.run(_synthesize_edge_mp3(text, lang_code))
        except NoAudioReceived as e:
            logger.warning("edge-tts NoAudioReceived for language=%s, retrying fallback: %s", lang_code, e)
            return asyncio.run(_synthesize_edge_mp3(text, lang_code, use_fallback_voice=True))

    async def stream(self, text: str, language: str) -> AsyncIterator[bytes]:
        """Stream MP3 chunks; uses --voice with mapped Neural voice for correct accent."""
        text = _clean_tts_text(text or "")
        if not text or not any(c.isalnum() for c in text):
            raise ValueError("Text must contain at least one letter or digit for synthesis")
        lang_code = normalize_lang(language)
        voice = get_edge_voice(language)  # accepts raw "f" or normalized "fr"
        logger.info("DEBUG: Selected voice %s for lang=%s (normalized=%s)", voice, language, lang_code)
        try:
            communicate = edge_tts.Communicate(text=text, voice=voice)
            async for chunk in communicate.stream():
                if chunk.get("type") == "audio" and chunk.get("data"):
                    yield chunk["data"]
        except Exception as e:
            logger.warning("edge-tts fallback voice for lang=%s: %s", lang_code, e)
            voice = EDGE_FALLBACK_VOICE
            communicate = edge_tts.Communicate(text=text, voice=voice)
            async for chunk in communicate.stream():
                if chunk.get("type") == "audio" and chunk.get("data"):
                    yield chunk["data"]

    @property
    def codec(self) -> str:
        return self._codec

    @property
    def sample_rate(self) -> int:
        return self._sample_rate

    @property
    def media_type(self) -> str:
        return self._media_type
