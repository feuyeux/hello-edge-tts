#!/usr/bin/env python3
"""
Basic Hello Edge TTS example.

This script demonstrates basic text-to-speech functionality using the
Microsoft Edge TTS service.
"""

import asyncio
import argparse
import os
from pathlib import Path

from tts_client import TTSClient, TTSError
from audio_player import AudioPlayer, AudioError
from utils import create_output_directory, get_safe_filename


async def main():
    """Main function demonstrating basic TTS functionality."""
    parser = argparse.ArgumentParser(description="Basic Edge TTS example")
    parser.add_argument("--text", "-t", default="Hello, World!", 
                       help="Text to synthesize (default: 'Hello, World!')")
    parser.add_argument("--voice", "-v", default="en-US-AriaNeural",
                       help="Voice to use (default: en-US-AriaNeural)")
    parser.add_argument("--output", "-o", 
                       help="Output filename (auto-generated if not specified)")
    parser.add_argument("--no-play", action="store_true",
                       help="Don't play the audio after generation")
    parser.add_argument("--list-voices", "-l", action="store_true",
                       help="List available voices and exit")
    parser.add_argument("--voices-by-language", 
                       help="List voices for specific language (e.g., 'en', 'es')")
    parser.add_argument("--ssml", action="store_true",
                       help="Treat input text as SSML")
    parser.add_argument("--demo", choices=["ssml", "batch", "voices"],
                       help="Run demonstration (ssml, batch, or voices)")
    
    args = parser.parse_args()
    
    try:
        # Create TTS client
        client = TTSClient()
        
        # List voices if requested
        if args.list_voices:
            print("Fetching available voices...")
            voices = await client.list_voices()
            
            print(f"\nFound {len(voices)} voices:")
            print("-" * 80)
            print(f"{'Name':<35} {'Display Name':<20} {'Locale':<10} {'Gender'}")
            print("-" * 80)
            
            for voice in voices[:20]:  # Show first 20 voices
                print(f"{voice.name:<35} {voice.display_name:<20} {voice.locale:<10} {voice.gender}")
            
            if len(voices) > 20:
                print(f"... and {len(voices) - 20} more voices")
            return
        
        # List voices by language if requested
        if args.voices_by_language:
            print(f"Fetching voices for language: {args.voices_by_language}")
            voices = await client.get_voices_by_language(args.voices_by_language)
            
            if not voices:
                print(f"No voices found for language: {args.voices_by_language}")
                return
            
            print(f"\nFound {len(voices)} voices for {args.voices_by_language}:")
            print("-" * 80)
            print(f"{'Name':<35} {'Display Name':<20} {'Locale':<10} {'Gender'}")
            print("-" * 80)
            
            for voice in voices:
                print(f"{voice.name:<35} {voice.display_name:<20} {voice.locale:<10} {voice.gender}")
            return
        
        # Run demonstrations if requested
        if args.demo:
            if args.demo == "ssml":
                await demo_ssml(client)
            elif args.demo == "batch":
                await demo_batch(client)
            elif args.demo == "voices":
                await demo_voices(client)
            return
            
            if len(voices) > 20:
                print(f"... and {len(voices) - 20} more voices")
            
            return
        
        # Create output directory
        output_dir = "output"
        create_output_directory(output_dir)
        
        # Generate output filename if not provided
        if args.output:
            output_file = args.output
        else:
            safe_name = get_safe_filename(args.text)
            output_file = os.path.join(output_dir, f"{safe_name}.mp3")
        
        print(f"Text: {args.text}")
        print(f"Voice: {args.voice}")
        print(f"Output: {output_file}")
        print()
        
        # Synthesize text
        print("Synthesizing speech...")
        audio_data = await client.synthesize_text(args.text, args.voice)
        
        # Save audio file
        print("Saving audio file...")
        await client.save_audio(audio_data, output_file)
        print(f"Audio saved to: {output_file}")
        
        # Play audio if requested
        if not args.no_play:
            try:
                print("Playing audio...")
                player = AudioPlayer()
                player.play_file(output_file)
                print("Playback completed!")
            except AudioError as e:
                print(f"Could not play audio: {e}")
                print("Audio file was saved successfully though.")
        
        print("\nDone!")
        
    except TTSError as e:
        print(f"TTS Error: {e}")
        return 1
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1
    
    return 0


async def demo_ssml(client):
    """Demonstrate SSML functionality."""
    print("=== SSML Demonstration ===")
    
    ssml_examples = [
        ('<speak><prosody rate="slow">This is spoken slowly.</prosody></speak>', "slow_speech.mp3"),
        ('<speak><prosody pitch="high">This is high pitch.</prosody></speak>', "high_pitch.mp3"),
        ('<speak>This is <emphasis level="strong">strongly emphasized</emphasis> text.</speak>', "emphasis.mp3"),
        ('<speak>First sentence.<break time="2s"/>After a long pause.</speak>', "with_break.mp3")
    ]
    
    for ssml, filename in ssml_examples:
        print(f"Generating: {filename}")
        print(f"SSML: {ssml}")
        
        try:
            audio_data = await client.synthesize_ssml(ssml)
            await client.save_audio(audio_data, f"output/{filename}")
            print(f"Saved: output/{filename}\n")
        except Exception as e:
            print(f"Error: {e}\n")


async def demo_batch(client):
    """Demonstrate batch processing."""
    print("=== Batch Processing Demonstration ===")
    
    texts = [
        "This is the first sentence in our batch.",
        "Here comes the second sentence.",
        "The third sentence follows naturally.",
        "Finally, we have the last sentence."
    ]
    
    voice = "en-US-AriaNeural"
    
    print("Processing texts sequentially...")
    for i, text in enumerate(texts, 1):
        print(f"Processing text {i}: {text[:30]}...")
        try:
            audio_data = await client.synthesize_text(text, voice)
            filename = f"output/batch_{i}.mp3"
            await client.save_audio(audio_data, filename)
            print(f"Saved: {filename}")
        except Exception as e:
            print(f"Error processing text {i}: {e}")
    
    print("Batch processing completed!")


async def demo_voices(client):
    """Demonstrate voice capabilities."""
    print("=== Voice Demonstration ===")
    
    text = "Hello, this is a voice demonstration."
    voices = ["en-US-AriaNeural", "en-US-DavisNeural", "en-GB-SoniaNeural"]
    
    for voice in voices:
        print(f"Generating with voice: {voice}")
        try:
            audio_data = await client.synthesize_text(text, voice)
            filename = f"output/voice_{voice.replace('-', '_')}.mp3"
            await client.save_audio(audio_data, filename)
            print(f"Saved: {filename}")
        except Exception as e:
            print(f"Error with voice {voice}: {e}")
    
    print("Voice demonstration completed!")


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)