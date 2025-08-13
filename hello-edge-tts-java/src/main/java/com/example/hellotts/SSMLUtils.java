package com.example.hellotts;

import java.util.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.function.BiFunction;

/**
 * SSML (Speech Synthesis Markup Language) utilities for Edge TTS.
 * 
 * This class provides builder patterns and validation for creating
 * SSML markup for use with Microsoft Edge TTS service.
 */
public class SSMLUtils {

    /**
     * Builder for creating SSML markup
     */
    public static class SSMLBuilder {
        private final String voice;
        private final String lang;
        private final List<String> elements;

        public SSMLBuilder(String voice) {
            this.voice = voice;
            this.lang = extractLanguage(voice);
            this.elements = new ArrayList<>();
        }

        public SSMLBuilder(String voice, String lang) {
            this.voice = voice;
            this.lang = lang;
            this.elements = new ArrayList<>();
        }

        private static String extractLanguage(String voice) {
            String[] parts = voice.split("-");
            if (parts.length >= 2) {
                return parts[0] + "-" + parts[1];
            }
            return "en-US";
        }

        /**
         * Add plain text
         */
        public SSMLBuilder addText(String text) {
            elements.add(text);
            return this;
        }

        /**
         * Add text with prosody controls
         */
        public SSMLBuilder addProsody(String text, String rate, String pitch, String volume) {
            List<String> attrs = new ArrayList<>();
            if (rate != null) attrs.add("rate=\"" + rate + "\"");
            if (pitch != null) attrs.add("pitch=\"" + pitch + "\"");
            if (volume != null) attrs.add("volume=\"" + volume + "\"");

            String attrStr = attrs.isEmpty() ? "" : " " + String.join(" ", attrs);
            elements.add("<prosody" + attrStr + ">" + text + "</prosody>");
            return this;
        }

        /**
         * Add emphasized text
         */
        public SSMLBuilder addEmphasis(String text, String level) {
            elements.add("<emphasis level=\"" + level + "\">" + text + "</emphasis>");
            return this;
        }

        /**
         * Add a break/pause
         */
        public SSMLBuilder addBreak(String time) {
            elements.add("<break time=\"" + time + "\"/>");
            return this;
        }

        /**
         * Add say-as element for special text interpretation
         */
        public SSMLBuilder addSayAs(String text, String interpretAs, String format) {
            String formatAttr = format != null ? " format=\"" + format + "\"" : "";
            elements.add("<say-as interpret-as=\"" + interpretAs + "\"" + formatAttr + ">" + text + "</say-as>");
            return this;
        }

        /**
         * Add phoneme pronunciation
         */
        public SSMLBuilder addPhoneme(String text, String alphabet, String ph) {
            elements.add("<phoneme alphabet=\"" + alphabet + "\" ph=\"" + ph + "\">" + text + "</phoneme>");
            return this;
        }

        /**
         * Add substitution
         */
        public SSMLBuilder addSub(String text, String alias) {
            elements.add("<sub alias=\"" + alias + "\">" + text + "</sub>");
            return this;
        }

        /**
         * Build the complete SSML markup
         */
        public String build() {
            String content = String.join("", elements);
            return String.format(
                "<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"%s\">\n" +
                "    <voice name=\"%s\">\n" +
                "        %s\n" +
                "    </voice>\n" +
                "</speak>",
                lang, voice, content
            );
        }
    }

    /**
     * Validator for SSML markup
     */
    public static class SSMLValidator {
        private static final Set<String> VALID_PROSODY_RATES = Set.of(
            "x-slow", "slow", "medium", "fast", "x-fast"
        );

        private static final Set<String> VALID_PROSODY_PITCHES = Set.of(
            "x-low", "low", "medium", "high", "x-high"
        );

        private static final Set<String> VALID_PROSODY_VOLUMES = Set.of(
            "silent", "x-soft", "soft", "medium", "loud", "x-loud"
        );

        private static final Set<String> VALID_EMPHASIS_LEVELS = Set.of(
            "strong", "moderate", "reduced"
        );

        private static final Set<String> VALID_BREAK_STRENGTHS = Set.of(
            "none", "x-weak", "weak", "medium", "strong", "x-strong"
        );

        /**
         * Validate SSML markup and return list of errors
         */
        public static List<String> validate(String ssml) {
            List<String> errors = new ArrayList<>();

            // Basic validation
            if (!ssml.trim().startsWith("<speak")) {
                errors.add("SSML must start with <speak> element");
            }

            if (!ssml.contains("version=\"1.0\"")) {
                errors.add("Missing version=\"1.0\" attribute in <speak> element");
            }

            if (!ssml.contains("xmlns=\"http://www.w3.org/2001/10/synthesis\"")) {
                errors.add("Missing xmlns attribute in <speak> element");
            }

            // Validate specific elements
            validateProsodyElements(ssml, errors);
            validateEmphasisElements(ssml, errors);
            validateBreakElements(ssml, errors);

            return errors;
        }

