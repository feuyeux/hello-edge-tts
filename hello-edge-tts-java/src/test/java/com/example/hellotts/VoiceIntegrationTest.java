package com.example.hellotts;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests for the Voice class using the actual shared voice configuration file.
 */
public class VoiceIntegrationTest {

    @Test
    void testParseVoicesFromSharedConfigFile() throws Exception {
        // Test parsing the actual shared voice configuration file
        String configPath = "../shared/voice_configs.json";
        
        List<Voice> voices = Voice.parseVoicesFromJsonFile(configPath);
        
        // Verify we got some voices
        assertFalse(voices.isEmpty(), "Should parse at least some voices from the config file");
        
        // Verify we have expected voices
        boolean hasAria = voices.stream().anyMatch(v -> v.getName().equals("en-US-AriaNeural"));
        assertTrue(hasAria, "Should contain Aria voice");
        
        boolean hasDavis = voices.stream().anyMatch(v -> v.getName().equals("en-US-DavisNeural"));
        assertTrue(hasDavis, "Should contain Davis voice");
        
        // Test filtering by language
        List<Voice> englishVoices = Voice.getVoicesByLanguage(voices, "en")
                .collect(Collectors.toList());
        assertFalse(englishVoices.isEmpty(), "Should have English voices");
        
        List<Voice> spanishVoices = Voice.getVoicesByLanguage(voices, "es")
                .collect(Collectors.toList());
        assertFalse(spanishVoices.isEmpty(), "Should have Spanish voices");
        
        // Test filtering by locale
        List<Voice> usVoices = Voice.getVoicesByLocale(voices, "en-US")
                .collect(Collectors.toList());
        assertFalse(usVoices.isEmpty(), "Should have US English voices");
        
        // Test filtering by gender
        List<Voice> femaleVoices = Voice.getVoicesByGender(voices, "Female")
                .collect(Collectors.toList());
        assertFalse(femaleVoices.isEmpty(), "Should have female voices");
        
        List<Voice> maleVoices = Voice.getVoicesByGender(voices, "Male")
                .collect(Collectors.toList());
        assertFalse(maleVoices.isEmpty(), "Should have male voices");
        
        // Print some information for verification
        System.out.println("Total voices parsed: " + voices.size());
        System.out.println("English voices: " + englishVoices.size());
        System.out.println("Spanish voices: " + spanishVoices.size());
        System.out.println("Female voices: " + femaleVoices.size());
        System.out.println("Male voices: " + maleVoices.size());
        
        // Print first few voices for verification
        System.out.println("\nFirst few voices:");
        voices.stream().limit(5).forEach(voice -> 
            System.out.println("  " + voice.toDisplayString()));
    }
    
    @Test
    void testVoiceDisplayStrings() throws Exception {
        String configPath = "../shared/voice_configs.json";
        List<Voice> voices = Voice.parseVoicesFromJsonFile(configPath);
        
        // Test that all voices have proper display strings
        for (Voice voice : voices) {
            String displayString = voice.toDisplayString();
            assertNotNull(displayString);
            assertFalse(displayString.trim().isEmpty());
            
            // Should contain display name, locale, and gender
            assertTrue(displayString.contains(voice.getDisplayName()));
            assertTrue(displayString.contains(voice.getLocale()));
            assertTrue(displayString.contains(voice.getGender()));
        }
    }
}