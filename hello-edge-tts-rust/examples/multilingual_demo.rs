use hello_edge_tts::prelude::*;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::time::{sleep, Duration};

#[derive(Debug, Deserialize, Serialize)]
struct LanguageConfig {
    code: String,
    name: String,
    flag: String,
    text: String,
    voice: String,
    alt_voice: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Config {
    languages: Vec<LanguageConfig>,
}

/// Load language configuration from JSON file
fn load_language_config() -> Result<Vec<LanguageConfig>, Box<dyn std::error::Error>> {
    let config_path = "../shared/multilingual_demo_config.json";
    
    match fs::read_to_string(config_path) {
        Ok(content) => {
            let config: Config = serde_json::from_str(&content)?;
            Ok(config.languages)
        }
        Err(e) => {
            eprintln!("❌ Configuration file not found: {}", config_path);
            Err(Box::new(e))
        }
    }
}

/// Generate audio for a single language
async fn generate_audio_for_language(
    client: &mut TTSClient,
    language_config: &LanguageConfig,
    output_dir: &str,
    play_audio: bool,
) -> Result<bool, Box<dyn std::error::Error>> {
    let lang_code = &language_config.code;
    let lang_name = &language_config.name;
    let flag = &language_config.flag;
    let text = &language_config.text;
    let voice = &language_config.voice;
    let alt_voice = &language_config.alt_voice;

    println!("\n{} {} ({})", flag, lang_name, lang_code.to_uppercase());
    println!("Text: {}", text);
    println!("Voice: {}", voice);

    // Try primary voice first
    let mut used_voice = voice.clone();
    let audio_data = match client.synthesize_text(text, voice, None).await {
        Ok(data) => data,
        Err(e) => {
            println!("Primary voice failed: {}", e);
            if let Some(alt_voice_name) = alt_voice {
                println!("Trying alternative voice: {}", alt_voice_name);
                match client.synthesize_text(text, alt_voice_name, None).await {
                    Ok(data) => {
                        used_voice = alt_voice_name.clone();
                        data
                    }
                    Err(e2) => {
                        println!("Alternative voice also failed: {}", e2);
                        return Ok(false);
                    }
                }
            } else {
                println!("❌ Failed to generate audio for {}: {}", lang_name, e);
                return Ok(false);
            }
        }
    };

    // Generate filename
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)?
        .as_secs();
    let lang_prefix = lang_code.split('-').next().unwrap_or("unknown");
    let filename = format!("multilingual_{}_rust_{}.mp3", lang_prefix, timestamp);
    let output_path = PathBuf::from(output_dir).join(&filename);

    // Save audio
    match client.save_audio(&audio_data, output_path.to_str().unwrap()).await {
        Ok(_) => {
            println!("✅ Generated: {}", filename);
            println!("📁 Saved to: {}", output_path.display());
            println!("🎤 Used voice: {}", used_voice);

            // Play audio if requested
            if play_audio {
                match AudioPlayer::new() {
                    Ok(player) => {
                        println!("🔊 Playing audio...");
                        match player.play_file(output_path.to_str().unwrap()) {
                            Ok(_) => println!("✅ Playback completed"),
                            Err(e) => println!("⚠️  Could not play audio: {}", e),
                        }
                    }
                    Err(e) => println!("⚠️  Could not create audio player: {}", e),
                }
            }

            Ok(true)
        }
        Err(e) => {
            println!("❌ Failed to save audio for {}: {}", lang_name, e);
            Ok(false)
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🌍 Multilingual Edge TTS Demo - Rust Implementation");
    println!("{}", "=".repeat(60));
    println!("Generating audio for 12 languages with custom sentences...");

    // Load language configuration
    let languages = match load_language_config() {
        Ok(langs) => langs,
        Err(e) => {
            eprintln!("❌ Failed to load language configuration: {}", e);
            std::process::exit(1);
        }
    };

    if languages.is_empty() {
        eprintln!("❌ No languages found in configuration");
        std::process::exit(1);
    }

    println!("📋 Found {} languages to process", languages.len());

    // Create output directory
    let output_dir = "./";  // Using current directory for Rust implementation
    let output_path = std::fs::canonicalize(output_dir)?;
    println!("📁 Output directory: {}", output_path.display());

    // Initialize TTS client
    let mut client = TTSClient::new(None);
    println!("✅ TTS client initialized");

    // Process each language
    let mut successful_count = 0;
    let mut failed_count = 0;
    let start_time = std::time::Instant::now();

    for (i, language_config) in languages.iter().enumerate() {
        println!("\n📍 Processing language {}/{}", i + 1, languages.len());

        match generate_audio_for_language(&mut client, language_config, output_dir, false).await {
            Ok(success) => {
                if success {
                    successful_count += 1;
                } else {
                    failed_count += 1;
                }
            }
            Err(e) => {
                println!("❌ Error processing {}: {}", language_config.name, e);
                failed_count += 1;
            }
        }

        // Small delay between languages to be polite to the service
        if i < languages.len() - 1 {
            println!("⏳ Waiting before next language...");
            sleep(Duration::from_secs(2)).await;
        }
    }

    // Summary
    let duration = start_time.elapsed();

    println!("\n🏁 Processing Complete!");
    println!("{}", "=".repeat(40));
    println!("✅ Successful: {}", successful_count);
    println!("❌ Failed: {}", failed_count);
    println!("⏱️  Total time: {:.2} seconds", duration.as_secs_f64());
    println!("📁 Output files saved in: {}", output_path.display());

    if successful_count > 0 {
        println!("\n🎉 Successfully generated audio files for {} languages!", successful_count);
        println!("You can find all generated MP3 files in the output directory.");
    }

    if failed_count > 0 {
        std::process::exit(1);
    }

    Ok(())
}