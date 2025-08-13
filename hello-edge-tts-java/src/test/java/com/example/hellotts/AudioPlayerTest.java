package com.example.hellotts;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for AudioPlayer class.
 * Tests basic functionality, error handling, and edge cases.
 */
class AudioPlayerTest {

    private AudioPlayer audioPlayer;
    
    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
        audioPlayer = new AudioPlayer();
    }

    @AfterEach
    void tearDown() {
        if (audioPlayer != null) {
            audioPlayer.close();
        }
    }

    @Test
    void testPlayFileWithNullFilename() {
        assertThrows(NullPointerException.class, () -> {
            audioPlayer.playFile(null);
        });
    }

    @Test
    void testPlayFileWithEmptyFilename() {
        assertThrows(IllegalArgumentException.class, () -> {
            audioPlayer.playFile("");
        });
        
        assertThrows(IllegalArgumentException.class, () -> {
            audioPlayer.playFile("   ");
        });
    }

    @Test
    void testPlayFileWithNonExistentFile() {
        AudioPlayer.AudioPlayerException exception = assertThrows(
            AudioPlayer.AudioPlayerException.class, 
            () -> audioPlayer.playFile("nonexistent_file.wav")
        );
        
        assertTrue(exception.getMessage().contains("not found"));
    }

    @Test
    void testPlayAudioDataWithNullData() {
        assertThrows(NullPointerException.class, () -> {
            audioPlayer.playAudioData(null);
        });
    }

    @Test
    void testPlayAudioDataWithEmptyData() {
        assertThrows(IllegalArgumentException.class, () -> {
            audioPlayer.playAudioData(new byte[0]);
        });
    }

    @Test
    void testPlayAudioDataWithInvalidData() {
        // Test with random bytes that don't represent valid audio
        byte[] invalidAudioData = {1, 2, 3, 4, 5};
        
        AudioPlayer.AudioPlayerException exception = assertThrows(
            AudioPlayer.AudioPlayerException.class,
            () -> audioPlayer.playAudioData(invalidAudioData)
        );
        
        assertNotNull(exception.getMessage());
    }

    @Test
    void testCreateAndPlayTempFile() throws IOException {
        // Create a simple WAV file header (minimal valid WAV)
        byte[] wavHeader = createMinimalWavHeader();
        
        File tempFile = tempDir.resolve("test.wav").toFile();
        try (FileOutputStream fos = new FileOutputStream(tempFile)) {
            fos.write(wavHeader);
        }
        
        // This should not throw an exception, even if no audio is actually played
        // (due to the minimal/empty audio content)
        assertDoesNotThrow(() -> {
            try {
                audioPlayer.playFile(tempFile.getAbsolutePath());
            } catch (AudioPlayer.AudioPlayerException e) {
                // Expected for minimal WAV - just ensure it's a format-related error
                assertTrue(e.getMessage().contains("Unsupported") || 
                          e.getMessage().contains("format") ||
                          e.getMessage().contains("Audio"));
            }
        });
    }

    @Test
    void testStopAndIsPlaying() {
        // Initially not playing
        assertFalse(audioPlayer.isPlaying());
        
        // Stop should not throw even when nothing is playing
        assertDoesNotThrow(() -> audioPlayer.stop());
        
        // Still not playing after stop
        assertFalse(audioPlayer.isPlaying());
    }

    @Test
    void testClose() {
        // Close should not throw
        assertDoesNotThrow(() -> audioPlayer.close());
        
        // Should be able to call close multiple times
        assertDoesNotThrow(() -> audioPlayer.close());
    }

    @Test
    void testAsyncPlayFile() {
        // Test that async methods return CompletableFuture
        assertDoesNotThrow(() -> {
            var future = audioPlayer.playFileAsync("nonexistent.wav");
            assertNotNull(future);
            
            // The future should complete exceptionally due to file not found
            assertThrows(Exception.class, () -> future.join());
        });
    }

    @Test
    void testAsyncPlayAudioData() {
        // Test that async methods return CompletableFuture
        assertDoesNotThrow(() -> {
            var future = audioPlayer.playAudioDataAsync(new byte[]{1, 2, 3});
            assertNotNull(future);
            
            // The future should complete exceptionally due to invalid audio data
            assertThrows(Exception.class, () -> future.join());
        });
    }

    /**
     * Creates a minimal WAV file header for testing purposes.
     * This creates a valid but empty WAV file structure.
     */
    private byte[] createMinimalWavHeader() {
        // Minimal WAV header (44 bytes)
        byte[] header = new byte[44];
        
        // RIFF header
        header[0] = 'R'; header[1] = 'I'; header[2] = 'F'; header[3] = 'F';
        
        // File size (36 + data size, little endian) - minimal size
        header[4] = 36; header[5] = 0; header[6] = 0; header[7] = 0;
        
        // WAVE header
        header[8] = 'W'; header[9] = 'A'; header[10] = 'V'; header[11] = 'E';
        
        // fmt subchunk
        header[12] = 'f'; header[13] = 'm'; header[14] = 't'; header[15] = ' ';
        
        // Subchunk1Size (16 for PCM)
        header[16] = 16; header[17] = 0; header[18] = 0; header[19] = 0;
        
        // AudioFormat (1 for PCM)
        header[20] = 1; header[21] = 0;
        
        // NumChannels (1 = mono)
        header[22] = 1; header[23] = 0;
        
        // SampleRate (44100 Hz)
        header[24] = 0x44; header[25] = (byte)0xAC; header[26] = 0; header[27] = 0;
        
        // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
        header[28] = (byte)0x88; header[29] = 0x58; header[30] = 0x01; header[31] = 0;
        
        // BlockAlign (NumChannels * BitsPerSample/8)
        header[32] = 2; header[33] = 0;
        
        // BitsPerSample (16)
        header[34] = 16; header[35] = 0;
        
        // data subchunk
        header[36] = 'd'; header[37] = 'a'; header[38] = 't'; header[39] = 'a';
        
        // Subchunk2Size (0 for empty audio)
        header[40] = 0; header[41] = 0; header[42] = 0; header[43] = 0;
        
        return header;
    }
}