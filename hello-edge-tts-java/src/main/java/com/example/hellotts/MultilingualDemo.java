package com.example.hellotts;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

/**
 * Multilingual demo for generating audio files in 12 languages.
 * This class processes a batch of languages with custom sentences.
 */
public class MultilingualDemo {
    
    private static final String CONFIG_PATH = "../shared/multilingual_demo_config.json";
    private static final String OUTPUT_DIR = "./";
    private static final boolean PLAY_AUDIO = false; // Set to true if you want to play each audio
    
    /**
     * Language configuration data structure
     */
    public static class LanguageConfig {
        public String code;
        public String name;
        public String flag;
        public String text;
        public String voice;
        public String altVoice;
        
        public LanguageConfig() {}
        
        public LanguageConfig(String code, String name, String flag, String text, String voice, String altVoice) {
            this.code = code;
            this.name = name;
            this.flag = flag;
            this.text = text;
            this.voice = voice;
            this.altVoice = altVoice;
        }
        
        @Override
        public String toString() {
            return String.format("%s %s (%s)", flag, name, code.toUpperCase());
        }
    }
    
    public static void main(String[] args) {
        System.out.println("🌍 Multilingual Edge TTS Demo - Java Implementation");
        System.out.println("=".repeat(60));
        System.out.println("Generating audio for 12 languages with custom sentences...");
        
        try {
            MultilingualDemo demo = new MultilingualDemo();
            demo.runDemo();
        } catch (Exception e) {
            System.err.println("❌ Demo failed: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    /**
     * Runs the complete multilingual demo
     */
    public void runDemo() throws Exception {
        // Load language configuration
        List<LanguageConfig> languages = loadLanguageConfig();
        if (languages.isEmpty()) {
            System.err.println("❌ Failed to load language configuration or no languages found");
            System.exit(1);
        }
        
        System.out.println("📋 Found " + languages.size() + " languages to process");
        
        // Create output directory (using current directory for Java implementation)
        File outputDir = new File(OUTPUT_DIR);
        String outputPath = outputDir.getAbsolutePath();
        System.out.println("📁 Output directory: " + outputPath);
        
        // Initialize TTS client
        TTSClient client;
        try {
            client = new TTSClient();
            System.out.println("✅ TTS client initialized");
        } catch (Exception e) {
            System.err.println("❌ Failed to initialize TTS client: " + e.getMessage());
            throw e;
        }
        
        // Initialize audio player if needed
        AudioPlayer player = null;
        if (PLAY_AUDIO) {
            player = new AudioPlayer();
        }
        
        // Process each language
        int successfulCount = 0;
        int failedCount = 0;
        long startTime = System.currentTimeMillis();
        
        for (int i = 0; i < languages.size(); i++) {
            LanguageConfig languageConfig = languages.get(i);
            System.out.println("\n📍 Processing language " + (i + 1) + "/" + languages.size());
            
            boolean success = generateAudioForLanguage(client, languageConfig, outputPath, player);
            
            if (success) {
                successfulCount++;
            } else {
                failedCount++;
            }
            
            // Small delay between languages to be polite to the service
            if (i < languages.size() - 1) {
                System.out.println("⏳ Waiting before next language...");
                Thread.sleep(2000);
            }
        }
        
        // Summary
        long endTime = System.currentTimeMillis();
        double duration = (endTime - startTime) / 1000.0;
        
        System.out.println("\n🏁 Processing Complete!");
        System.out.println("=".repeat(40));
        System.out.println("✅ Successful: " + successfulCount);
        System.out.println("❌ Failed: " + failedCount);
        System.out.printf("⏱️  Total time: %.2f seconds%n", duration);
        System.out.println("📁 Output files saved in: " + outputPath);
        
        if (successfulCount > 0) {
            System.out.println("\n🎉 Successfully generated audio files for " + successfulCount + " languages!");
            System.out.println("You can find all generated MP3 files in the output directory.");
        }
        
        if (failedCount > 0) {
            System.exit(1);
        }
    }
    
    /**
     * Load language configuration from JSON file
     */
    private List<LanguageConfig> loadLanguageConfig() {
        List<LanguageConfig> languages = new ArrayList<>();
        
        try {
            File configFile = new File(CONFIG_PATH);
            if (!configFile.exists()) {
                System.err.println("❌ Configuration file not found: " + CONFIG_PATH);
                return languages;
            }
            
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(configFile);
            JsonNode languagesNode = root.get("languages");
            
            if (languagesNode != null && languagesNode.isArray()) {
                for (JsonNode languageNode : languagesNode) {
                    LanguageConfig config = new LanguageConfig();
                    config.code = languageNode.get("code").asText();
                    config.name = languageNode.get("name").asText();
                    config.flag = languageNode.get("flag").asText();
                    config.text = languageNode.get("text").asText();
                    config.voice = languageNode.get("voice").asText();
                    JsonNode altVoiceNode = languageNode.get("alt_voice");
                    config.altVoice = altVoiceNode != null ? altVoiceNode.asText() : null;
                    
                    languages.add(config);
                }
            }
            
        } catch (IOException e) {
            System.err.println("❌ Error loading configuration: " + e.getMessage());
        }
        
        return languages;
    }
    
    /**
     * Generate audio for a single language
     */
    private boolean generateAudioForLanguage(TTSClient client, LanguageConfig languageConfig, 
                                           String outputDir, AudioPlayer player) {
        String langCode = languageConfig.code;
        String langName = languageConfig.name;
        String flag = languageConfig.flag;
        String text = languageConfig.text;
        String voice = languageConfig.voice;
        String altVoice = languageConfig.altVoice;
        
        System.out.println("\n" + flag + " " + langName + " (" + langCode.toUpperCase() + ")");
        System.out.println("Text: " + text);
        System.out.println("Voice: " + voice);
        
        try {
            // Try primary voice first
            byte[] audioData = null;
            String usedVoice = voice;
            
            try {
                CompletableFuture<byte[]> audioFuture = client.synthesizeText(text, voice);
                audioData = audioFuture.get();
            } catch (ExecutionException | InterruptedException e) {
                System.out.println("Primary voice failed: " + e.getMessage());
                if (altVoice != null && !altVoice.isEmpty()) {
                    System.out.println("Trying alternative voice: " + altVoice);
                    try {
                        CompletableFuture<byte[]> audioFuture = client.synthesizeText(text, altVoice);
                        audioData = audioFuture.get();
                        usedVoice = altVoice;
                    } catch (ExecutionException | InterruptedException e2) {
                        System.out.println("Alternative voice also failed: " + e2.getMessage());
                        throw e2;
                    }
                } else {
                    throw e;
                }
            }
            
            // Generate filename
            long timestamp = System.currentTimeMillis() / 1000;
            String langPrefix = langCode.split("-")[0]; // e.g., 'zh' from 'zh-cn'
            String filename = "multilingual_" + langPrefix + "_java_" + timestamp + ".mp3";
            String outputPath = new File(outputDir, filename).getPath();
            
            // Save audio
            CompletableFuture<Void> saveFuture = client.saveAudio(audioData, outputPath);
            saveFuture.get();
            
            System.out.println("✅ Generated: " + filename);
            System.out.println("📁 Saved to: " + outputPath);
            System.out.println("🎤 Used voice: " + usedVoice);
            
            // Play audio if requested (uncomment the lines below if needed)
            /*
            if (PLAY_AUDIO && player != null) {
                try {
                    System.out.println("🔊 Playing audio...");
                    player.playFile(outputPath);
                    System.out.println("✅ Playback completed");
                } catch (Exception e) {
                    System.out.println("⚠️  Could not play audio: " + e.getMessage());
                }
            }
            */
            
            return true;
            
        } catch (Exception e) {
            System.out.println("❌ Failed to generate audio for " + langName + ": " + e.getMessage());
            return false;
        }
    }
}