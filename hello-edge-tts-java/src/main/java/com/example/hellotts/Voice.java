package com.example.hellotts;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Stream;

/**
 * Immutable Voice class representing a text-to-speech voice with its properties.
 * This class provides voice information including name, display name, locale, and gender.
 */
public final class Voice {
    private final String name;
    private final String displayName;
    private final String locale;
    private final String gender;
    private final String description;

    /**
     * Creates a new Voice instance.
     *
     * @param name        The technical name of the voice (e.g., "en-US-AriaNeural")
     * @param displayName The human-readable display name (e.g., "Aria")
     * @param locale      The locale/language code (e.g., "en-US")
     * @param gender      The voice gender ("Male" or "Female")
     * @param description Optional description of the voice characteristics
     */
    @JsonCreator
    public Voice(
            @JsonProperty("name") String name,
            @JsonProperty("displayName") String displayName,
            @JsonProperty("locale") String locale,
            @JsonProperty("gender") String gender,
            @JsonProperty("description") String description) {
        this.name = Objects.requireNonNull(name, "Voice name cannot be null");
        this.displayName = Objects.requireNonNull(displayName, "Display name cannot be null");
        this.locale = Objects.requireNonNull(locale, "Locale cannot be null");
        this.gender = Objects.requireNonNull(gender, "Gender cannot be null");
        this.description = description; // Can be null
    }

    /**
     * Creates a new Voice instance without description.
     *
     * @param name        The technical name of the voice
     * @param displayName The human-readable display name
     * @param locale      The locale/language code
     * @param gender      The voice gender
     */
    public Voice(String name, String displayName, String locale, String gender) {
        this(name, displayName, locale, gender, null);
    }

    /**
     * Gets the technical name of the voice.
     *
     * @return The voice name (e.g., "en-US-AriaNeural")
     */
    public String getName() {
        return name;
    }

    /**
     * Gets the human-readable display name of the voice.
     *
     * @return The display name (e.g., "Aria")
     */
    public String getDisplayName() {
        return displayName;
    }

    /**
     * Gets the locale/language code of the voice.
     *
     * @return The locale (e.g., "en-US")
     */
    public String getLocale() {
        return locale;
    }

    /**
     * Gets the gender of the voice.
     *
     * @return The gender ("Male" or "Female")
     */
    public String getGender() {
        return gender;
    }

    /**
     * Gets the description of the voice characteristics.
     *
     * @return The description, or null if not available
     */
    public String getDescription() {
        return description;
    }

    /**
     * Gets the language code from the locale (e.g., "en" from "en-US").
     *
     * @return The language code
     */
    public String getLanguageCode() {
        if (locale.contains("-")) {
            return locale.substring(0, locale.indexOf("-"));
        }
        return locale;
    }
    
    /**
     * Gets the language code from the locale (e.g., "en" from "en-US").
     * @deprecated Use getLanguageCode() instead for consistency with other implementations
     * @return The language code
     */
    @Deprecated
    public String getLanguage() {
        return getLanguageCode();
    }

    /**
     * Gets the country code from the locale (e.g., "US" from "en-US").
     *
     * @return The country code, or empty string if not available
     */
    public String getCountryCode() {
        if (locale.contains("-")) {
            return locale.substring(locale.indexOf("-") + 1);
        }
        return "";
    }
    
    /**
     * Gets the country code from the locale (e.g., "US" from "en-US").
     * @deprecated Use getCountryCode() instead for consistency with other implementations
     * @return The country code, or empty string if not available
     */
    @Deprecated
    public String getCountry() {
        return getCountryCode();
    }
    
    /**
     * Checks if this voice matches the given language code.
     *
     * @param language The language code to match (e.g., "en", "es", "fr")
     * @return true if the voice matches the language
     */
    public boolean matchesLanguage(String language) {
        if (language == null) return false;
        String normalizedLanguage = language.toLowerCase().trim();
        return getLanguageCode().toLowerCase().equals(normalizedLanguage) ||
               getLocale().toLowerCase().equals(normalizedLanguage);
    }

    /**
     * Filters a list of voices by language code.
     *
     * @param voices   The list of voices to filter
     * @param language The language code to filter by (e.g., "en", "es", "fr")
     * @return A stream of voices matching the specified language
     */
    public static Stream<Voice> getVoicesByLanguage(List<Voice> voices, String language) {
        Objects.requireNonNull(voices, "Voices list cannot be null");
        Objects.requireNonNull(language, "Language cannot be null");
        
        String normalizedLanguage = language.toLowerCase().trim();
        
        return voices.stream()
                .filter(voice -> voice.getLanguageCode().toLowerCase().equals(normalizedLanguage));
    }

