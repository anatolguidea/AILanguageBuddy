"""
Chatterbox-Turbo TTS provider: higher quality, single-language, raw PCM stream.
"""
import io
import logging
from typing import Any, Optional

import numpy as np
import torch

from .base import TTSProvider

logger = logging.getLogger(__name__)


class ChatterboxProvider(TTSProvider):
    """Chatterbox-Turbo TTS: PCM int16, 24kHz. Language is ignored (model is English)."""

    def __init__(self, model: Any):
        """
        :param model: ChatterboxTurboTTS instance or MockTTS. None not allowed.
        """
        self._model = model
        self._sample_rate = 24000
        self._codec = "pcm16"
        self._media_type = "application/octet-stream"

    def synthesize(self, text: str, language: str) -> bytes:
        with torch.inference_mode(), torch.no_grad():
            wav = self._model.generate(text)
        if hasattr(wav, "cpu"):
            wav = wav.cpu()
        if hasattr(wav, "numpy"):
            wav_numpy = wav.numpy()
        else:
            wav_numpy = np.array(wav)
        wav_numpy = wav_numpy.squeeze()
        wav_int16 = (np.clip(wav_numpy, -1, 1) * 32767).astype(np.int16)
        return wav_int16.tobytes()

    async def stream(self, text: str, language: str):
        """Single chunk for Chatterbox."""
        yield self.synthesize(text, language)

    @property
    def codec(self) -> str:
        return self._codec

    @property
    def sample_rate(self) -> int:
        return self._sample_rate

    @property
    def media_type(self) -> str:
        return self._media_type
