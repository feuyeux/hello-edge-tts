"""
TTSClient implementation for Microsoft Edge TTS service.
"""

import asyncio
import edge_tts
import aiofiles
from typing import List, Optional
from voice import Voice
from config_manager import TTSConfig
from ssml_utils import SSMLBuilder, validate_ssml


class TTSError(Exception):
    """Custom exception for TTS-related errors."""
    pass


class TTSClient:
    """
    Client for Microsoft Edge TTS service.
    
    Provides methods for text synthesis, voice management, and audio file operations.
    """
    
    def __init__(self, config: Optional[TTSConfig] = None):
        """
        Initialize TTSClient with optional configuration.
        
        Args:
            config: Optional TTSConfig instance for client configuration
        """
        self.config = config or TTSConfig()
        self._voices_cache: Optional[List[Voice]] = None
    
    async def synthesize_text(self, text: str, voice: str, use_ssml: bool = False) -> bytes:
        """
        Convert text to audio data using specified voice.
        
        Args:
            text: Text to convert to speech (plain text or SSML)
            voice: Voice name to use for synthesis
            use_ssml: Whether the text contains SSML markup
            
        Returns:
            Audio data as bytes
            
        Raises:
            TTSError: If synthesis fails
        """
        try:
            # Validate SSML if specified
            if use_ssml:
                self._validate_ssml(text)
            
            # Create TTS communicate object
            communicate = edge_tts.Communicate(text, voice)
            
            # Collect audio data
            audio_data = b""
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_data += chunk["data"]
            
            if not audio_data:
                raise TTSError(f"No audio data generated for text: {text[:50]}...")
                
            return audio_data
            
        except Exception as e:
            raise TTSError(f"Failed to synthesize text: {str(e)}")
    
    async def synthesize_ssml(self, ssml: str, voice: str) -> bytes:
        """
        Convert SSML to audio data using specified voice.
        
        Args:
            ssml: SSML markup to convert to speech
            voice: Voice name to use for synthesis
            
        Returns:
            Audio data as bytes
            
        Raises:
            TTSError: If synthesis fails
        """
        return await self.synthesize_text(ssml, voice, use_ssml=True)
    
    async def save_audio(self, audio_data: bytes, filename: str) -> None:
        """
        Save audio data to file.
        
        Args:
            audio_data: Audio data as bytes
            filename: Output filename
            
        Raises:
            TTSError: If file save fails
        """
        try:
            async with aiofiles.open(filename, 'wb') as f:
                await f.write(audio_data)
        except Exception as e:
            raise TTSError(f"Failed to save audio to {filename}: {str(e)}")
    
    async def list_voices(self) -> List[Voice]:
        """
        Get all available voices from Edge TTS service.
        
        Returns:
            List of Voice objects
            
        Raises:
            TTSError: If voice listing fails
        """
        if self._voices_cache is None:
            try:
                voices_data = await edge_tts.list_voices()
                self._voices_cache = [
                    Voice(
                        name=voice["ShortName"],  # Use ShortName as the main identifier
                        display_name=voice["FriendlyName"],  # Use FriendlyName as display name
                        locale=voice["Locale"],
                        gender=voice["Gender"]
                    )
                    for voice in voices_data
                ]
            except Exception as e:
                raise TTSError(f"Failed to list voices: {str(e)}")
        
        return self._voices_cache
    
    async def get_voices_by_language(self, language: str) -> List[Voice]:
        """
        Get voices filtered by language code.
        
        Args:
            language: Language code (e.g., 'en', 'en-US')
            
        Returns:
            List of Voice objects matching the language
            
        Raises:
            TTSError: If voice filtering fails
        """
        try:
            all_voices = await self.list_voices()
            
            # Filter by language - support both 'en' and 'en-US' formats
            filtered_voices = []
            for voice in all_voices:
                if voice.locale.startswith(language) or voice.locale.split('-')[0] == language:
                    filtered_voices.append(voice)
            
            return filtered_voices
            
        except Exception as e:
            raise TTSError(f"Failed to filter voices by language {language}: {str(e)}")
    
    def clear_voice_cache(self) -> None:
        """Clear the cached voice list to force refresh on next request."""
        self._voices_cache = None
    
    def create_ssml(self, text: str, voice: str, rate: str = "0%", pitch: str = "0%", volume: str = "100%") -> str:
        """
        Create SSML markup with prosody controls.
        
        Args:
            text: Text content to wrap in SSML
            voice: Voice name to use
            rate: Speech rate adjustment (e.g., "slow", "fast", "+20%", "-10%")
            pitch: Pitch adjustment (e.g., "high", "low", "+2st", "-1st")
            volume: Volume adjustment (e.g., "loud", "soft", "+6dB", "-3dB")
            
        Returns:
            SSML markup string
        """
        # Extract language from voice name for xml:lang attribute
        lang = voice.split('-')[0] + '-' + voice.split('-')[1] if '-' in voice else 'en-US'
        
        ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{lang}">
    <voice name="{voice}">
        <prosody rate="{rate}" pitch="{pitch}" volume="{volume}">
            {text}
        </prosody>
    </voice>
