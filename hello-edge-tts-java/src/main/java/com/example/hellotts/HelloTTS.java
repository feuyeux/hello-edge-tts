package com.example.hellotts;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.commons.cli.*;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

/**
 * Main class demonstrating Edge TTS functionality in Java
 * Provides command-line interface for text-to-speech conversion with voice selection and multi-language support
 */
public class HelloTTS {
    
    private static final String DEFAULT_VOICE = "en-US-AriaNeural";
    private static final String DEFAULT_OUTPUT_DIR = "./";
    private static final String VOICE_CONFIG_PATH = "../shared/voice_configs.json";
    private static final String SAMPLE_TEXTS_PATH = "../shared/sample_texts.json";
    
    public static void main(String[] args) {
        Options options = createCommandLineOptions();
        CommandLineParser parser = new DefaultParser();
        
        try {
            CommandLine cmd = parser.parse(options, args);
            
            if (cmd.hasOption("help")) {
                printHelp(options);
                return;
            }
            
            if (cmd.hasOption("list-voices")) {
                listAvailableVoices();
                return;
            }
            
            if (cmd.hasOption("demo")) {
                runMultiLanguageDemo();
                return;
            }
            
            // Main TTS functionality
            runTTSConversion(cmd);
            
        } catch (ParseException e) {
            System.err.println("Error parsing command line arguments: " + e.getMessage());
            printHelp(options);
            System.exit(1);
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    /**
     * Creates command line options for the application
     */
    private static Options createCommandLineOptions() {
        Options options = new Options();
        
        options.addOption(Option.builder("t")
                .longOpt("text")
                .hasArg()
                .desc("Text to convert to speech (default: 'Hello, World!')")
                .build());
        
        options.addOption(Option.builder("v")
                .longOpt("voice")
                .hasArg()
                .desc("Voice to use (default: " + DEFAULT_VOICE + ")")
                .build());
        
        options.addOption(Option.builder("o")
                .longOpt("output")
                .hasArg()
                .desc("Output filename (default: auto-generated)")
                .build());
        
        options.addOption(Option.builder("l")
                .longOpt("language")
                .hasArg()
                .desc("Filter voices by language code (e.g., 'en', 'es', 'fr')")
                .build());
        
        options.addOption(Option.builder()
                .longOpt("list-voices")
                .desc("List all available voices")
                .build());
        
        options.addOption(Option.builder()
                .longOpt("demo")
                .desc("Run multi-language demonstration")
                .build());
        
        options.addOption(Option.builder()
                .longOpt("no-play")
                .desc("Don't play audio after generation")
                .build());
        
        options.addOption(Option.builder("h")
                .longOpt("help")
                .desc("Show this help message")
                .build());
        
        return options;
    }
    
    /**
     * Prints help information for command line usage
     */
    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("java -jar hello-edge-tts.jar [OPTIONS]", 
                "\nJava implementation of Edge TTS demonstration\n\n", 
                options, 
                "\nExamples:\n" +
                "  java -jar hello-edge-tts.jar\n" +
                "  java -jar hello-edge-tts.jar --text \"Hello from Java!\" --voice en-US-DavisNeural\n" +
                "  java -jar hello-edge-tts.jar --list-voices\n" +
                "  java -jar hello-edge-tts.jar --demo\n" +
                "  java -jar hello-edge-tts.jar --language es --text \"Hola mundo\"\n");
    }
    
    /**
     * Lists all available voices from the configuration file
     */
    private static void listAvailableVoices() {
        System.out.println("=== Available Voices ===\n");
        
        try {
            List<Voice> voices = loadVoicesFromConfig();
            
            if (voices.isEmpty()) {
                System.out.println("No voices found in configuration file.");
                return;
            }
            
            // Group voices by language
            voices.stream()
                    .collect(Collectors.groupingBy(Voice::getLanguageCode))
                    .forEach((language, voiceList) -> {
                        System.out.println("Language: " + language.toUpperCase());
                        System.out.println("─".repeat(40));
                        voiceList.forEach(voice -> {
                            System.out.printf("  %-25s %-15s %-10s %s%n",
                                    voice.getName(),
                                    voice.getDisplayName(),
                                    voice.getGender(),
                                    voice.getDescription() != null ? voice.getDescription() : "");
                        });
                        System.out.println();
                    });
                    
        } catch (Exception e) {
            System.err.println("Error loading voices: " + e.getMessage());
            
            // Fallback to hardcoded popular voices
            System.out.println("Using fallback voice list:");
            System.out.println("  en-US-AriaNeural     Aria            Female     Friendly and conversational");
            System.out.println("  en-US-DavisNeural    Davis           Male       Professional and clear");
            System.out.println("  en-US-JennyNeural    Jenny           Female     Warm and expressive");
            System.out.println("  es-ES-ElviraNeural   Elvira          Female     Spanish from Spain");
            System.out.println("  fr-FR-DeniseNeural   Denise          Female     French from France");
            System.out.println("  de-DE-KatjaNeural    Katja           Female     German from Germany");
        }
    }
    
    /**
     * Runs a multi-language demonstration
     */
    private static void runMultiLanguageDemo() {
        System.out.println("=== Multi-Language TTS Demo ===\n");
        
        try {
            JsonNode sampleTexts = loadSampleTexts();
            JsonNode multilingualTexts = sampleTexts.get("multilingual");
            
            if (multilingualTexts == null) {
                System.err.println("No multilingual samples found in configuration.");
                return;
            }
            
            TTSClient client = new TTSClient();
            AudioPlayer player = new AudioPlayer();
            
            // Demo languages in order
            String[] languages = {"english", "spanish", "french", "german"};
            
            for (String language : languages) {
                JsonNode langConfig = multilingualTexts.get(language);
                if (langConfig != null) {
                    String text = langConfig.get("text").asText();
                    String voice = langConfig.get("voice").asText();
                    
                    System.out.println("Language: " + language.substring(0, 1).toUpperCase() + language.substring(1));
                    System.out.println("Voice: " + voice);
                    System.out.println("Text: " + text);
                    System.out.println("Converting...");
                    
                    try {
                        // Generate audio
                        CompletableFuture<byte[]> audioFuture = client.synthesizeText(text, voice);
                        byte[] audioData = audioFuture.get();
                        
                        // Save to file
                        String filename = "demo_" + language + ".mp3";
                        CompletableFuture<Void> saveFuture = client.saveAudio(audioData, filename);
                        saveFuture.get();
                        
                        System.out.println("✓ Generated: " + filename);
                        
                        // Play audio
                        player.playFile(filename);
                        System.out.println("✓ Playback completed");
                        
                        // Small delay between languages
                        Thread.sleep(1000);
                        
                    } catch (Exception e) {
                        System.err.println("✗ Error processing " + language + ": " + e.getMessage());
                    }
                    
                    System.out.println();
                }
            }
            
            System.out.println("Multi-language demo completed!");
            
        } catch (Exception e) {
            System.err.println("Error running demo: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Runs the main TTS conversion based on command line arguments
     */
    private static void runTTSConversion(CommandLine cmd) throws Exception {
        System.out.println("=== Hello Edge TTS - Java Implementation ===\n");
        
        // Get parameters from command line or use defaults
        String text = cmd.getOptionValue("text", "Hello, World! This is a demonstration of Edge TTS in Java.");
        String voice = cmd.getOptionValue("voice", DEFAULT_VOICE);
        String outputFile = cmd.getOptionValue("output");
        String languageFilter = cmd.getOptionValue("language");
        boolean shouldPlay = !cmd.hasOption("no-play");
        
        // If language filter is specified, find a suitable voice
        if (languageFilter != null) {
            voice = findVoiceByLanguage(languageFilter, voice);
        }
        
        // Generate output filename if not specified
        if (outputFile == null) {
            outputFile = generateOutputFilename(voice);
        }
        
        System.out.println("Text: " + text);
        System.out.println("Voice: " + voice);
        System.out.println("Output: " + outputFile);
        System.out.println();
        
        // Create TTS client and process
        TTSClient client = new TTSClient();
        
        try {
            System.out.println("Converting text to speech...");
            
            // Synthesize text to audio
            CompletableFuture<byte[]> audioFuture = client.synthesizeText(text, voice);
            byte[] audioData = audioFuture.get();
            
            System.out.println("✓ Audio generated successfully! Size: " + audioData.length + " bytes");
            
            // Save audio to file
            CompletableFuture<Void> saveFuture = client.saveAudio(audioData, outputFile);
            saveFuture.get();
            
            System.out.println("✓ Audio saved to: " + outputFile);
            
            // Play the audio if requested
            if (shouldPlay) {
                System.out.println("Playing audio...");
                AudioPlayer player = new AudioPlayer();
                player.playFile(outputFile);
                System.out.println("✓ Playback completed!");
            }
            
        } catch (ExecutionException | InterruptedException e) {
            System.err.println("✗ TTS Error: " + e.getMessage());
            throw e;
        }
    }
    
    /**
     * Finds a voice by language code, falling back to default if not found
     */
    private static String findVoiceByLanguage(String languageCode, String fallbackVoice) {
        try {
            List<Voice> voices = loadVoicesFromConfig();
            
            List<Voice> matchingVoices = Voice.getVoicesByLanguage(voices, languageCode)
                    .collect(Collectors.toList());
            
            if (!matchingVoices.isEmpty()) {
                Voice selectedVoice = matchingVoices.get(0); // Use first matching voice
                System.out.println("Found voice for language '" + languageCode + "': " + selectedVoice.getName());
                return selectedVoice.getName();
            } else {
                System.out.println("No voices found for language '" + languageCode + "', using: " + fallbackVoice);
                return fallbackVoice;
            }
            
        } catch (Exception e) {
            System.err.println("Error finding voice by language: " + e.getMessage());
            return fallbackVoice;
        }
    }
    
    /**
     * Generates an output filename based on the voice name
     */
    private static String generateOutputFilename(String voice) {
        // Extract language from voice (e.g., 'en' from 'en-US-AriaNeural')
        String lang = voice.split("-")[0];
        long timestamp = System.currentTimeMillis() / 1000;
        return "edge_tts_" + lang + "_" + timestamp + ".mp3";
    }
    
    /**
     * Loads voices from the shared configuration file
     */
    private static List<Voice> loadVoicesFromConfig() throws Exception {
        File configFile = new File(VOICE_CONFIG_PATH);
        if (!configFile.exists()) {
            throw new IOException("Voice configuration file not found: " + VOICE_CONFIG_PATH);
        }
        
        return Voice.parseVoicesFromJsonFile(VOICE_CONFIG_PATH);
    }
    
    /**
     * Loads sample texts from the shared configuration file
     */
    private static JsonNode loadSampleTexts() throws Exception {
        File configFile = new File(SAMPLE_TEXTS_PATH);
        if (!configFile.exists()) {
            throw new IOException("Sample texts file not found: " + SAMPLE_TEXTS_PATH);
        }
        
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readTree(configFile);
    }
}