//! Basic usage example for Hello Edge TTS
//!
//! This example demonstrates the core functionality of the Edge TTS client:
//! - Creating a TTS client
//! - Listing available voices
//! - Filtering voices by language
//! - Synthesizing text to speech (demo mode)
//! - Playing audio files
//!
//! Run this example with: cargo run --example hello_tts

use hello_edge_tts::prelude::*;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🚀 Hello Edge TTS - Basic Usage Example");
    println!("{}", "=".repeat(50));

    // Step 1: Create TTS client with default configuration
    println!("\n1️⃣ Creating TTS client...");
    let mut client = TTSClient::new(None);
    println!("✅ TTS client created successfully");

    // Step 2: List all available voices
    println!("\n2️⃣ Fetching available voices...");
    match client.list_voices().await {
        Ok(voices) => {
            println!("✅ Found {} voices total", voices.len());

            // Show first 5 voices as examples
            println!("\n📋 Sample voices:");
            for (i, voice) in voices.iter().take(5).enumerate() {
                println!(
                    "   {}. {} ({}) - {}",
                    i + 1,
                    voice.display_name,
                    voice.locale,
                    voice.gender
                );
            }

            if voices.len() > 5 {
                println!("   ... and {} more voices", voices.len() - 5);
            }
        }
        Err(e) => {
            eprintln!("❌ Failed to fetch voices: {}", e);
            return Ok(());
        }
    }

    // Step 3: Filter voices by language
    println!("\n3️⃣ Filtering voices by language...");
    let languages = vec!["en", "es", "fr", "de", "ja"];

    for lang in languages {
        match client.get_voices_by_language(lang).await {
            Ok(lang_voices) => {
                if !lang_voices.is_empty() {
                    println!(
                        "🌍 {} voices for '{}': {}",
                        lang_voices.len(),
                        lang.to_uppercase(),
                        lang_voices
                            .iter()
                            .take(3)
                            .map(|v| v.display_name.as_str())
                            .collect::<Vec<_>>()
                            .join(", ")
                    );
                    if lang_voices.len() > 3 {
                        println!("     ... and {} more", lang_voices.len() - 3);
                    }
                }
            }
            Err(e) => {
                eprintln!("❌ Failed to get voices for {}: {}", lang, e);
            }
        }
    }

    // Step 4: Demonstrate text synthesis (demo mode)
    println!("\n4️⃣ Demonstrating text synthesis...");

    // Get English voices for demo
    match client.get_voices_by_language("en").await {
        Ok(en_voices) => {
            if let Some(voice) = en_voices.first() {
                println!("🎤 Using voice: {} ({})", voice.display_name, voice.name);

                let demo_texts = vec![
                    "Hello, World!",
                    "This is a demonstration of Edge TTS with Rust.",
                    "The quick brown fox jumps over the lazy dog.",
                ];

                for (i, text) in demo_texts.iter().enumerate() {
                    println!("\n   📝 Synthesizing text {}: \"{}\"", i + 1, text);

                    match client.synthesize_text(text, &voice.name, None).await {
                        Ok(audio_data) => {
                            println!(
                                "   ✅ Synthesis successful! Generated {} bytes of audio data",
                                audio_data.len()
                            );

                            // Save to file
                            let filename = format!("edgetts_example_{}_rust.mp3", i + 1);
                            match client.save_audio(&audio_data, &filename).await {
                                Ok(()) => {
                                    println!("   💾 Audio saved to: {}", filename);
                                }
                                Err(e) => {
                                    eprintln!("   ❌ Failed to save audio: {}", e);
                                }
                            }
                        }
                        Err(e) => {
                            println!("   ❌ Synthesis failed: {}", e);
                            println!("   💡 This is expected in demo mode - full WebSocket implementation needed");
                        }
                    }
                }
            } else {
                println!("❌ No English voices available for demo");
            }
        }
        Err(e) => {
            eprintln!("❌ Failed to get English voices: {}", e);
        }
    }

    // Step 5: Demonstrate audio player functionality
    println!("\n5️⃣ Demonstrating audio player...");
    match AudioPlayer::new() {
        Ok(player) => {
            println!("✅ Audio player created successfully");
            println!("🔊 Current volume: {:.1}%", player.volume() * 100.0);

            // Demonstrate volume control
            player.set_volume(0.8);
            println!("🔧 Volume set to: {:.1}%", player.volume() * 100.0);

            // Note: We can't actually play audio in this demo since we don't have real audio files
            println!("💡 Audio player is ready to play files with player.play_file(filename)");
            println!("💡 Use player.play_audio_data(audio_bytes) to play raw audio data");
        }
        Err(e) => {
            eprintln!("❌ Failed to create audio player: {}", e);
            eprintln!("💡 This might happen if no audio devices are available");
        }
    }

    // Step 6: Demonstrate configuration
    println!("\n6️⃣ Demonstrating custom configuration...");
    let custom_config = TTSConfig {
        default_voice: "en-US-JennyNeural".to_string(),
        output_format: "wav".to_string(),
        output_directory: "./custom_output".to_string(),
        auto_play: false,
        cache_voices: true,
        max_retries: 5,
        timeout: std::time::Duration::from_secs(45),
        rate: "0%".to_string(),
        pitch: "0%".to_string(),
        volume: "100%".to_string(),
        ssml: false,
        batch_size: 5,
        max_concurrent: 3,
    };

    let _custom_client = TTSClient::new(Some(custom_config));
    println!("✅ Custom TTS client created with:");
    println!("   • Default voice: en-US-JennyNeural");
    println!("   • Output format: WAV");
    println!("   • Output directory: ./custom_output");
    println!("   • Auto-play: disabled");
    println!("   • Voice caching: enabled");
    println!("   • Max retries: 5");
    println!("   • Timeout: 45 seconds");

    // Step 7: Summary and next steps
    println!("\n🎉 Basic usage example completed!");
    println!("{}", "=".repeat(50));
    println!("📚 What you learned:");
    println!("   • How to create and configure a TTS client");
    println!("   • How to list and filter available voices");
    println!("   • How to synthesize text to speech (API structure)");
    println!("   • How to use the audio player for playback");
    println!("   • How to customize client configuration");

    println!("\n🚀 Next steps:");
    println!("   • Try the CLI: cargo run -- speak --text 'Hello' --voice en-US-AriaNeural");
    println!("   • List voices: cargo run -- voices --language en");
    println!("   • Run demo: cargo run -- demo --language en");
    println!("   • Implement WebSocket communication for actual TTS synthesis");

    println!("\n💡 Note: This example shows the API structure. Full Edge TTS synthesis");
    println!("   requires WebSocket implementation which is beyond this demo scope.");

    Ok(())
}
