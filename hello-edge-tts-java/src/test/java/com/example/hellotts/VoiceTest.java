package com.example.hellotts;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for the Voice class.
 */
public class VoiceTest {

    private Voice ariaVoice;
    private Voice davisVoice;
    private Voice soniaVoice;
    private Voice elviraVoice;
    private List<Voice> testVoices;

    @BeforeEach
    void setUp() {
        ariaVoice = new Voice("en-US-AriaNeural", "Aria", "en-US", "Female", "Friendly and conversational");
        davisVoice = new Voice("en-US-DavisNeural", "Davis", "en-US", "Male", "Professional and clear");
        soniaVoice = new Voice("en-GB-SoniaNeural", "Sonia", "en-GB", "Female", "British accent, professional");
        elviraVoice = new Voice("es-ES-ElviraNeural", "Elvira", "es-ES", "Female", "Spanish from Spain");
        
        testVoices = Arrays.asList(ariaVoice, davisVoice, soniaVoice, elviraVoice);
    }

    @Test
    void testVoiceCreation() {
        assertEquals("en-US-AriaNeural", ariaVoice.getName());
        assertEquals("Aria", ariaVoice.getDisplayName());
        assertEquals("en-US", ariaVoice.getLocale());
        assertEquals("Female", ariaVoice.getGender());
        assertEquals("Friendly and conversational", ariaVoice.getDescription());
    }

    @Test
    void testVoiceCreationWithoutDescription() {
        Voice voice = new Voice("test-voice", "Test", "en-US", "Male");
        assertEquals("test-voice", voice.getName());
        assertEquals("Test", voice.getDisplayName());
        assertEquals("en-US", voice.getLocale());
        assertEquals("Male", voice.getGender());
        assertNull(voice.getDescription());
    }

    @Test
    void testVoiceCreationWithNullValues() {
        assertThrows(NullPointerException.class, () -> 
            new Voice(null, "Test", "en-US", "Male"));
        assertThrows(NullPointerException.class, () -> 
            new Voice("test", null, "en-US", "Male"));
        assertThrows(NullPointerException.class, () -> 
            new Voice("test", "Test", null, "Male"));
        assertThrows(NullPointerException.class, () -> 
            new Voice("test", "Test", "en-US", null));
    }

    @Test
    void testGetLanguage() {
        assertEquals("en", ariaVoice.getLanguage());
        assertEquals("es", elviraVoice.getLanguage());
        
        // Test voice with no country code
        Voice simpleVoice = new Voice("test", "Test", "fr", "Female");
        assertEquals("fr", simpleVoice.getLanguage());
    }

    @Test
    void testGetCountry() {
        assertEquals("US", ariaVoice.getCountry());
        assertEquals("GB", soniaVoice.getCountry());
        assertEquals("ES", elviraVoice.getCountry());
        
        // Test voice with no country code
        Voice simpleVoice = new Voice("test", "Test", "fr", "Female");
        assertEquals("", simpleVoice.getCountry());
    }

    @Test
    void testGetVoicesByLanguage() {
        List<Voice> englishVoices = Voice.getVoicesByLanguage(testVoices, "en")
                .collect(Collectors.toList());
        
        assertEquals(3, englishVoices.size());
        assertTrue(englishVoices.contains(ariaVoice));
        assertTrue(englishVoices.contains(davisVoice));
        assertTrue(englishVoices.contains(soniaVoice));
        assertFalse(englishVoices.contains(elviraVoice));
    }

    @Test
    void testGetVoicesByLanguageCaseInsensitive() {
        List<Voice> englishVoices = Voice.getVoicesByLanguage(testVoices, "EN")
                .collect(Collectors.toList());
        
        assertEquals(3, englishVoices.size());
        
        List<Voice> spanishVoices = Voice.getVoicesByLanguage(testVoices, "Es")
                .collect(Collectors.toList());
        
        assertEquals(1, spanishVoices.size());
        assertTrue(spanishVoices.contains(elviraVoice));
    }

    @Test
    void testGetVoicesByLanguageWithNullInputs() {
        assertThrows(NullPointerException.class, () -> 
            Voice.getVoicesByLanguage(null, "en"));
        assertThrows(NullPointerException.class, () -> 
            Voice.getVoicesByLanguage(testVoices, null));
    }

    @Test
    void testGetVoicesByLocale() {
        List<Voice> usVoices = Voice.getVoicesByLocale(testVoices, "en-US")
                .collect(Collectors.toList());
        
        assertEquals(2, usVoices.size());
        assertTrue(usVoices.contains(ariaVoice));
        assertTrue(usVoices.contains(davisVoice));
    }

