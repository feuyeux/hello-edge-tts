use rodio::{Decoder, OutputStream, Sink};
use std::fs::File;
use std::io::{BufReader, Cursor};

/// Custom error type for audio operations
#[derive(Debug, thiserror::Error)]
pub enum AudioError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Audio decode error: {0}")]
    Decode(String),
    #[error("Audio playback error: {0}")]
    Playback(String),
    #[error("Audio device error: {0}")]
    Device(String),
}

/// Audio player for cross-platform audio playback
pub struct AudioPlayer {
    _stream: OutputStream,
    sink: Sink,
}

impl AudioPlayer {
    /// Create a new AudioPlayer instance
    pub fn new() -> Result<Self, AudioError> {
        let (_stream, stream_handle) = OutputStream::try_default()
            .map_err(|e| AudioError::Device(format!("Failed to get audio device: {}", e)))?;

        let sink = Sink::try_new(&stream_handle)
            .map_err(|e| AudioError::Device(format!("Failed to create audio sink: {}", e)))?;

        Ok(Self { _stream, sink })
    }

    /// Play audio from a file
    pub fn play_file(&self, filename: &str) -> Result<(), AudioError> {
        let file = File::open(filename)?;
        let source = Decoder::new(BufReader::new(file))
            .map_err(|e| AudioError::Decode(format!("Failed to decode audio file: {}", e)))?;

        self.sink.append(source);

        // Wait for playback to complete
        self.sink.sleep_until_end();

        Ok(())
    }

    /// Play audio from raw audio data
    pub fn play_audio_data(
        &self,
        audio_data: Vec<u8>,
        format_hint: Option<&str>,
    ) -> Result<(), AudioError> {
        let _format_hint = format_hint.unwrap_or("mp3"); // Store for potential future use

        let cursor = Cursor::new(audio_data);
        let source = Decoder::new(cursor)
            .map_err(|e| AudioError::Decode(format!("Failed to decode audio data: {}", e)))?;

        self.sink.append(source);

        // Wait for playback to complete
        self.sink.sleep_until_end();

        Ok(())
    }

    /// Stop current playback
    pub fn stop(&self) {
        self.sink.stop();
    }

    /// Pause current playback
    pub fn pause(&self) {
        self.sink.pause();
    }

    /// Resume paused playback
    pub fn resume(&self) {
        self.sink.play();
    }

    /// Check if audio is currently playing
    pub fn is_playing(&self) -> bool {
        !self.sink.empty()
    }

    /// Set playback volume (0.0 to 1.0)
    pub fn set_volume(&self, volume: f32) {
        self.sink.set_volume(volume.clamp(0.0, 1.0));
    }

    /// Get current playback volume
    pub fn volume(&self) -> f32 {
        self.sink.volume()
    }
}

impl Default for AudioPlayer {
    fn default() -> Self {
        Self::new().expect("Failed to create default AudioPlayer")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_audio_player_creation() {
        let result = AudioPlayer::new();
        assert!(result.is_ok(), "AudioPlayer creation should succeed");
    }

    #[test]
    fn test_volume_control() {
        if let Ok(player) = AudioPlayer::new() {
            player.set_volume(0.5);
            assert_eq!(player.volume(), 0.5);

            player.set_volume(1.5); // Should be clamped to 1.0
            assert_eq!(player.volume(), 1.0);

            player.set_volume(-0.5); // Should be clamped to 0.0
            assert_eq!(player.volume(), 0.0);
        }
    }

    #[test]
    fn test_playback_controls() {
        if let Ok(player) = AudioPlayer::new() {
            // Test that controls don't panic
            player.pause();
            player.resume();
            player.stop();
        }
    }
}
