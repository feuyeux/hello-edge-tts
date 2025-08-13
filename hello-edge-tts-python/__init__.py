"""
Hello Edge TTS - Python Implementation

A Python library for text-to-speech using Microsoft Edge TTS service.
Provides TTSClient, Voice model, and AudioPlayer functionality.
"""

try:
    from .tts_client import TTSClient
    from .voice import Voice
    from .audio_player import AudioPlayer
    from .config import TTSConfig
except ImportError:
    from tts_client import TTSClient
    from voice import Voice
    from audio_player import AudioPlayer
    from config_manager import TTSConfig

__version__ = "1.0.0"
__all__ = ["TTSClient", "Voice", "AudioPlayer", "TTSConfig"]