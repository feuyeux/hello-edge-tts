package com.example.hellotts;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

/**
 * Configuration manager with preset support
 */
public class ConfigManager {
    private static final String[] DEFAULT_CONFIG_PATHS = {
        "./tts_config.json",
        System.getProperty("user.home") + "/.tts/config.json"
    };

    private static final Map<String, TTSConfig> PRESETS = new HashMap<>();

    static {
        // Initialize presets
        PRESETS.put("default", new TTSConfig());
        
        PRESETS.put("fast", new TTSConfig.Builder()
            .rate("+20%")
            .maxConcurrent(5)
            .batchSize(10)
            .build());
        
        PRESETS.put("slow", new TTSConfig.Builder()
            .rate("-20%")
            .maxConcurrent(2)
            .batchSize(3)
            .build());
        
        PRESETS.put("high_quality", new TTSConfig.Builder()
            .outputFormat("wav")
            .cacheVoices(true)
            .maxRetries(5)
            .build());
        
        PRESETS.put("batch_processing", new TTSConfig.Builder()
            .maxConcurrent(8)
            .batchSize(20)
            .cacheVoices(true)
            .build());
        
        PRESETS.put("whisper", new TTSConfig.Builder()
            .rate("-10%")
            .volume("50%")
            .pitch("-5%")
            .build());
        
        PRESETS.put("excited", new TTSConfig.Builder()
            .rate("+15%")
            .pitch("+10%")
            .volume("110%")
            .build());
    }

    /**
     * Load configuration from file or use default
     */
    public static TTSConfig loadConfig(String configPath) throws IOException {
        if (configPath != null) {
            return loadFromFile(configPath);
        }

        // Try default paths
        for (String path : DEFAULT_CONFIG_PATHS) {
            if (Files.exists(Paths.get(path))) {
                return loadFromFile(path);
            }
        }

        // Return default config if no file found
        return new TTSConfig();
    }

    /**
     * Load configuration from specific file
     */
    public static TTSConfig loadFromFile(String filePath) throws IOException {
        Path path = Paths.get(filePath);
        if (!Files.exists(path)) {
            throw new FileNotFoundException("Configuration file not found: " + filePath);
        }

        String content = Files.readString(path);
        
        // Simple JSON parsing (in a real implementation, you'd use a JSON library)
        Map<String, Object> configMap = parseSimpleJson(content);
        return TTSConfig.fromMap(configMap);
    }

    /**
     * Save configuration to file
     */
    public static void saveConfig(TTSConfig config, String filePath) throws IOException {
        Path path = Paths.get(filePath);
        Files.createDirectories(path.getParent());

        String json = mapToJson(config.toMap());
        Files.writeString(path, json);
    }

    /**
     * Get a preset configuration
     */
    public static TTSConfig getPreset(String presetName) {
        if (!PRESETS.containsKey(presetName)) {
            String available = String.join(", ", PRESETS.keySet());
            throw new IllegalArgumentException("Unknown preset '" + presetName + "'. Available: " + available);
        }
        return PRESETS.get(presetName);
    }

    /**
     * List available preset names
     */
    public static Set<String> listPresets() {
        return PRESETS.keySet();
    }

    /**
     * Create a default configuration file
     */
    public static void createDefaultConfig(String filePath, String preset) throws IOException {
        TTSConfig config = getPreset(preset);
        saveConfig(config, filePath);
        System.out.println("Created default configuration file: " + filePath);
    }

    /**
     * Simple JSON parser (for demonstration - use a proper JSON library in production)
     */
    private static Map<String, Object> parseSimpleJson(String json) {
        Map<String, Object> result = new HashMap<>();
        
        // Remove braces and split by comma
        json = json.trim().replaceAll("^\\{|\\}$", "");
        String[] pairs = json.split(",");
        
        for (String pair : pairs) {
            String[] keyValue = pair.split(":", 2);
            if (keyValue.length == 2) {
                String key = keyValue[0].trim().replaceAll("\"", "");
                String value = keyValue[1].trim();
                
                // Parse different types
                Object parsedValue;
                if (value.equals("true")) {
                    parsedValue = true;
                } else if (value.equals("false")) {
                    parsedValue = false;
                } else if (value.startsWith("\"") && value.endsWith("\"")) {
                    parsedValue = value.substring(1, value.length() - 1);
                } else {
                    try {
                        parsedValue = Integer.parseInt(value);
                    } catch (NumberFormatException e) {
                        parsedValue = value;
                    }
                }
                
                result.put(key, parsedValue);
            }
        }
        
        return result;
    }

    /**
     * Simple JSON serializer (for demonstration - use a proper JSON library in production)
     */
    private static String mapToJson(Map<String, Object> map) {
        StringBuilder json = new StringBuilder("{\n");
        
        boolean first = true;
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            if (!first) {
                json.append(",\n");
            }
            first = false;
            
            json.append("  \"").append(entry.getKey()).append("\": ");
            
            Object value = entry.getValue();
            if (value instanceof String) {
                json.append("\"").append(value).append("\"");
            } else {
                json.append(value);
            }
        }
        
        json.append("\n}");
        return json.toString();
    }
}

// Convenience functions
class ConfigUtils {
    public static TTSConfig loadConfig(String configPath) throws IOException {
        return ConfigManager.loadConfig(configPath);
    }

    public static TTSConfig getPreset(String presetName) {
        return ConfigManager.getPreset(presetName);
    }

    public static void createDefaultConfig(String filePath, String preset) throws IOException {
        ConfigManager.createDefaultConfig(filePath, preset);
    }
}