        private static void validateProsodyElements(String ssml, List<String> errors) {
            Pattern prosodyPattern = Pattern.compile("<prosody\\s+([^>]+)>");
            Matcher matcher = prosodyPattern.matcher(ssml);

            while (matcher.find()) {
                String attrs = matcher.group(1);

                Pattern ratePattern = Pattern.compile("rate=\"([^\"]+)\"");
                Matcher rateMatch = ratePattern.matcher(attrs);
                if (rateMatch.find()) {
                    String rate = rateMatch.group(1);
                    if (!VALID_PROSODY_RATES.contains(rate) && 
                        !rate.endsWith("%") && !rate.endsWith("Hz")) {
                        errors.add("Invalid prosody rate: " + rate);
                    }
                }

                Pattern pitchPattern = Pattern.compile("pitch=\"([^\"]+)\"");
                Matcher pitchMatch = pitchPattern.matcher(attrs);
                if (pitchMatch.find()) {
                    String pitch = pitchMatch.group(1);
                    if (!VALID_PROSODY_PITCHES.contains(pitch) && 
                        !pitch.endsWith("Hz") && !pitch.endsWith("st")) {
                        errors.add("Invalid prosody pitch: " + pitch);
                    }
                }

                Pattern volumePattern = Pattern.compile("volume=\"([^\"]+)\"");
                Matcher volumeMatch = volumePattern.matcher(attrs);
                if (volumeMatch.find()) {
                    String volume = volumeMatch.group(1);
                    if (!VALID_PROSODY_VOLUMES.contains(volume) && !volume.endsWith("dB")) {
                        errors.add("Invalid prosody volume: " + volume);
                    }
                }
            }
        }

        private static void validateEmphasisElements(String ssml, List<String> errors) {
            Pattern emphasisPattern = Pattern.compile("<emphasis\\s+level=\"([^\"]+)\"");
            Matcher matcher = emphasisPattern.matcher(ssml);

            while (matcher.find()) {
                String level = matcher.group(1);
                if (!VALID_EMPHASIS_LEVELS.contains(level)) {
                    errors.add("Invalid emphasis level: " + level);
                }
            }
        }

        private static void validateBreakElements(String ssml, List<String> errors) {
            Pattern breakPattern = Pattern.compile("<break\\s+([^>]+)/>");
            Matcher matcher = breakPattern.matcher(ssml);

            while (matcher.find()) {
                String attrs = matcher.group(1);

                Pattern timePattern = Pattern.compile("time=\"([^\"]+)\"");
                Matcher timeMatch = timePattern.matcher(attrs);
                if (timeMatch.find()) {
                    String time = timeMatch.group(1);
                    if (!time.endsWith("s") && !time.endsWith("ms")) {
                        errors.add("Invalid break time format: " + time);
                    }
                }

                Pattern strengthPattern = Pattern.compile("strength=\"([^\"]+)\"");
                Matcher strengthMatch = strengthPattern.matcher(attrs);
                if (strengthMatch.find()) {
                    String strength = strengthMatch.group(1);
                    if (!VALID_BREAK_STRENGTHS.contains(strength)) {
                        errors.add("Invalid break strength: " + strength);
                    }
                }
            }
        }
    }

    /**
     * Predefined SSML templates
     */
    public static class SSMLTemplates {
        private static final Map<String, BiFunction<String, String, String>> templates = Map.of(
            "slow_speech", (text, voice) -> new SSMLBuilder(voice).addProsody(text, "slow", null, null).build(),
            "fast_speech", (text, voice) -> new SSMLBuilder(voice).addProsody(text, "fast", null, null).build(),
            "whisper", (text, voice) -> new SSMLBuilder(voice).addProsody(text, "slow", null, "x-soft").build(),
            "excited", (text, voice) -> new SSMLBuilder(voice).addProsody(text, "fast", "high", "loud").build(),
            "calm", (text, voice) -> new SSMLBuilder(voice).addProsody(text, "slow", "low", "soft").build(),
            "emphasis_strong", (text, voice) -> new SSMLBuilder(voice).addEmphasis(text, "strong").build(),
            "with_pauses", (text, voice) -> {
                if (text.contains(".")) {
                    String[] parts = text.split("\\.", 2);
                    return new SSMLBuilder(voice)
                        .addText(parts[0])
                        .addBreak("1s")
                        .addText(parts.length > 1 ? parts[1] : "")
                        .build();
                }
                return new SSMLBuilder(voice).addText(text).build();
            }
        );

        /**
         * Create SSML using a predefined template
         */
        public static String createFromTemplate(String templateName, String text, String voice) {
            BiFunction<String, String, String> template = templates.get(templateName);
            if (template == null) {
                String available = String.join(", ", templates.keySet());
                throw new IllegalArgumentException("Unknown template '" + templateName + "'. Available: " + available);
            }
            return template.apply(text, voice);
        }

        /**
         * Get list of available template names
         */
        public static Set<String> getAvailableTemplates() {
            return templates.keySet();
        }
    }

    /**
     * Validate SSML markup
     */
    public static List<String> validateSSML(String ssml, boolean raiseOnError) {
        List<String> errors = SSMLValidator.validate(ssml);
        
        if (!errors.isEmpty() && raiseOnError) {
            throw new IllegalArgumentException("SSML validation failed: " + String.join("; ", errors));
        }
        
        return errors;
    }

    /**
     * Create SSML with prosody controls
     */
    public static String createSSML(String text, String voice, String rate, String pitch, String volume) {
        return new SSMLBuilder(voice).addProsody(text, rate, pitch, volume).build();
    }

    /**
     * Create SSML with emphasis
     */
    public static String createEmphasisSSML(String text, String voice, String level) {
        return new SSMLBuilder(voice).addEmphasis(text, level).build();
    }

    /**
     * Create SSML with breaks between text parts
     */
    public static String createBreakSSML(String[] textParts, String voice, String breakTime) {
        SSMLBuilder builder = new SSMLBuilder(voice);
        
        for (int i = 0; i < textParts.length; i++) {
            builder.addText(textParts[i]);
            if (i < textParts.length - 1) {
                builder.addBreak(breakTime);
            }
        }
        
        return builder.build();
    }
}