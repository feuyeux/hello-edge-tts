"""
Configuration management for TTS client.
"""

import json
import yaml
import os
from dataclasses import dataclass, asdict
from typing import Optional, Dict, Any
from pathlib import Path


@dataclass
class TTSConfig:
    """
    Configuration class for TTS client settings.
    """
    
    default_voice: str = "en-US-AriaNeural"
    output_format: str = "mp3"
    output_directory: str = "./output"
    auto_play: bool = True
    cache_voices: bool = True
    max_retries: int = 3
    timeout: int = 30000  # milliseconds
    rate: str = "0%"
    pitch: str = "0%"
    volume: str = "100%"
    ssml: bool = False
    batch_size: int = 5
    max_concurrent: int = 3
    
    def __post_init__(self):
        """Validate configuration after initialization."""
        if self.max_retries < 0:
            raise ValueError("max_retries must be non-negative")
        if self.timeout <= 0:
            raise ValueError("timeout must be positive")
        if not self.default_voice:
            raise ValueError("default_voice cannot be empty")
        if self.batch_size <= 0:
            raise ValueError("batch_size must be positive")
        if self.max_concurrent <= 0:
            raise ValueError("max_concurrent must be positive")
    
    @classmethod
    def from_dict(cls, config_dict: Dict[str, Any]) -> 'TTSConfig':
        """Create TTSConfig from dictionary."""
        # Filter out unknown keys
        valid_keys = {field.name for field in cls.__dataclass_fields__.values()}
        filtered_dict = {k: v for k, v in config_dict.items() if k in valid_keys}
        return cls(**filtered_dict)
    
    @classmethod
    def from_json_file(cls, file_path: str) -> 'TTSConfig':
        """Load configuration from JSON file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                config_dict = json.load(f)
            return cls.from_dict(config_dict)
        except FileNotFoundError:
            raise FileNotFoundError(f"Configuration file not found: {file_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in configuration file: {e}")
    
    @classmethod
    def from_yaml_file(cls, file_path: str) -> 'TTSConfig':
        """Load configuration from YAML file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                config_dict = yaml.safe_load(f)
            return cls.from_dict(config_dict or {})
        except FileNotFoundError:
            raise FileNotFoundError(f"Configuration file not found: {file_path}")
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML in configuration file: {e}")
    
    @classmethod
    def from_file(cls, file_path: str) -> 'TTSConfig':
        """Load configuration from file (auto-detect format)."""
        path = Path(file_path)
        if path.suffix.lower() == '.json':
            return cls.from_json_file(file_path)
        elif path.suffix.lower() in ['.yaml', '.yml']:
            return cls.from_yaml_file(file_path)
        else:
            raise ValueError(f"Unsupported configuration file format: {path.suffix}")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert TTSConfig to dictionary."""
        return asdict(self)
    
    def to_json_file(self, file_path: str, indent: int = 2) -> None:
        """Save configuration to JSON file."""
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=indent)
    
    def to_yaml_file(self, file_path: str) -> None:
        """Save configuration to YAML file."""
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            yaml.dump(self.to_dict(), f, default_flow_style=False, indent=2)
    
    def to_file(self, file_path: str) -> None:
        """Save configuration to file (auto-detect format)."""
        path = Path(file_path)
        if path.suffix.lower() == '.json':
            self.to_json_file(file_path)
        elif path.suffix.lower() in ['.yaml', '.yml']:
            self.to_yaml_file(file_path)
        else:
            raise ValueError(f"Unsupported configuration file format: {path.suffix}")


class ConfigManager:
    """Configuration manager with preset support."""
    
    DEFAULT_CONFIG_PATHS = [
        "./tts_config.json",
        "./tts_config.yaml",
        "~/.tts/config.json",
        "~/.tts/config.yaml"
    ]
    
    PRESETS = {
        "default": TTSConfig(),
        "fast": TTSConfig(
            rate="+20%",
            max_concurrent=5,
            batch_size=10
        ),
        "slow": TTSConfig(
            rate="-20%",
            max_concurrent=2,
            batch_size=3
        ),
        "high_quality": TTSConfig(
            output_format="wav",
            cache_voices=True,
            max_retries=5
        ),
        "batch_processing": TTSConfig(
            max_concurrent=8,
            batch_size=20,
            cache_voices=True
        ),
        "whisper": TTSConfig(
            rate="-10%",
            volume="50%",
            pitch="-5%"
        ),
        "excited": TTSConfig(
            rate="+15%",
            pitch="+10%",
            volume="110%"
        )
    }
    
    @classmethod
    def load_config(cls, config_path: Optional[str] = None) -> TTSConfig:
        """Load configuration from file or use default."""
        if config_path:
            return TTSConfig.from_file(config_path)
        
        # Try default paths
        for path in cls.DEFAULT_CONFIG_PATHS:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                return TTSConfig.from_file(expanded_path)
        
        # Return default config if no file found
        return TTSConfig()
    
    @classmethod
    def get_preset(cls, preset_name: str) -> TTSConfig:
        """Get a preset configuration."""
        if preset_name not in cls.PRESETS:
            available = ', '.join(cls.PRESETS.keys())
            raise ValueError(f"Unknown preset '{preset_name}'. Available: {available}")
        return cls.PRESETS[preset_name]
    
    @classmethod
    def list_presets(cls) -> list[str]:
        """List available preset names."""
        return list(cls.PRESETS.keys())
    
    @classmethod
    def create_default_config(cls, file_path: str, preset: str = "default") -> None:
        """Create a default configuration file."""
        config = cls.get_preset(preset)
        config.to_file(file_path)
        print(f"Created default configuration file: {file_path}")


# Convenience functions
def load_config(config_path: Optional[str] = None) -> TTSConfig:
    """Load configuration from file or use default."""
    return ConfigManager.load_config(config_path)


def get_preset(preset_name: str) -> TTSConfig:
    """Get a preset configuration."""
    return ConfigManager.get_preset(preset_name)


def create_default_config(file_path: str, preset: str = "default") -> None:
    """Create a default configuration file."""
    ConfigManager.create_default_config(file_path, preset)