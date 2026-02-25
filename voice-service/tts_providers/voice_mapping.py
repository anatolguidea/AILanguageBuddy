"""
Edge-TTS voice mapping: language code -> Neural Voice ID.
All languages use female Neural voices.
"""
from typing import Dict

# All female Neural voices
VOICE_MAP: Dict[str, str] = {
    "e": "en-US-JennyNeural",
    "en": "en-US-JennyNeural",
    "f": "fr-FR-DeniseNeural",
    "fr": "fr-FR-DeniseNeural",
    "ro": "ro-RO-AlinaNeural",
    "es": "es-ES-ElviraNeural",
    "de": "de-DE-KatjaNeural",
    "it": "it-IT-ElsaNeural",
    "pt": "pt-BR-FranciscaNeural",
    "ru": "ru-RU-SvetlanaNeural",
    "ja": "ja-JP-NanamiNeural",
    "ko": "ko-KR-SunHiNeural",
    "zh": "zh-CN-XiaoxiaoNeural",
}
EDGE_VOICE_BY_LANGUAGE = VOICE_MAP
EDGE_FALLBACK_VOICE = "en-US-JennyNeural"

# Display names (from app) -> 2-letter code for request normalization
_LANG_NAME_TO_CODE: Dict[str, str] = {
    "romanian": "ro",
    "română": "ro",
    "french": "fr",
    "english": "en",
    "spanish": "es",
    "german": "de",
    "italian": "it",
    "portuguese": "pt",
    "russian": "ru",
    "japanese": "ja",
    "korean": "ko",
    "chinese": "zh",
}


def normalize_lang(value: str | None) -> str:
    """Normalize request language to 2-letter code. Handles 'e', 'f', 'en', 'English', etc."""
    if not value:
        return "en"
    v = "".join(c for c in str(value).strip().lower() if c.isalpha())[:2]
    if not v:
        return "en"
    if v == "e" or v == "en":
        return "en"
    if v == "f" or v == "fr":
        return "fr"
    if len(v) == 2:
        return v
    return _LANG_NAME_TO_CODE.get(v, "en")


def get_edge_voice(lang_code: str | None) -> str:
    """Return Edge-TTS voice for the given language (2-letter code or display name)."""
    code = normalize_lang(lang_code)
    # Try exact code first, then single-letter (f -> fr voice, e -> en voice)
    voice = VOICE_MAP.get(code)
    if voice is not None:
        return voice
    raw = (lang_code or "").strip().lower()
    if len(raw) >= 1 and raw[0].isalpha():
        voice = VOICE_MAP.get(raw[0])  # "f" -> fr-FR-DeniseNeural
        if voice is not None:
            return voice
    return EDGE_FALLBACK_VOICE
