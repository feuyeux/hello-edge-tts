package com.example.hellotts;

/**
 * Exception for audio-related TTS errors
 */
public class AudioException extends TTSException {
    
    public AudioException(String message) {
        super(message);
    }
    
    public AudioException(String message, Throwable cause) {
        super(message, cause);
    }
}