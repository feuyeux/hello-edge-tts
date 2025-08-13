use hello_edge_tts::prelude::*;
use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "hello-edge-tts")]
#[command(about = "A Rust implementation of Edge TTS demonstration")]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Convert text to speech
    Speak {
        /// Text to convert to speech
        #[arg(short, long)]
        text: String,
        
        /// Voice to use for synthesis
        #[arg(short, long, default_value = "en-US-AriaNeural")]
        voice: String,
        
        /// Output file path
        #[arg(short, long)]
        output: Option<PathBuf>,
        
        /// Play audio after synthesis
        #[arg(short, long, default_value = "true")]
        play: bool,
    },
    /// List available voices
    Voices {
        /// Filter by language code (e.g., 'en', 'fr', 'es')
        #[arg(short, long)]
        language: Option<String>,
        
        /// Show detailed information
        #[arg(short, long)]
        detailed: bool,
    },
    /// Run basic demo
    Demo {
        /// Language for demo
        #[arg(short, long, default_value = "en")]
        language: String,
    },
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Speak { text, voice, output, play } => {
            handle_speak(text, voice, output, play).await?;
        }
        Commands::Voices { language, detailed } => {
            handle_voices(language, detailed).await?;
        }
        Commands::Demo { language } => {
            handle_demo(language).await?;
        }
    }
    
    Ok(())
}

async fn handle_speak(text: String, voice: String, output: Option<PathBuf>, play: bool) -> Result<(), Box<dyn std::error::Error>> {
    println!("🎤 Converting text to speech...");
    println!("Text: {}", text);
    println!("Voice: {}", voice);
    
    let mut client = TTSClient::new(None);
    
    // Verify the voice exists
    match client.list_voices().await {
        Ok(voices) => {
            if !voices.iter().any(|v| v.name == voice) {
                eprintln!("❌ Voice '{}' not found!", voice);
                eprintln!("💡 Use 'hello-edge-tts voices' to see available voices");
                return Ok(());
            }
        }
        Err(e) => {
            eprintln!("❌ Failed to list voices: {}", e);
            return Ok(());
        }
    }
    
    // Attempt synthesis (will show demo message since WebSocket implementation is complex)
    match client.synthesize_text(&text, &voice, None).await {
        Ok(audio_data) => {
            let output_path = output.unwrap_or_else(|| PathBuf::from("hello.mp3"));
            
            match client.save_audio(&audio_data, output_path.to_str().unwrap()).await {
                Ok(()) => {
                    println!("✅ Audio saved to: {}", output_path.display());
                    
                    if play {
                        println!("🔊 Playing audio...");
                        match AudioPlayer::new() {
                            Ok(player) => {
                                if let Err(e) = player.play_file(output_path.to_str().unwrap()) {
                                    eprintln!("❌ Failed to play audio: {}", e);
                                }
                            }
                            Err(e) => {
                                eprintln!("❌ Failed to create audio player: {}", e);
                            }
                        }
                    }
                }
                Err(e) => {
                    eprintln!("❌ Failed to save audio: {}", e);
                }
            }
        }
        Err(e) => {
            eprintln!("❌ TTS synthesis failed: {}", e);
            eprintln!("💡 This is a demo implementation. Full WebSocket support needed for actual synthesis.");
        }
    }
    
    Ok(())
}

async fn handle_voices(language: Option<String>, detailed: bool) -> Result<(), Box<dyn std::error::Error>> {
    println!("🎵 Fetching available voices...");
    
    let mut client = TTSClient::new(None);
    
    let voices = match language {
        Some(lang) => {
            println!("Filtering by language: {}", lang);
            client.get_voices_by_language(&lang).await?
        }
        None => client.list_voices().await?,
    };
    
    if voices.is_empty() {
        println!("No voices found for the specified criteria.");
        return Ok(());
    }
    
    println!("\n📋 Available voices ({} total):", voices.len());
    println!("{}", "=".repeat(60));
    
    if detailed {
        for voice in voices {
            println!("🎤 {}", voice.display_name);
            println!("   Name: {}", voice.name);
            println!("   Locale: {}", voice.locale);
            println!("   Gender: {}", voice.gender);
            println!("   Language: {}", voice.language_code());
            println!();
        }
    } else {
        // Group by language for better organization
        let mut by_language: std::collections::HashMap<String, Vec<Voice>> = std::collections::HashMap::new();
        
        for voice in voices {
            by_language.entry(voice.language_code().to_string())
                .or_insert_with(Vec::new)
                .push(voice);
        }
        
        for (lang, mut voices) in by_language {
            voices.sort_by(|a, b| a.display_name.cmp(&b.display_name));
            println!("\n🌍 {} ({} voices):", lang.to_uppercase(), voices.len());
            for voice in voices {
                println!("  • {} ({}) - {}", voice.display_name, voice.locale, voice.gender);
            }
        }
    }
    
    Ok(())
}

async fn handle_demo(language: String) -> Result<(), Box<dyn std::error::Error>> {
    println!("🚀 Running Hello Edge TTS Demo");
    println!("Language: {}", language);
    println!("{}", "=".repeat(40));
    
    let mut client = TTSClient::new(None);
    
    // Get voices for the specified language
    println!("1️⃣ Fetching voices for language '{}'...", language);
    let voices = client.get_voices_by_language(&language).await?;
    
    if voices.is_empty() {
        eprintln!("❌ No voices found for language '{}'", language);
        eprintln!("💡 Try 'hello-edge-tts voices' to see all available languages");
        return Ok(());
    }
    
    println!("✅ Found {} voice(s)", voices.len());
    
    // Show first few voices
    let display_count = std::cmp::min(3, voices.len());
    println!("\n2️⃣ Sample voices:");
    for (i, voice) in voices.iter().take(display_count).enumerate() {
        println!("   {}. {} ({}) - {}", i + 1, voice.display_name, voice.locale, voice.gender);
    }
    
    // Demonstrate synthesis with first voice
    if let Some(first_voice) = voices.first() {
        println!("\n3️⃣ Demonstrating synthesis with '{}'...", first_voice.display_name);
        
        let demo_texts = match language.as_str() {
            "en" => vec!["Hello, World!", "Welcome to Edge TTS with Rust!"],
            "es" => vec!["¡Hola, Mundo!", "¡Bienvenido a Edge TTS con Rust!"],
            "fr" => vec!["Bonjour, le Monde!", "Bienvenue à Edge TTS avec Rust!"],
            "de" => vec!["Hallo, Welt!", "Willkommen bei Edge TTS mit Rust!"],
            "ja" => vec!["こんにちは、世界！", "RustでEdge TTSへようこそ！"],
            "zh" => vec!["你好，世界！", "欢迎使用Rust的Edge TTS！"],
            _ => vec!["Hello, World!", "Welcome to Edge TTS with Rust!"],
        };
        
        for (i, text) in demo_texts.iter().enumerate() {
            println!("   📝 Text {}: {}", i + 1, text);
            
            match client.synthesize_text(text, &first_voice.name, None).await {
                Ok(_audio_data) => {
                    println!("   ✅ Synthesis successful (demo mode)");
                }
                Err(e) => {
                    println!("   ❌ Synthesis failed: {}", e);
                    println!("   💡 This is expected in demo mode - WebSocket implementation needed");
                }
            }
        }
    }
    
    println!("\n🎉 Demo completed!");
    println!("💡 Use 'hello-edge-tts speak --help' for synthesis options");
    println!("💡 Use 'hello-edge-tts voices --help' for voice listing options");
    
    Ok(())
}