</speak>'''
        return ssml
    
    def create_emphasis_ssml(self, text: str, voice: str, emphasis_level: str = "moderate") -> str:
        """
        Create SSML with emphasis markup.
        
        Args:
            text: Text content to emphasize
            voice: Voice name to use
            emphasis_level: Level of emphasis ("strong", "moderate", "reduced")
            
        Returns:
            SSML markup string
        """
        lang = voice.split('-')[0] + '-' + voice.split('-')[1] if '-' in voice else 'en-US'
        
        ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{lang}">
    <voice name="{voice}">
        <emphasis level="{emphasis_level}">{text}</emphasis>
    </voice>
</speak>'''
        return ssml
    
    def create_break_ssml(self, text_parts: List[str], voice: str, break_time: str = "1s") -> str:
        """
        Create SSML with breaks between text parts.
        
        Args:
            text_parts: List of text segments to separate with breaks
            voice: Voice name to use
            break_time: Duration of break (e.g., "1s", "500ms", "weak", "strong")
            
        Returns:
            SSML markup string
        """
        lang = voice.split('-')[0] + '-' + voice.split('-')[1] if '-' in voice else 'en-US'
        
        content = f'<break time="{break_time}"/>'.join(text_parts)
        
        ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{lang}">
    <voice name="{voice}">
        {content}
    </voice>
</speak>'''
        return ssml
    
    def _validate_ssml(self, ssml: str) -> None:
        """
        Validate SSML markup using comprehensive validation.
        
        Args:
            ssml: SSML markup to validate
            
        Raises:
            TTSError: If SSML is invalid
        """
        try:
            errors = validate_ssml(ssml, raise_on_error=False)
            if errors:
                raise TTSError(f"SSML validation failed: {'; '.join(errors)}")
        except Exception as e:
            raise TTSError(f"SSML validation error: {str(e)}")
    
    def get_ssml_builder(self, voice: str) -> SSMLBuilder:
        """
        Get an SSML builder instance for the specified voice.
        
        Args:
            voice: Voice name to use
            
        Returns:
            SSMLBuilder instance
        """
        return SSMLBuilder(voice)
    
    async def batch_synthesize_text(self, texts: List[str], voice: str, use_ssml: bool = False) -> List[bytes]:
        """
        Convert multiple texts to audio data using specified voice.
        
        Args:
            texts: List of texts to convert to speech
            voice: Voice name to use for synthesis
            use_ssml: Whether the texts contain SSML markup
            
        Returns:
            List of audio data as bytes
            
        Raises:
            TTSError: If synthesis fails
        """
        results = []
        
        for i, text in enumerate(texts):
            try:
                print(f"Processing batch item {i+1}/{len(texts)}: {text[:50]}...")
                audio_data = await self.synthesize_text(text, voice, use_ssml)
                results.append(audio_data)
            except Exception as e:
                raise TTSError(f"Failed to synthesize batch item {i+1}: {str(e)}")
        
        return results
    
    async def batch_synthesize_concurrent(self, texts: List[str], voice: str, use_ssml: bool = False, max_concurrent: int = 3) -> List[bytes]:
        """
        Convert multiple texts to audio data concurrently using specified voice.
        
        Args:
            texts: List of texts to convert to speech
            voice: Voice name to use for synthesis
            use_ssml: Whether the texts contain SSML markup
            max_concurrent: Maximum number of concurrent requests
            
        Returns:
            List of audio data as bytes
            
        Raises:
            TTSError: If synthesis fails
        """
        import asyncio
        
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def synthesize_with_semaphore(text: str, index: int) -> tuple[int, bytes]:
            async with semaphore:
                try:
                    print(f"Processing concurrent item {index+1}/{len(texts)}: {text[:50]}...")
                    audio_data = await self.synthesize_text(text, voice, use_ssml)
                    return (index, audio_data)
                except Exception as e:
                    raise TTSError(f"Failed to synthesize concurrent item {index+1}: {str(e)}")
        
        # Create tasks for all texts
        tasks = [synthesize_with_semaphore(text, i) for i, text in enumerate(texts)]
        
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks)
        
        # Sort results by original index to maintain order
        results.sort(key=lambda x: x[0])
        
        return [audio_data for _, audio_data in results]
    
    async def batch_save_audio(self, audio_data_list: List[bytes], filename_template: str) -> List[str]:
        """
        Save multiple audio data to files.
        
        Args:
            audio_data_list: List of audio data as bytes
            filename_template: Template for filenames (should contain {} for index)
            
        Returns:
            List of saved filenames
            
        Raises:
            TTSError: If file save fails
        """
        saved_files = []
        
        for i, audio_data in enumerate(audio_data_list):
            try:
                filename = filename_template.format(i+1)
                await self.save_audio(audio_data, filename)
                saved_files.append(filename)
                print(f"Saved batch item {i+1}: {filename}")
            except Exception as e:
                raise TTSError(f"Failed to save batch item {i+1}: {str(e)}")
        
        return saved_files