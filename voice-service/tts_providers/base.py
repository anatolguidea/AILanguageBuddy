"""TTS provider abstract base."""
from abc import ABC, abstractmethod
from typing import AsyncIterator


class TTSProvider(ABC):
    """Interface for TTS backends."""

    @abstractmethod
    def synthesize(self, text: str, language: str) -> bytes:
        """Synthesize text to audio bytes (full buffer)."""
        pass

    @abstractmethod
    async def stream(self, text: str, language: str) -> AsyncIterator[bytes]:
        """Stream audio chunks as they become available."""
        pass

    @property
    @abstractmethod
    def codec(self) -> str:
        """e.g. 'pcm16' or 'mp3'."""
        pass

    @property
    @abstractmethod
    def sample_rate(self) -> int:
        pass

    @property
    @abstractmethod
    def media_type(self) -> str:
        """e.g. 'application/octet-stream' or 'audio/mpeg'."""
        pass
