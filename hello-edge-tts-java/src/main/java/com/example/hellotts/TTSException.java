package com.example.hellotts;

/**
 * Base exception class for TTS-related errors
 */
public class TTSException extends Exception {
    
    public TTSException(String message) {
        super(message);
    }
    
    public TTSException(String message, Throwable cause) {
        super(message, cause);
    }
}