    @Test
    void testGetVoicesByLocaleCaseInsensitive() {
        List<Voice> usVoices = Voice.getVoicesByLocale(testVoices, "EN-us")
                .collect(Collectors.toList());
        
        assertEquals(2, usVoices.size());
    }

    @Test
    void testGetVoicesByGender() {
        List<Voice> femaleVoices = Voice.getVoicesByGender(testVoices, "Female")
                .collect(Collectors.toList());
        
        assertEquals(3, femaleVoices.size());
        assertTrue(femaleVoices.contains(ariaVoice));
        assertTrue(femaleVoices.contains(soniaVoice));
        assertTrue(femaleVoices.contains(elviraVoice));
        assertFalse(femaleVoices.contains(davisVoice));
        
        List<Voice> maleVoices = Voice.getVoicesByGender(testVoices, "Male")
                .collect(Collectors.toList());
        
        assertEquals(1, maleVoices.size());
        assertTrue(maleVoices.contains(davisVoice));
    }

    @Test
    void testGetVoicesByGenderCaseInsensitive() {
        List<Voice> femaleVoices = Voice.getVoicesByGender(testVoices, "FEMALE")
                .collect(Collectors.toList());
        
        assertEquals(3, femaleVoices.size());
    }

    @Test
    void testParseVoicesFromJson() throws JsonProcessingException {
        String jsonString = "{\n" +
            "  \"popular_voices\": {\n" +
            "    \"english_us\": [\n" +
            "      {\n" +
            "        \"name\": \"en-US-AriaNeural\",\n" +
            "        \"displayName\": \"Aria\",\n" +
            "        \"gender\": \"Female\",\n" +
            "        \"locale\": \"en-US\",\n" +
            "        \"description\": \"Friendly and conversational\"\n" +
            "      },\n" +
            "      {\n" +
            "        \"name\": \"en-US-DavisNeural\",\n" +
            "        \"displayName\": \"Davis\",\n" +
            "        \"gender\": \"Male\",\n" +
            "        \"locale\": \"en-US\",\n" +
            "        \"description\": \"Professional and clear\"\n" +
            "      }\n" +
            "    ],\n" +
            "    \"spanish\": [\n" +
            "      {\n" +
            "        \"name\": \"es-ES-ElviraNeural\",\n" +
            "        \"displayName\": \"Elvira\",\n" +
            "        \"gender\": \"Female\",\n" +
            "        \"locale\": \"es-ES\",\n" +
            "        \"description\": \"Spanish from Spain\"\n" +
            "      }\n" +
            "    ]\n" +
            "  }\n" +
            "}";

        List<Voice> voices = Voice.parseVoicesFromJson(jsonString);
        
        assertEquals(3, voices.size());
        
        Voice aria = voices.stream()
                .filter(v -> v.getName().equals("en-US-AriaNeural"))
                .findFirst()
                .orElse(null);
        
        assertNotNull(aria);
        assertEquals("Aria", aria.getDisplayName());
        assertEquals("Female", aria.getGender());
        assertEquals("en-US", aria.getLocale());
        assertEquals("Friendly and conversational", aria.getDescription());
    }

    @Test
    void testParseVoicesFromJsonWithNullInput() {
        assertThrows(NullPointerException.class, () -> 
            Voice.parseVoicesFromJson(null));
    }

    @Test
    void testParseVoicesFromJsonWithInvalidJson() {
        assertThrows(JsonProcessingException.class, () -> 
            Voice.parseVoicesFromJson("invalid json"));
    }

    @Test
    void testEqualsAndHashCode() {
        Voice voice1 = new Voice("test", "Test", "en-US", "Female", "Description");
        Voice voice2 = new Voice("test", "Test", "en-US", "Female", "Description");
        Voice voice3 = new Voice("test2", "Test", "en-US", "Female", "Description");
        
        assertEquals(voice1, voice2);
        assertEquals(voice1.hashCode(), voice2.hashCode());
        assertNotEquals(voice1, voice3);
        assertNotEquals(voice1.hashCode(), voice3.hashCode());
        
        assertNotEquals(voice1, null);
        assertNotEquals(voice1, "not a voice");
    }

    @Test
    void testToString() {
        String expected = "Voice{name='en-US-AriaNeural', displayName='Aria', locale='en-US', gender='Female', description='Friendly and conversational'}";
        assertEquals(expected, ariaVoice.toString());
    }

    @Test
    void testToDisplayString() {
        String expected = "Aria (en-US, Female) - Friendly and conversational";
        assertEquals(expected, ariaVoice.toDisplayString());
        
        Voice voiceWithoutDescription = new Voice("test", "Test", "en-US", "Male");
        String expectedWithoutDesc = "Test (en-US, Male)";
        assertEquals(expectedWithoutDesc, voiceWithoutDescription.toDisplayString());
    }
}