package com.example.hellotts;

import java.io.File;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Semaphore;
import java.util.List;
import java.util.ArrayList;

/**
 * TTS client implementation with SSML support
 * This will be fully implemented in task 5.2
 */
public class TTSClient {
    
    public TTSClient() {
        // Placeholder constructor
    }
    
    /**
     * Convert text to audio data using specified voice
     */
    public CompletableFuture<byte[]> synthesizeText(String text, String voice) {
        return synthesizeText(text, voice, false);
    }
    
    /**
     * Convert text to audio data using specified voice with SSML option
     */
    public CompletableFuture<byte[]> synthesizeText(String text, String voice, boolean useSSML) {
        return synthesizeTextWithOptions(text, voice, useSSML);
    }
    
    /**
     * Convert text to audio data using specified voice with SSML option
     */
    public CompletableFuture<byte[]> synthesizeTextWithOptions(String text, String voice, boolean useSSML) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Validate SSML if specified
                if (useSSML) {
                    validateSSML(text);
                }
                
                // Create SSML for the request
                String ssml = useSSML ? text : createSSML(text, voice);
                System.out.println("SSML prepared for synthesis: " + ssml.length() + " characters");
                
                // Use edge-tts via process execution (similar to Dart and Rust implementations)
                return synthesizeViaEdgeTTS(text, voice);
                
            } catch (Exception e) {
                throw new RuntimeException("TTS synthesis failed: " + e.getMessage(), e);
            }
        });
    }

    /**
     * Use Python edge-tts library via process execution
     */
    private byte[] synthesizeViaEdgeTTS(String text, String voice) throws Exception {
        // Create temporary file for output (use MP3 format)
        File tempFile = File.createTempFile("tts_output_", ".mp3");
        tempFile.deleteOnExit();
        
        try {
            // Try edge-tts command first
            ProcessBuilder pb = new ProcessBuilder(
                "edge-tts",
                "--voice", voice,
                "--text", text,
                "--write-media", tempFile.getAbsolutePath()
            );
            
            Process process = pb.start();
            int exitCode = process.waitFor();
            
            // If direct edge-tts command fails, try python -m edge_tts
            if (exitCode != 0) {
                ProcessBuilder pythonPb = new ProcessBuilder(
                    "python", "-m", "edge_tts",
                    "--voice", voice,
                    "--text", text,
                    "--write-media", tempFile.getAbsolutePath()
                );
                
                Process pythonProcess = pythonPb.start();
                int pythonExitCode = pythonProcess.waitFor();
                
                if (pythonExitCode != 0) {
                    throw new RuntimeException("Edge TTS failed with exit code: " + pythonExitCode);
                }
            }
            
            // Read the generated audio file
            if (tempFile.exists() && tempFile.length() > 0) {
                return java.nio.file.Files.readAllBytes(tempFile.toPath());
            } else {
                throw new RuntimeException("Audio file was not generated or is empty");
            }
            
        } finally {
            // Clean up temporary file
            if (tempFile.exists()) {
                tempFile.delete();
            }
        }
    }
    
    /**
     * Convert SSML to audio data using specified voice
     */
    public CompletableFuture<byte[]> synthesizeSSML(String ssml, String voice) {
        return synthesizeTextWithOptions(ssml, voice, true);
    }
    
    /**
     * Save audio data to file
     */
    public CompletableFuture<Void> saveAudio(byte[] audioData, String filename) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Ensure output directory exists
                File file = new File(filename);
                File parentDir = file.getParentFile();
                if (parentDir != null && !parentDir.exists()) {
                    parentDir.mkdirs();
                }
                
                // Write audio data to file
                java.nio.file.Files.write(file.toPath(), audioData);
                return null;
            } catch (Exception e) {
                throw new RuntimeException("Failed to save audio file: " + e.getMessage(), e);
            }
        });
    }
    
    /**
     * Get all available voices
     */
    public CompletableFuture<List<Voice>> listVoices() {
        // Placeholder implementation
        return CompletableFuture.completedFuture(List.of());
    }
    
    /**
     * Create SSML markup with prosody controls
     */
    public String createSSML(String text, String voice, String rate, String pitch, String volume) {
        return SSMLUtils.createSSML(text, voice, rate, pitch, volume);
    }
    
    /**
     * Create basic SSML markup
     */
    public String createSSML(String text, String voice) {
        return new SSMLUtils.SSMLBuilder(voice).addText(text).build();
    }
    
    /**
     * Create SSML with emphasis markup
     */
    public String createEmphasisSSML(String text, String voice, String emphasisLevel) {
        return SSMLUtils.createEmphasisSSML(text, voice, emphasisLevel);
    }
    
    /**
     * Create SSML with breaks between text parts
     */
    public String createBreakSSML(String[] textParts, String voice, String breakTime) {
        return SSMLUtils.createBreakSSML(textParts, voice, breakTime);
    }
    
    /**
     * Get an SSML builder instance for the specified voice
     */
    public SSMLUtils.SSMLBuilder getSSMLBuilder(String voice) {
        return new SSMLUtils.SSMLBuilder(voice);
    }
    
    /**
     * Validate SSML markup
     */
    private void validateSSML(String ssml) {
        List<String> errors = SSMLUtils.validateSSML(ssml, false);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("SSML validation failed: " + String.join("; ", errors));
        }
    }
    
    /**
     * Convert multiple texts to audio data using specified voice
     */
    public CompletableFuture<List<byte[]>> batchSynthesizeText(String[] texts, String voice, boolean useSSML) {
        return CompletableFuture.supplyAsync(() -> {
            List<byte[]> results = new ArrayList<>();
            
            for (int i = 0; i < texts.length; i++) {
                try {
                    System.out.println("Processing batch item " + (i + 1) + "/" + texts.length + ": " + 
                                     texts[i].substring(0, Math.min(50, texts[i].length())) + "...");
                    
                    CompletableFuture<byte[]> audioFuture = synthesizeTextWithOptions(texts[i], voice, useSSML);
                    byte[] audioData = audioFuture.get();
                    results.add(audioData);
                } catch (Exception e) {
                    throw new RuntimeException("Failed to synthesize batch item " + (i + 1) + ": " + e.getMessage(), e);
                }
            }
            
            return results;
        });
    }
    
    /**
     * Convert multiple texts to audio data concurrently using specified voice
     */
    public CompletableFuture<List<byte[]>> batchSynthesizeConcurrent(String[] texts, String voice, boolean useSSML, int maxConcurrent) {
        return CompletableFuture.supplyAsync(() -> {
            List<CompletableFuture<IndexedResult>> futures = new ArrayList<>();
            Semaphore semaphore = new Semaphore(maxConcurrent);
            
            for (int i = 0; i < texts.length; i++) {
                final int index = i;
                final String text = texts[i];
                
                CompletableFuture<IndexedResult> future = CompletableFuture.supplyAsync(() -> {
                    try {
                        semaphore.acquire();
                        System.out.println("Processing concurrent item " + (index + 1) + "/" + texts.length + ": " + 
                                         text.substring(0, Math.min(50, text.length())) + "...");
                        
                        CompletableFuture<byte[]> audioFuture = synthesizeTextWithOptions(text, voice, useSSML);
                        byte[] audioData = audioFuture.get();
                        return new IndexedResult(index, audioData);
                    } catch (Exception e) {
                        throw new RuntimeException("Failed to synthesize concurrent item " + (index + 1) + ": " + e.getMessage(), e);
                    } finally {
                        semaphore.release();
                    }
                });
                
                futures.add(future);
            }
            
            // Wait for all futures to complete
            try {
                List<IndexedResult> indexedResults = new ArrayList<>();
                for (CompletableFuture<IndexedResult> future : futures) {
                    indexedResults.add(future.get());
                }
                
                // Sort by index to maintain order
                indexedResults.sort((a, b) -> Integer.compare(a.index, b.index));
                
                // Extract audio data
                List<byte[]> results = new ArrayList<>();
                for (IndexedResult result : indexedResults) {
                    results.add(result.audioData);
                }
                
                return results;
            } catch (Exception e) {
                throw new RuntimeException("Error in concurrent batch processing: " + e.getMessage(), e);
            }
        });
    }
    
    /**
     * Save multiple audio data to files
     */
    public CompletableFuture<List<String>> batchSaveAudio(List<byte[]> audioDataList, String filenameTemplate) {
        return CompletableFuture.supplyAsync(() -> {
            List<String> savedFiles = new ArrayList<>();
            
            for (int i = 0; i < audioDataList.size(); i++) {
                try {
                    String filename = filenameTemplate.replace("{}", String.valueOf(i + 1));
                    saveAudio(audioDataList.get(i), filename).get();
                    savedFiles.add(filename);
                    System.out.println("Saved batch item " + (i + 1) + ": " + filename);
                } catch (Exception e) {
                    throw new RuntimeException("Failed to save batch item " + (i + 1) + ": " + e.getMessage(), e);
                }
            }
            
            return savedFiles;
        });
    }
    
    /**
     * Helper class for maintaining order in concurrent processing
     */
    private static class IndexedResult {
        final int index;
        final byte[] audioData;
        
        IndexedResult(int index, byte[] audioData) {
            this.index = index;
            this.audioData = audioData;
        }
    }
}