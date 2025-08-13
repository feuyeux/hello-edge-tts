//! Hello Edge TTS - Rust implementation
//! 
//! This crate provides a Rust client for Microsoft Edge TTS service,
//! demonstrating text-to-speech functionality with audio playback capabilities.

pub mod tts_client;
pub mod audio_player;
pub mod ssml_utils;
pub mod config_manager;

pub use tts_client::{TTSClient, TTSConfig, TTSError, Voice};
pub use audio_player::{AudioPlayer, AudioError};
pub use ssml_utils::{SSMLBuilder, SSMLValidator, SSMLTemplates};
pub use config_manager::{ConfigManager, load_config, get_preset, create_default_config, list_presets};

/// Re-export commonly used types
pub mod prelude {
    pub use crate::{TTSClient, TTSConfig, TTSError, Voice, AudioPlayer, AudioError, SSMLBuilder, SSMLValidator, SSMLTemplates, ConfigManager, load_config, get_preset, create_default_config, list_presets};
}