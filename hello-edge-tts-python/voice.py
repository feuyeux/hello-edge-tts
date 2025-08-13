"""
Voice model and voice management functionality.
"""

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class Voice:
    """
    Represents a TTS voice with its properties.
    """
    
    name: str
    display_name: str
    locale: str
    gender: str
    
    def __post_init__(self):
        """Validate voice data after initialization."""
        if not self.name:
            raise ValueError("Voice name cannot be empty")
        if not self.display_name:
            raise ValueError("Voice display_name cannot be empty")
        if not self.locale:
            raise ValueError("Voice locale cannot be empty")
        if not self.gender:
            raise ValueError("Voice gender cannot be empty")
    
    @property
    def language_code(self) -> str:
        """
        Extract language code from locale (e.g., 'en' from 'en-US').
        
        Returns:
            Language code string
        """
        return self.locale.split('-')[0]
    
    @property
    def country_code(self) -> Optional[str]:
        """
        Extract country code from locale (e.g., 'US' from 'en-US').
        
        Returns:
            Country code string or None if not available
        """
        parts = self.locale.split('-')
        return parts[1] if len(parts) > 1 else None
    
    def matches_language(self, language: str) -> bool:
        """
        Check if this voice matches the given language code.
        
        Args:
            language: Language code to match (e.g., 'en' or 'en-US')
            
        Returns:
            True if voice matches the language
        """
        if language == self.locale:
            return True
        if language == self.language_code:
            return True
        return False
    
    def __str__(self) -> str:
        """String representation of the voice."""
        return f"{self.display_name} ({self.locale}, {self.gender})"
    
    def __repr__(self) -> str:
        """Detailed string representation for debugging."""
        return (f"Voice(name='{self.name}', display_name='{self.display_name}', "
                f"locale='{self.locale}', gender='{self.gender}')")


class VoiceManager:
    """
    Utility class for voice management operations.
    """
    
    @staticmethod
    def filter_by_language(voices: List[Voice], language: str) -> List[Voice]:
        """
        Filter voices by language code.
        
        Args:
            voices: List of Voice objects to filter
            language: Language code to filter by
            
        Returns:
            Filtered list of Voice objects
        """
        return [voice for voice in voices if voice.matches_language(language)]
    
    @staticmethod
    def filter_by_gender(voices: List[Voice], gender: str) -> List[Voice]:
        """
        Filter voices by gender.
        
        Args:
            voices: List of Voice objects to filter
            gender: Gender to filter by ('Male', 'Female')
            
        Returns:
            Filtered list of Voice objects
        """
        return [voice for voice in voices if voice.gender.lower() == gender.lower()]
    
    @staticmethod
    def find_voice_by_name(voices: List[Voice], name: str) -> Optional[Voice]:
        """
        Find a voice by its name.
        
        Args:
            voices: List of Voice objects to search
            name: Voice name to find
            
        Returns:
            Voice object if found, None otherwise
        """
        for voice in voices:
            if voice.name == name:
                return voice
        return None
    
    @staticmethod
    def get_languages(voices: List[Voice]) -> List[str]:
        """
        Get unique list of language codes from voices.
        
        Args:
            voices: List of Voice objects
            
        Returns:
            Sorted list of unique language codes
        """
        languages = set()
        for voice in voices:
            languages.add(voice.language_code)
        return sorted(list(languages))
    
    @staticmethod
    def get_locales(voices: List[Voice]) -> List[str]:
        """
        Get unique list of locales from voices.
        
        Args:
            voices: List of Voice objects
            
        Returns:
            Sorted list of unique locales
        """
        locales = set()
        for voice in voices:
            locales.add(voice.locale)
        return sorted(list(locales))