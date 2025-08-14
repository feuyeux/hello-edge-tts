package com.example.hellotts;

import javax.sound.sampled.*;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * AudioPlayer provides audio playback functionality using javax.sound.sampled.
 * Supports playing audio files and raw audio data with proper error handling
 * and format conversion capabilities.
 */
public class AudioPlayer {

    private static final int BUFFER_SIZE = 4096;
    private final ExecutorService executorService;
    private volatile boolean isPlaying = false;
    private Clip currentClip;

    /**
     * Creates a new AudioPlayer instance with a dedicated thread pool for audio
     * operations.
     */
    public AudioPlayer() {
        this.executorService = Executors.newSingleThreadExecutor(r -> {
            Thread t = new Thread(r, "AudioPlayer-Thread");
            t.setDaemon(true);
            return t;
        });
    }

    /**
     * Plays an audio file from the specified file path.
     * Supports WAV, AIFF, AU formats through Java's built-in audio system, and MP3
     * through system commands.
     *
     * @param filename The path to the audio file to play
     * @throws AudioPlayerException     If the file cannot be played due to format
     *                                  issues or I/O errors
     * @throws IllegalArgumentException If the filename is null or empty
     */
    public void playFile(String filename) throws AudioPlayerException {
        Objects.requireNonNull(filename, "Filename cannot be null");
        if (filename.trim().isEmpty()) {
            throw new IllegalArgumentException("Filename cannot be empty");
        }

        Path filePath = Paths.get(filename);
        if (!Files.exists(filePath)) {
            throw new AudioPlayerException("Audio file not found: " + filename);
        }

        if (!Files.isReadable(filePath)) {
            throw new AudioPlayerException("Audio file is not readable: " + filename);
        }

        try {
            // Check if file is MP3 format (edge-tts generates MP3 regardless of extension)
            if (isMP3File(filePath.toFile())) {
                playMP3WithSystemCommand(filename);
            } else {
                File audioFile = filePath.toFile();
                playAudioFile(audioFile);
            }
        } catch (Exception e) {
            throw new AudioPlayerException("Failed to play audio file: " + filename, e);
        }
    }

    /**
     * Check if file is MP3 format by reading file header
     */
    private boolean isMP3File(File file) {
        try {
            byte[] header = new byte[3];
            try (java.io.FileInputStream fis = new java.io.FileInputStream(file)) {
                fis.read(header);
            }
            // Check for MP3 header (ID3 tag or MPEG frame sync)
            return (header[0] == 'I' && header[1] == 'D' && header[2] == '3') ||
                    (header[0] == (byte) 0xFF && (header[1] & 0xE0) == 0xE0);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Play MP3 file using system command
     */
    private void playMP3WithSystemCommand(String filename) throws Exception {
        String os = System.getProperty("os.name").toLowerCase();

        // Convert to absolute path
        File file = new File(filename);
        String absolutePath = file.getAbsolutePath();

        if (os.contains("mac")) {
            // macOS
            ProcessBuilder pb = new ProcessBuilder("afplay", absolutePath);
            Process process = pb.start();
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                throw new Exception("Audio playback failed with exit code: " + exitCode);
            }
        } else if (os.contains("win")) {
            // Windows - use the most reliable method
            Exception lastException = null;

            // Method 1: PowerShell with Windows Media Player (most reliable for MP3)
            try {
                String powershellCmd = String.format(
                        "Add-Type -AssemblyName PresentationCore; " +
                                "$player = New-Object System.Windows.Media.MediaPlayer; " +
                                "$player.Open([System.Uri]\"%s\"); " +
                                "$player.Play(); " +
                                "Start-Sleep -Seconds 5; " +
                                "$player.Close();",
                        absolutePath.replace("\\", "\\\\"));

                ProcessBuilder pb = new ProcessBuilder("powershell", "-Command", powershellCmd);
                Process process = pb.start();
                int exitCode = process.waitFor();
                if (exitCode == 0) {
                    return; // Success
                }
                lastException = new Exception("PowerShell MediaPlayer failed with exit code: " + exitCode);
            } catch (Exception e) {
                lastException = e;
            }

            // Method 2: Use system default program
            try {
                ProcessBuilder pb = new ProcessBuilder("cmd", "/c", "start", "/wait", "\"\"",
                        "\"" + absolutePath + "\"");
                Process process = pb.start();
                int exitCode = process.waitFor();
                if (exitCode == 0) {
                    // Give some time for the audio to play
                    Thread.sleep(3000);
                    return;
                }
                lastException = new Exception("System default player failed with exit code: " + exitCode);
            } catch (Exception e) {
                lastException = e;
            }

            // Method 3: PowerShell Invoke-Item
            try {
                String powershellCmd = String.format("Invoke-Item \"%s\"; Start-Sleep -Seconds 3", absolutePath);
                ProcessBuilder pb = new ProcessBuilder("powershell", "-Command", powershellCmd);
                Process process = pb.start();
                int exitCode = process.waitFor();
                if (exitCode == 0) {
                    return;
                }
                lastException = new Exception("PowerShell Invoke-Item failed with exit code: " + exitCode);
            } catch (Exception e) {
                lastException = e;
            }

            if (lastException != null) {
                throw new Exception("All Windows playback methods failed", lastException);
            }
        } else {
            // Linux - try multiple players
            String[] players = { "mpg123", "mpv", "vlc", "paplay" };
            boolean played = false;

            for (String player : players) {
                try {
                    ProcessBuilder pb = new ProcessBuilder(player, absolutePath);
                    Process process = pb.start();
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        played = true;
                        break;
                    }
                } catch (Exception e) {
                    // Try next player
                }
            }

            if (!played) {
                throw new Exception("No suitable audio player found on Linux");
            }
        }
    }

