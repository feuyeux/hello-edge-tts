"""
Audio playback functionality with multiple backend support.
"""

import os
import tempfile
import platform
from typing import Optional
from pathlib import Path


class AudioError(Exception):
    """Custom exception for audio-related errors."""
    pass


class AudioPlayer:
    """
    Cross-platform audio player with multiple backend support.
    
    Supports pygame and playsound libraries with automatic fallback.
    """
    
    def __init__(self, preferred_backend: Optional[str] = None):
        """
        Initialize AudioPlayer with optional backend preference.
        
        Args:
            preferred_backend: Preferred audio backend ('pygame' or 'playsound')
        """
        self.preferred_backend = preferred_backend
        self._pygame_initialized = False
        self._available_backends = self._detect_backends()
        
        if not self._available_backends:
            raise AudioError("No audio backends available. Please install pygame or playsound.")
    
    def _detect_backends(self) -> list:
        """
        Detect available audio backends.
        
        Returns:
            List of available backend names
        """
        backends = []
        
        # Check for pygame
        try:
            import pygame
            backends.append('pygame')
        except ImportError:
            pass
        
        # Check for playsound
        try:
            import playsound
            backends.append('playsound')
        except ImportError:
            pass
        
        return backends
    
    def _init_pygame(self):
        """Initialize pygame mixer if not already initialized."""
        if not self._pygame_initialized:
            try:
                import pygame
                pygame.mixer.init()
                self._pygame_initialized = True
            except Exception as e:
                raise AudioError(f"Failed to initialize pygame: {str(e)}")
    
    def _play_with_pygame(self, filename: str) -> None:
        """
        Play audio file using pygame.
        
        Args:
            filename: Path to audio file
            
        Raises:
            AudioError: If playback fails
        """
        try:
            import pygame
            self._init_pygame()
            
            # Load and play the sound
            sound = pygame.mixer.Sound(filename)
            sound.play()
            
            # Wait for playback to complete
            while pygame.mixer.get_busy():
                pygame.time.wait(100)
                
        except Exception as e:
            raise AudioError(f"Pygame playback failed: {str(e)}")
    
    def _play_with_playsound(self, filename: str) -> None:
        """
        Play audio file using playsound.
        
        Args:
            filename: Path to audio file
            
        Raises:
            AudioError: If playback fails
        """
        try:
            from playsound import playsound
            playsound(filename)
        except Exception as e:
            raise AudioError(f"Playsound playback failed: {str(e)}")
    
    def _get_backend_to_use(self) -> str:
        """
        Determine which backend to use for playback.
        
        Returns:
            Backend name to use
            
        Raises:
            AudioError: If no backends are available
        """
        if not self._available_backends:
            raise AudioError("No audio backends available")
        
        # Use preferred backend if specified and available
        if self.preferred_backend and self.preferred_backend in self._available_backends:
            return self.preferred_backend
        
        # Default priority: pygame > playsound
        if 'pygame' in self._available_backends:
            return 'pygame'
        elif 'playsound' in self._available_backends:
            return 'playsound'
        
        raise AudioError("No suitable audio backend found")
    
    def play_file(self, filename: str) -> None:
        """
        Play audio file.
        
        Args:
            filename: Path to audio file to play
            
        Raises:
            AudioError: If file doesn't exist or playback fails
        """
        if not os.path.exists(filename):
            raise AudioError(f"Audio file not found: {filename}")
        
        backend = self._get_backend_to_use()
        
        try:
            if backend == 'pygame':
                self._play_with_pygame(filename)
            elif backend == 'playsound':
                self._play_with_playsound(filename)
            else:
                raise AudioError(f"Unknown backend: {backend}")
        except AudioError:
            # Try fallback backend if available
            fallback_backends = [b for b in self._available_backends if b != backend]
            if fallback_backends:
                try:
                    fallback = fallback_backends[0]
                    if fallback == 'pygame':
                        self._play_with_pygame(filename)
                    elif fallback == 'playsound':
                        self._play_with_playsound(filename)
                except Exception:
                    pass  # Fallback failed, re-raise original error
            raise
    
    def play_audio_data(self, audio_data: bytes, format_hint: str = "mp3") -> None:
        """
        Play audio from bytes data.
        
        Args:
            audio_data: Audio data as bytes
            format_hint: Audio format hint (e.g., 'mp3', 'wav')
            
        Raises:
            AudioError: If playback fails
        """
        if not audio_data:
            raise AudioError("No audio data provided")
        
        # Create temporary file for playback
        try:
            with tempfile.NamedTemporaryFile(suffix=f".{format_hint}", delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_filename = temp_file.name
            
            # Play the temporary file
            self.play_file(temp_filename)
            
        except Exception as e:
            raise AudioError(f"Failed to play audio data: {str(e)}")
        finally:
            # Clean up temporary file
            try:
                if 'temp_filename' in locals() and os.path.exists(temp_filename):
                    os.unlink(temp_filename)
            except Exception:
                pass  # Ignore cleanup errors
    
    def get_available_backends(self) -> list:
        """
        Get list of available audio backends.
        
        Returns:
            List of available backend names
        """
        return self._available_backends.copy()
    
    def is_backend_available(self, backend: str) -> bool:
        """
        Check if a specific backend is available.
        
        Args:
            backend: Backend name to check
            
        Returns:
            True if backend is available
        """
        return backend in self._available_backends
    
    def cleanup(self) -> None:
        """Clean up audio resources."""
        if self._pygame_initialized:
            try:
                import pygame
                pygame.mixer.quit()
                self._pygame_initialized = False
            except Exception:
                pass  # Ignore cleanup errors