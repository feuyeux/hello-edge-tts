#!/usr/bin/env python3
"""
Multilingual batch demo for Edge TTS Python implementation.
Generates audio files for 12 languages with specified sentences.
"""

import asyncio
import json
import os
import time
from pathlib import Path
import sys

# Add the parent directory to Python path to import local modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from tts_client import TTSClient, TTSError
from audio_player import AudioPlayer, AudioError
from utils import create_output_directory


async def load_language_config():
    """Load language configuration from shared config file."""
    config_path = "../shared/multilingual_demo_config.json"
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Configuration file not found: {config_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing configuration file: {e}")
        return None


async def generate_audio_for_language(client, language_config, output_dir, play_audio=False):
    """Generate audio for a single language configuration."""
    lang_code = language_config['code']
    lang_name = language_config['name']
    flag = language_config['flag']
    text = language_config['text']
    voice = language_config['voice']
    alt_voice = language_config.get('alt_voice')
    
    print(f"\n{flag} {lang_name} ({lang_code.upper()})")
    print(f"Text: {text}")
    print(f"Voice: {voice}")
    
    try:
        # Try primary voice first
        audio_data = None
        used_voice = voice
        
        try:
            audio_data = await client.synthesize_text(text, voice)
        except TTSError as e:
            print(f"Primary voice failed: {e}")
            if alt_voice:
                print(f"Trying alternative voice: {alt_voice}")
                try:
                    audio_data = await client.synthesize_text(text, alt_voice)
                    used_voice = alt_voice
                except TTSError as e2:
                    print(f"Alternative voice also failed: {e2}")
                    raise e2
            else:
                raise e
        
        # Generate filename
        timestamp = int(time.time())
        lang_prefix = lang_code.split('-')[0]  # e.g., 'zh' from 'zh-cn'
        filename = f"multilingual_{lang_prefix}_python_{timestamp}.mp3"
        output_path = os.path.join(output_dir, filename)
        
        # Save audio
        await client.save_audio(audio_data, output_path)
        
        print(f"✅ Generated: {filename}")
        print(f"📁 Saved to: {output_path}")
        print(f"🎤 Used voice: {used_voice}")
        
        # Play audio if requested
        if play_audio:
            try:
                print("🔊 Playing audio...")
                player = AudioPlayer()
                player.play_file(output_path)
                print("✅ Playback completed")
            except AudioError as e:
                print(f"⚠️  Could not play audio: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to generate audio for {lang_name}: {e}")
        return False


async def main():
    """Main function for multilingual demo."""
    print("🌍 Multilingual Edge TTS Demo - Python Implementation")
    print("=" * 60)
    print("Generating audio for 12 languages with custom sentences...")
    
    # Load language configuration
    config = await load_language_config()
    if not config:
        print("❌ Failed to load language configuration")
        return 1
    
    languages = config.get('languages', [])
    if not languages:
        print("❌ No languages found in configuration")
        return 1
    
    print(f"📋 Found {len(languages)} languages to process")
    
    # Create output directory
    output_dir = "output"
    create_output_directory(output_dir)
    print(f"📁 Output directory: {os.path.abspath(output_dir)}")
    
    # Initialize TTS client
    try:
        client = TTSClient()
        print("✅ TTS client initialized")
    except Exception as e:
        print(f"❌ Failed to initialize TTS client: {e}")
        return 1
    
    # Process each language
    successful_count = 0
    failed_count = 0
    start_time = time.time()
    
    for i, language_config in enumerate(languages, 1):
        print(f"\n📍 Processing language {i}/{len(languages)}")
        
        success = await generate_audio_for_language(
            client, 
            language_config, 
            output_dir, 
            play_audio=False  # Set to True if you want to play each audio
        )
        
        if success:
            successful_count += 1
        else:
            failed_count += 1
        
        # Small delay between languages to be polite to the service
        if i < len(languages):
            print("⏳ Waiting before next language...")
            await asyncio.sleep(2)
    
    # Summary
    end_time = time.time()
    duration = end_time - start_time
    
    print(f"\n🏁 Processing Complete!")
    print("=" * 40)
    print(f"✅ Successful: {successful_count}")
    print(f"❌ Failed: {failed_count}")
    print(f"⏱️  Total time: {duration:.2f} seconds")
    print(f"📁 Output files saved in: {os.path.abspath(output_dir)}")
    
    if successful_count > 0:
        print(f"\n🎉 Successfully generated audio files for {successful_count} languages!")
        print("You can find all generated MP3 files in the output directory.")
    
    return 0 if failed_count == 0 else 1


if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n⏹️  Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Unexpected error: {e}")
        sys.exit(1)