    /**
     * Plays audio from raw byte data.
     * Attempts to detect the audio format and convert if necessary.
     *
     * @param audioData The raw audio data to play
     * @throws AudioPlayerException     If the audio data cannot be played
     * @throws IllegalArgumentException If the audioData is null or empty
     */
    public void playAudioData(byte[] audioData) throws AudioPlayerException {
        playAudioData(audioData, "mp3");
    }

    /**
     * Plays audio from raw byte data with format hint.
     * Attempts to detect the audio format and convert if necessary.
     *
     * @param audioData  The raw audio data to play
     * @param formatHint Audio format hint (e.g., "mp3", "wav")
     * @throws AudioPlayerException     If the audio data cannot be played
     * @throws IllegalArgumentException If the audioData is null or empty
     */
    public void playAudioData(byte[] audioData, String formatHint) throws AudioPlayerException {
        Objects.requireNonNull(audioData, "Audio data cannot be null");
        if (audioData.length == 0) {
            throw new IllegalArgumentException("Audio data cannot be empty");
        }

        try {
            // Create a temporary file to play the audio data
            File tempFile = createTempAudioFile(audioData, formatHint);
            try {
                playAudioFile(tempFile);
            } finally {
                // Clean up temporary file
                if (tempFile.exists()) {
                    tempFile.delete();
                }
            }
        } catch (Exception e) {
            throw new AudioPlayerException("Failed to play audio data", e);
        }
    }

    /**
     * Plays an audio file asynchronously and returns a CompletableFuture.
     *
     * @param filename The path to the audio file to play
     * @return A CompletableFuture that completes when playback finishes
     */
    public CompletableFuture<Void> playFileAsync(String filename) {
        return CompletableFuture.runAsync(() -> {
            try {
                playFile(filename);
            } catch (AudioPlayerException e) {
                throw new RuntimeException(e);
            }
        }, executorService);
    }

    /**
     * Plays audio data asynchronously and returns a CompletableFuture.
     *
     * @param audioData The raw audio data to play
     * @return A CompletableFuture that completes when playback finishes
     */
    public CompletableFuture<Void> playAudioDataAsync(byte[] audioData) {
        return CompletableFuture.runAsync(() -> {
            try {
                playAudioData(audioData);
            } catch (AudioPlayerException e) {
                throw new RuntimeException(e);
            }
        }, executorService);
    }

    /**
     * Stops the currently playing audio if any.
     */
    public void stop() {
        if (currentClip != null && currentClip.isRunning()) {
            currentClip.stop();
            currentClip.close();
            isPlaying = false;
        }
    }

    /**
     * Checks if audio is currently playing.
     *
     * @return true if audio is playing, false otherwise
     */
    public boolean isPlaying() {
        return isPlaying && currentClip != null && currentClip.isRunning();
    }

    /**
     * Closes the AudioPlayer and releases resources.
     * Should be called when the AudioPlayer is no longer needed.
     */
    public void close() {
        stop();
        executorService.shutdown();
    }

