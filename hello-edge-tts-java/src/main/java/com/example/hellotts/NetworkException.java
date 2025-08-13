package com.example.hellotts;

/**
 * Exception for network-related TTS errors
 */
public class NetworkException extends TTSException {
    
    public NetworkException(String message) {
        super(message);
    }
    
    public NetworkException(String message, Throwable cause) {
        super(message, cause);
    }
}