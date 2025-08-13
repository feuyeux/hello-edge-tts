use crate::tts_client::{TTSConfig, TTSError};
use std::collections::HashMap;
use std::path::Path;

/// Configuration manager with preset support
pub struct ConfigManager;

impl ConfigManager {
    const DEFAULT_CONFIG_PATHS: &'static [&'static str] = &[
        "./tts_config.json",
        "~/.tts/config.json",
    ];

    /// Get predefined presets
    pub fn get_presets() -> HashMap<&'static str, TTSConfig> {
        let mut presets = HashMap::new();
        
        presets.insert("default", TTSConfig::default());
        
        presets.insert("fast", TTSConfig {
            rate: "+20%".to_string(),
            max_concurrent: 5,
            batch_size: 10,
            ..TTSConfig::default()
        });
        
        presets.insert("slow", TTSConfig {
            rate: "-20%".to_string(),
            max_concurrent: 2,
            batch_size: 3,
            ..TTSConfig::default()
        });
        
        presets.insert("high_quality", TTSConfig {
            output_format: "wav".to_string(),
            cache_voices: true,
            max_retries: 5,
            ..TTSConfig::default()
        });
        
        presets.insert("batch_processing", TTSConfig {
            max_concurrent: 8,
            batch_size: 20,
            cache_voices: true,
            ..TTSConfig::default()
        });
        
        presets.insert("whisper", TTSConfig {
            rate: "-10%".to_string(),
            volume: "50%".to_string(),
            pitch: "-5%".to_string(),
            ..TTSConfig::default()
        });
        
        presets.insert("excited", TTSConfig {
            rate: "+15%".to_string(),
            pitch: "+10%".to_string(),
            volume: "110%".to_string(),
            ..TTSConfig::default()
        });
        
        presets
    }

    /// Load configuration from file or use default
    pub fn load_config(config_path: Option<&str>) -> Result<TTSConfig, TTSError> {
        if let Some(path) = config_path {
            return TTSConfig::from_json_file(path);
        }

        // Try default paths
        for path in Self::DEFAULT_CONFIG_PATHS {
            let expanded_path = Self::expand_path(path);
            if Path::new(&expanded_path).exists() {
                return TTSConfig::from_json_file(&expanded_path);
            }
        }

        // Return default config if no file found
        Ok(TTSConfig::default())
    }

    /// Get a preset configuration
    pub fn get_preset(preset_name: &str) -> Result<TTSConfig, TTSError> {
        let presets = Self::get_presets();
        presets.get(preset_name)
            .cloned()
            .ok_or_else(|| {
                let available: Vec<_> = presets.keys().collect();
                let available_str = available.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(", ");
                TTSError::Config(format!("Unknown preset '{}'. Available: {}", preset_name, available_str))
            })
    }

    /// List available preset names
    pub fn list_presets() -> Vec<&'static str> {
        Self::get_presets().keys().cloned().collect()
    }

    /// Create a default configuration file
    pub fn create_default_config(file_path: &str, preset: &str) -> Result<(), TTSError> {
        let config = Self::get_preset(preset)?;
        config.to_json_file(file_path)?;
        println!("Created default configuration file: {}", file_path);
        Ok(())
    }

    /// Expand path with home directory
    fn expand_path(path: &str) -> String {
        if path.starts_with("~/") {
            if let Some(home) = std::env::var_os("HOME") {
                return path.replace("~", &home.to_string_lossy());
            }
        }
        path.to_string()
    }
}

/// Convenience functions
pub fn load_config(config_path: Option<&str>) -> Result<TTSConfig, TTSError> {
    ConfigManager::load_config(config_path)
}

pub fn get_preset(preset_name: &str) -> Result<TTSConfig, TTSError> {
    ConfigManager::get_preset(preset_name)
}

pub fn create_default_config(file_path: &str, preset: &str) -> Result<(), TTSError> {
    ConfigManager::create_default_config(file_path, preset)
}

pub fn list_presets() -> Vec<&'static str> {
    ConfigManager::list_presets()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = TTSConfig::default();
        assert_eq!(config.default_voice, "en-US-AriaNeural");
        assert_eq!(config.output_format, "mp3");
        assert_eq!(config.batch_size, 5);
        assert_eq!(config.max_concurrent, 3);
    }

    #[test]
    fn test_presets() {
        let presets = ConfigManager::get_presets();
        assert!(presets.contains_key("default"));
        assert!(presets.contains_key("fast"));
        assert!(presets.contains_key("slow"));
        
        let fast_config = presets.get("fast").unwrap();
        assert_eq!(fast_config.rate, "+20%");
        assert_eq!(fast_config.max_concurrent, 5);
    }

    #[test]
    fn test_get_preset() {
        let config = ConfigManager::get_preset("fast").unwrap();
        assert_eq!(config.rate, "+20%");
        assert_eq!(config.batch_size, 10);
    }

    #[test]
    fn test_unknown_preset() {
        let result = ConfigManager::get_preset("unknown");
        assert!(result.is_err());
    }

    #[test]
    fn test_list_presets() {
        let presets = ConfigManager::list_presets();
        assert!(presets.contains(&"default"));
        assert!(presets.contains(&"fast"));
        assert!(presets.contains(&"slow"));
    }

    #[test]
    fn test_config_validation() {
        let mut config = TTSConfig::default();
        assert!(config.validate().is_ok());

        config.default_voice = String::new();
        assert!(config.validate().is_err());

        config.default_voice = "en-US-AriaNeural".to_string();
        config.batch_size = 0;
        assert!(config.validate().is_err());
    }
}