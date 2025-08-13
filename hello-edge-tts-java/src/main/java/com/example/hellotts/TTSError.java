package com.example.hellotts;

/**
 * Custom exception class for TTS-related errors.
 * Provides consistent error handling across the TTS client implementation.
 */
public class TTSError extends Exception {
    
    /**
     * Error categories for better error classification
     */
    public enum ErrorType {
        NETWORK,
        SYNTHESIS,
        VALIDATION,
        IO,
        CONFIG,
        VOICE_NOT_FOUND
    }
    
    private final ErrorType errorType;
    
    /**
     * Creates a new TTSError with a message.
     *
     * @param message The error message
     */
    public TTSError(String message) {
        super(message);
        this.errorType = ErrorType.SYNTHESIS; // Default type
    }
    
    /**
     * Creates a new TTSError with a message and cause.
     *
     * @param message The error message
     * @param cause The underlying cause
     */
    public TTSError(String message, Throwable cause) {
        super(message, cause);
        this.errorType = ErrorType.SYNTHESIS; // Default type
    }
    
    /**
     * Creates a new TTSError with a message and error type.
     *
     * @param message The error message
     * @param errorType The error type category
     */
    public TTSError(String message, ErrorType errorType) {
        super(message);
        this.errorType = errorType;
    }
    
    /**
     * Creates a new TTSError with a message, cause, and error type.
     *
     * @param message The error message
     * @param cause The underlying cause
     * @param errorType The error type category
     */
    public TTSError(String message, Throwable cause, ErrorType errorType) {
        super(message, cause);
        this.errorType = errorType;
    }
    
    /**
     * Gets the error type category.
     *
     * @return The error type
     */
    public ErrorType getErrorType() {
        return errorType;
    }
    
    /**
     * Creates a network-related TTS error.
     *
     * @param message The error message
     * @return A new TTSError with NETWORK type
     */
    public static TTSError networkError(String message) {
        return new TTSError(message, ErrorType.NETWORK);
    }
    
    /**
     * Creates a network-related TTS error with cause.
     *
     * @param message The error message
     * @param cause The underlying cause
     * @return A new TTSError with NETWORK type
     */
    public static TTSError networkError(String message, Throwable cause) {
        return new TTSError(message, cause, ErrorType.NETWORK);
    }
    
    /**
     * Creates a synthesis-related TTS error.
     *
     * @param message The error message
     * @return A new TTSError with SYNTHESIS type
     */
    public static TTSError synthesisError(String message) {
        return new TTSError(message, ErrorType.SYNTHESIS);
    }
    
    /**
     * Creates a synthesis-related TTS error with cause.
     *
     * @param message The error message
     * @param cause The underlying cause
     * @return A new TTSError with SYNTHESIS type
     */
    public static TTSError synthesisError(String message, Throwable cause) {
        return new TTSError(message, cause, ErrorType.SYNTHESIS);
    }
    
    /**
     * Creates a validation-related TTS error.
     *
     * @param message The error message
     * @return A new TTSError with VALIDATION type
     */
    public static TTSError validationError(String message) {
        return new TTSError(message, ErrorType.VALIDATION);
    }
    
    /**
     * Creates an IO-related TTS error.
     *
     * @param message The error message
     * @param cause The underlying cause
     * @return A new TTSError with IO type
     */
    public static TTSError ioError(String message, Throwable cause) {
        return new TTSError(message, cause, ErrorType.IO);
    }
    
    /**
     * Creates a configuration-related TTS error.
     *
     * @param message The error message
     * @return A new TTSError with CONFIG type
     */
    public static TTSError configError(String message) {
        return new TTSError(message, ErrorType.CONFIG);
    }
    
    /**
     * Creates a voice not found TTS error.
     *
     * @param voiceName The name of the voice that was not found
     * @return A new TTSError with VOICE_NOT_FOUND type
     */
    public static TTSError voiceNotFoundError(String voiceName) {
        return new TTSError("Voice not found: " + voiceName, ErrorType.VOICE_NOT_FOUND);
    }
    
    @Override
    public String toString() {
        return String.format("TTSError[%s]: %s", errorType, getMessage());
    }
}