"""
Utility functions for the hello-edge-tts Python implementation.
"""

import asyncio
import os
from pathlib import Path
from typing import List, Optional
try:
    from .tts_client import TTSClient, TTSError
    from .voice import Voice
    from .audio_player import AudioPlayer, AudioError
except ImportError:
    from tts_client import TTSClient, TTSError
    from voice import Voice
    from audio_player import AudioPlayer, AudioError


def create_output_directory(directory: str) -> None:
    """
    Create output directory if it doesn't exist.
    
    Args:
        directory: Directory path to create
    """
    Path(directory).mkdir(parents=True, exist_ok=True)


def get_safe_filename(text: str, max_length: int = 50) -> str:
    """
    Generate a safe filename from text.
    
    Args:
        text: Text to convert to filename
        max_length: Maximum filename length
        
    Returns:
        Safe filename string
    """
    # Remove or replace unsafe characters
    safe_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_. "
    filename = "".join(c if c in safe_chars else "_" for c in text)
    
    # Truncate if too long
    if len(filename) > max_length:
        filename = filename[:max_length]
    
    # Remove trailing spaces and dots
    filename = filename.rstrip('. ')
    
    # Ensure it's not empty
    if not filename:
        filename = "output"
    
    return filename


async def synthesize_and_save(
    client: TTSClient,
    text: str,
    voice: str,
    output_file: str,
    play_audio: bool = False
) -> None:
    """
    Synthesize text and save to file, optionally playing it.
    
    Args:
        client: TTSClient instance
        text: Text to synthesize
        voice: Voice name to use
        output_file: Output filename
        play_audio: Whether to play the audio after saving
        
    Raises:
        TTSError: If synthesis or save fails
        AudioError: If audio playback fails
    """
    try:
        # Synthesize text
        print(f"Synthesizing text with voice '{voice}'...")
        audio_data = await client.synthesize_text(text, voice)
        
        # Save to file
        print(f"Saving audio to '{output_file}'...")
        await client.save_audio(audio_data, output_file)
        
        print(f"Audio saved successfully to '{output_file}'")
        
        # Play audio if requested
        if play_audio:
            print("Playing audio...")
            player = AudioPlayer()
            player.play_file(output_file)
            print("Playback completed")
            
    except TTSError as e:
        print(f"TTS Error: {e}")
        raise
    except AudioError as e:
        print(f"Audio Error: {e}")
        raise
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise


async def list_voices_by_language(client: TTSClient, language: Optional[str] = None) -> List[Voice]:
    """
    List available voices, optionally filtered by language.
    
    Args:
        client: TTSClient instance
        language: Optional language code to filter by
        
    Returns:
        List of Voice objects
        
    Raises:
        TTSError: If voice listing fails
    """
    try:
        if language:
            print(f"Getting voices for language '{language}'...")
            voices = await client.get_voices_by_language(language)
        else:
            print("Getting all available voices...")
            voices = await client.list_voices()
        
        print(f"Found {len(voices)} voice(s)")
        return voices
        
    except TTSError as e:
        print(f"Error listing voices: {e}")
        raise


def print_voices(voices: List[Voice]) -> None:
    """
    Print voice information in a formatted way.
    
    Args:
        voices: List of Voice objects to print
    """
    if not voices:
        print("No voices found")
        return
    
    print("\nAvailable voices:")
    print("-" * 80)
    print(f"{'Name':<30} {'Display Name':<20} {'Locale':<10} {'Gender':<8}")
    print("-" * 80)
    
    for voice in voices:
        print(f"{voice.name:<30} {voice.display_name:<20} {voice.locale:<10} {voice.gender:<8}")
    
    print("-" * 80)


async def demo_basic_tts(text: str = "Hello, World!") -> None:
    """
    Demonstrate basic TTS functionality.
    
    Args:
        text: Text to synthesize
    """
    try:
        # Create client
        client = TTSClient()
        
        # Create output directory
        create_output_directory("output")
        
        # Generate filename
        filename = get_safe_filename(text) + ".mp3"
        output_path = os.path.join("output", filename)
        
        # Synthesize and save
        await synthesize_and_save(
            client=client,
            text=text,
            voice="en-US-AriaNeural",
            output_file=output_path,
            play_audio=True
        )
        
    except Exception as e:
        print(f"Demo failed: {e}")


async def demo_voice_listing() -> None:
    """Demonstrate voice listing functionality."""
    try:
        client = TTSClient()
        
        # List English voices
        en_voices = await list_voices_by_language(client, "en")
        print_voices(en_voices[:10])  # Show first 10 voices
        
    except Exception as e:
        print(f"Voice listing demo failed: {e}")


if __name__ == "__main__":
    # Run basic demo
    asyncio.run(demo_basic_tts())
    print("\n" + "="*50 + "\n")
    asyncio.run(demo_voice_listing())