    /**
     * Internal method to play an audio file using javax.sound.sampled.
     *
     * @param audioFile The audio file to play
     * @throws AudioPlayerException If playback fails
     */
    private void playAudioFile(File audioFile) throws AudioPlayerException {
        AudioInputStream audioInputStream = null;

        try {
            // Stop any currently playing audio
            stop();

            // Get audio input stream
            audioInputStream = AudioSystem.getAudioInputStream(audioFile);
            AudioFormat originalFormat = audioInputStream.getFormat();

            // Convert to PCM if necessary
            AudioInputStream pcmStream = convertToPCM(audioInputStream, originalFormat);

            // Get a clip resource
            currentClip = AudioSystem.getClip();

            // Open the clip with the audio stream
            currentClip.open(pcmStream);

            // Add a line listener to track playback completion
            currentClip.addLineListener(event -> {
                if (event.getType() == LineEvent.Type.STOP) {
                    isPlaying = false;
                    currentClip.close();
                }
            });

            // Start playback
            isPlaying = true;
            currentClip.start();

            // Wait for playback to complete
            while (currentClip.isRunning()) {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }

        } catch (UnsupportedAudioFileException e) {
            throw new AudioPlayerException("Unsupported audio format: " + audioFile.getName(), e);
        } catch (IOException e) {
            throw new AudioPlayerException("I/O error while reading audio file: " + audioFile.getName(), e);
        } catch (LineUnavailableException e) {
            throw new AudioPlayerException("Audio line unavailable - check if audio device is available", e);
        } catch (Exception e) {
            throw new AudioPlayerException("Unexpected error during audio playback", e);
        } finally {
            if (audioInputStream != null) {
                try {
                    audioInputStream.close();
                } catch (IOException e) {
                    // Log but don't throw - cleanup operation
                    System.err.println("Warning: Failed to close audio input stream: " + e.getMessage());
                }
            }
        }
    }

    /**
     * Converts audio format to PCM if necessary for playback compatibility.
     *
     * @param audioInputStream The original audio input stream
     * @param originalFormat   The original audio format
     * @return An audio input stream in PCM format
     * @throws AudioPlayerException If format conversion fails
     */
    private AudioInputStream convertToPCM(AudioInputStream audioInputStream, AudioFormat originalFormat)
            throws AudioPlayerException {

        // If already PCM, return as-is
        if (originalFormat.getEncoding().equals(AudioFormat.Encoding.PCM_SIGNED) ||
                originalFormat.getEncoding().equals(AudioFormat.Encoding.PCM_UNSIGNED)) {
            return audioInputStream;
        }

        try {
            // Define target PCM format
            AudioFormat pcmFormat = new AudioFormat(
                    AudioFormat.Encoding.PCM_SIGNED,
                    originalFormat.getSampleRate(),
                    16, // 16-bit
                    originalFormat.getChannels(),
                    originalFormat.getChannels() * 2, // frame size
                    originalFormat.getSampleRate(),
                    false // little endian
            );

            // Check if conversion is supported
            if (!AudioSystem.isConversionSupported(pcmFormat, originalFormat)) {
                // Try with a more flexible format
                pcmFormat = new AudioFormat(
                        AudioFormat.Encoding.PCM_SIGNED,
                        originalFormat.getSampleRate(),
                        16,
                        originalFormat.getChannels(),
                        originalFormat.getChannels() * 2,
                        originalFormat.getSampleRate(),
                        true // big endian
                );

                if (!AudioSystem.isConversionSupported(pcmFormat, originalFormat)) {
                    throw new AudioPlayerException("Audio format conversion not supported: " + originalFormat);
                }
            }

            return AudioSystem.getAudioInputStream(pcmFormat, audioInputStream);

        } catch (Exception e) {
            throw new AudioPlayerException("Failed to convert audio format to PCM", e);
        }
    }

    /**
     * Creates a temporary file from audio data for playback.
     *
     * @param audioData  The audio data to write to a temporary file
     * @param formatHint Audio format hint for file extension
     * @return A temporary file containing the audio data
     * @throws IOException If file creation fails
     */
    private File createTempAudioFile(byte[] audioData, String formatHint) throws IOException {
        // Use format hint if provided, otherwise detect from data
        String extension = (formatHint != null && !formatHint.trim().isEmpty())
                ? formatHint.trim().toLowerCase()
                : detectAudioFormat(audioData);

        File tempFile = File.createTempFile("hellotts_audio_", "." + extension);
        tempFile.deleteOnExit();

        try (FileOutputStream fos = new FileOutputStream(tempFile)) {
            fos.write(audioData);
            fos.flush();
        }

        return tempFile;
    }

    /**
     * Attempts to detect audio format from byte data header.
     *
     * @param audioData The audio data to analyze
     * @return The detected file extension (default: "wav")
     */
    private String detectAudioFormat(byte[] audioData) {
        if (audioData.length < 4) {
            return "wav"; // Default fallback
        }

        // Check for common audio format signatures
        if (audioData[0] == 'R' && audioData[1] == 'I' && audioData[2] == 'F' && audioData[3] == 'F') {
            return "wav";
        } else if (audioData.length >= 3 &&
                (audioData[0] & 0xFF) == 0xFF &&
                (audioData[1] & 0xE0) == 0xE0) {
            return "mp3";
        } else if (audioData.length >= 4 &&
                audioData[0] == 'O' && audioData[1] == 'g' &&
                audioData[2] == 'g' && audioData[3] == 'S') {
            return "ogg";
        }

        return "wav"; // Default fallback
    }

    /**
     * Custom exception class for AudioPlayer-specific errors.
     */
    public static class AudioPlayerException extends Exception {

        public AudioPlayerException(String message) {
            super(message);
        }

        public AudioPlayerException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}