    /**
     * Filters a list of voices by full locale (e.g., "en-US").
     *
     * @param voices The list of voices to filter
     * @param locale The locale to filter by
     * @return A stream of voices matching the specified locale
     */
    public static Stream<Voice> getVoicesByLocale(List<Voice> voices, String locale) {
        Objects.requireNonNull(voices, "Voices list cannot be null");
        Objects.requireNonNull(locale, "Locale cannot be null");
        
        String normalizedLocale = locale.toLowerCase().trim();
        
        return voices.stream()
                .filter(voice -> voice.getLocale().toLowerCase().equals(normalizedLocale));
    }

    /**
     * Filters a list of voices by gender.
     *
     * @param voices The list of voices to filter
     * @param gender The gender to filter by ("Male" or "Female")
     * @return A stream of voices matching the specified gender
     */
    public static Stream<Voice> getVoicesByGender(List<Voice> voices, String gender) {
        Objects.requireNonNull(voices, "Voices list cannot be null");
        Objects.requireNonNull(gender, "Gender cannot be null");
        
        String normalizedGender = gender.toLowerCase().trim();
        
        return voices.stream()
                .filter(voice -> voice.getGender().toLowerCase().equals(normalizedGender));
    }

    /**
     * Parses voices from a JSON string containing voice configuration data.
     *
     * @param jsonString The JSON string to parse
     * @return A list of Voice objects parsed from the JSON
     * @throws JsonProcessingException If the JSON cannot be parsed
     */
    public static List<Voice> parseVoicesFromJson(String jsonString) throws JsonProcessingException {
        Objects.requireNonNull(jsonString, "JSON string cannot be null");
        
        ObjectMapper mapper = new ObjectMapper();
        JsonNode rootNode = mapper.readTree(jsonString);
        List<Voice> voices = new ArrayList<>();

        // Parse voices from the popular_voices section
        JsonNode popularVoicesNode = rootNode.get("popular_voices");
        if (popularVoicesNode != null && popularVoicesNode.isObject()) {
            popularVoicesNode.fields().forEachRemaining(entry -> {
                JsonNode voiceArray = entry.getValue();
                if (voiceArray.isArray()) {
                    for (JsonNode voiceNode : voiceArray) {
                        try {
                            Voice voice = mapper.treeToValue(voiceNode, Voice.class);
                            voices.add(voice);
                        } catch (JsonProcessingException e) {
                            // Log error but continue processing other voices
                            System.err.println("Warning: Failed to parse voice: " + e.getMessage());
                        }
                    }
                }
            });
        }

        return voices;
    }

    /**
     * Parses voices from a JSON file containing voice configuration data.
     *
     * @param jsonFilePath The path to the JSON file
     * @return A list of Voice objects parsed from the file
     * @throws Exception If the file cannot be read or parsed
     */
    public static List<Voice> parseVoicesFromJsonFile(String jsonFilePath) throws Exception {
        Objects.requireNonNull(jsonFilePath, "JSON file path cannot be null");
        
        ObjectMapper mapper = new ObjectMapper();
        JsonNode rootNode = mapper.readTree(new java.io.File(jsonFilePath));
        List<Voice> voices = new ArrayList<>();

        // Parse voices from the popular_voices section
        JsonNode popularVoicesNode = rootNode.get("popular_voices");
        if (popularVoicesNode != null && popularVoicesNode.isObject()) {
            popularVoicesNode.fields().forEachRemaining(entry -> {
                JsonNode voiceArray = entry.getValue();
                if (voiceArray.isArray()) {
                    for (JsonNode voiceNode : voiceArray) {
                        try {
                            Voice voice = mapper.treeToValue(voiceNode, Voice.class);
                            voices.add(voice);
                        } catch (JsonProcessingException e) {
                            // Log error but continue processing other voices
                            System.err.println("Warning: Failed to parse voice: " + e.getMessage());
                        }
                    }
                }
            });
        }

        return voices;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        
        Voice voice = (Voice) obj;
        return Objects.equals(name, voice.name) &&
               Objects.equals(displayName, voice.displayName) &&
               Objects.equals(locale, voice.locale) &&
               Objects.equals(gender, voice.gender) &&
               Objects.equals(description, voice.description);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, displayName, locale, gender, description);
    }

    @Override
    public String toString() {
        return String.format("Voice{name='%s', displayName='%s', locale='%s', gender='%s', description='%s'}",
                name, displayName, locale, gender, description);
    }

    /**
     * Returns a formatted string representation suitable for display to users.
     *
     * @return A user-friendly string representation
     */
    public String toDisplayString() {
        StringBuilder sb = new StringBuilder();
        sb.append(displayName).append(" (").append(locale).append(", ").append(gender).append(")");
        if (description != null && !description.trim().isEmpty()) {
            sb.append(" - ").append(description);
        }
        return sb.toString();
    }
}