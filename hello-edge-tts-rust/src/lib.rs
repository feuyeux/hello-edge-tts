//! Hello Edge TTS - Rust implementation
//!
//! This crate provides a Rust client for Microsoft Edge TTS service,
//! demonstrating text-to-speech functionality with audio playback capabilities.

pub mod audio_player;
pub mod config_manager;
pub mod ssml_utils;
pub mod tts_client;

pub use audio_player::{AudioError, AudioPlayer};
pub use config_manager::{
    create_default_config, get_preset, list_presets, load_config, ConfigManager,
};
pub use ssml_utils::{SSMLBuilder, SSMLTemplates, SSMLValidator};
pub use tts_client::{TTSClient, TTSConfig, TTSError, Voice};

/// Re-export commonly used types
pub mod prelude {
    pub use crate::{
        create_default_config, get_preset, list_presets, load_config, AudioError, AudioPlayer,
        ConfigManager, SSMLBuilder, SSMLTemplates, SSMLValidator, TTSClient, TTSConfig, TTSError,
        Voice,
    };
}
