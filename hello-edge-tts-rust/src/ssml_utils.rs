

/// SSML (Speech Synthesis Markup Language) utilities for Edge TTS
/// 
/// This module provides builder patterns and validation for creating
/// SSML markup for use with Microsoft Edge TTS service.

/// Builder for creating SSML markup
pub struct SSMLBuilder {
    voice: String,
    lang: String,
    elements: Vec<String>,
}

impl SSMLBuilder {
    /// Create a new SSML builder
    pub fn new(voice: &str) -> Self {
        let lang = Self::extract_language(voice);
        Self {
            voice: voice.to_string(),
            lang,
            elements: Vec::new(),
        }
    }

    /// Create a new SSML builder with explicit language
    pub fn with_language(voice: &str, lang: &str) -> Self {
        Self {
            voice: voice.to_string(),
            lang: lang.to_string(),
            elements: Vec::new(),
        }
    }

    /// Extract language code from voice name
    fn extract_language(voice: &str) -> String {
        let parts: Vec<&str> = voice.split('-').collect();
        if parts.len() >= 2 {
            format!("{}-{}", parts[0], parts[1])
        } else {
            "en-US".to_string()
        }
    }

    /// Add plain text
    pub fn add_text(mut self, text: &str) -> Self {
        self.elements.push(text.to_string());
        self
    }

    /// Add text with prosody controls
    pub fn add_prosody(mut self, text: &str, rate: Option<&str>, pitch: Option<&str>, volume: Option<&str>) -> Self {
        let mut attrs = Vec::new();
        if let Some(r) = rate {
            attrs.push(format!("rate=\"{}\"", r));
        }
        if let Some(p) = pitch {
            attrs.push(format!("pitch=\"{}\"", p));
        }
        if let Some(v) = volume {
            attrs.push(format!("volume=\"{}\"", v));
        }

        let attr_str = if attrs.is_empty() {
            String::new()
        } else {
            format!(" {}", attrs.join(" "))
        };

        self.elements.push(format!("<prosody{}>{}</prosody>", attr_str, text));
        self
    }

    /// Add emphasized text
    pub fn add_emphasis(mut self, text: &str, level: &str) -> Self {
        self.elements.push(format!("<emphasis level=\"{}\">{}</emphasis>", level, text));
        self
    }

    /// Add a break/pause
    pub fn add_break(mut self, time: &str) -> Self {
        self.elements.push(format!("<break time=\"{}\"/>", time));
        self
    }

    /// Add say-as element for special text interpretation
    pub fn add_say_as(mut self, text: &str, interpret_as: &str, format: Option<&str>) -> Self {
        let format_attr = format.map(|f| format!(" format=\"{}\"", f)).unwrap_or_default();
        self.elements.push(format!("<say-as interpret-as=\"{}\"{}>{}</say-as>", interpret_as, format_attr, text));
        self
    }

    /// Add phoneme pronunciation
    pub fn add_phoneme(mut self, text: &str, alphabet: &str, ph: &str) -> Self {
        self.elements.push(format!("<phoneme alphabet=\"{}\" ph=\"{}\">{}</phoneme>", alphabet, ph, text));
        self
    }

    /// Add substitution
    pub fn add_sub(mut self, text: &str, alias: &str) -> Self {
        self.elements.push(format!("<sub alias=\"{}\">{}</sub>", alias, text));
        self
    }

    /// Build the complete SSML markup
    pub fn build(self) -> String {
        let content = self.elements.join("");
        format!(
            r#"<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{}">
    <voice name="{}">
        {}
    </voice>
</speak>"#,
            self.lang, self.voice, content
        )
    }
}

/// Validator for SSML markup
pub struct SSMLValidator;

impl SSMLValidator {
    const VALID_PROSODY_RATES: &'static [&'static str] = &[
        "x-slow", "slow", "medium", "fast", "x-fast"
    ];

    const VALID_PROSODY_PITCHES: &'static [&'static str] = &[
        "x-low", "low", "medium", "high", "x-high"
    ];

    const VALID_PROSODY_VOLUMES: &'static [&'static str] = &[
        "silent", "x-soft", "soft", "medium", "loud", "x-loud"
    ];

    const VALID_EMPHASIS_LEVELS: &'static [&'static str] = &[
        "strong", "moderate", "reduced"
    ];

    const VALID_BREAK_STRENGTHS: &'static [&'static str] = &[
        "none", "x-weak", "weak", "medium", "strong", "x-strong"
    ];

    /// Validate SSML markup and return list of errors
    pub fn validate(ssml: &str) -> Vec<String> {
        let mut errors = Vec::new();

        // Basic validation
        if !ssml.trim_start().starts_with("<speak") {
            errors.push("SSML must start with <speak> element".to_string());
        }

        if !ssml.contains("version=\"1.0\"") {
            errors.push("Missing version=\"1.0\" attribute in <speak> element".to_string());
        }

        if !ssml.contains("xmlns=\"http://www.w3.org/2001/10/synthesis\"") {
            errors.push("Missing xmlns attribute in <speak> element".to_string());
        }

        // Validate specific elements
        Self::validate_prosody_elements(ssml, &mut errors);
        Self::validate_emphasis_elements(ssml, &mut errors);
        Self::validate_break_elements(ssml, &mut errors);

        errors
    }

    fn validate_prosody_elements(ssml: &str, errors: &mut Vec<String>) {
        use regex::Regex;
        
        let prosody_regex = Regex::new(r"<prosody\s+([^>]+)>").unwrap();
        
        for caps in prosody_regex.captures_iter(ssml) {
            let attrs = &caps[1];
            
            if let Some(rate_caps) = Regex::new(r#"rate="([^"]+)""#).unwrap().captures(attrs) {
                let rate = &rate_caps[1];
                if !Self::VALID_PROSODY_RATES.contains(&rate) && 
                   !rate.ends_with('%') && !rate.ends_with("Hz") {
                    errors.push(format!("Invalid prosody rate: {}", rate));
                }
            }

            if let Some(pitch_caps) = Regex::new(r#"pitch="([^"]+)""#).unwrap().captures(attrs) {
                let pitch = &pitch_caps[1];
                if !Self::VALID_PROSODY_PITCHES.contains(&pitch) && 
                   !pitch.ends_with("Hz") && !pitch.ends_with("st") {
                    errors.push(format!("Invalid prosody pitch: {}", pitch));
                }
            }

            if let Some(volume_caps) = Regex::new(r#"volume="([^"]+)""#).unwrap().captures(attrs) {
                let volume = &volume_caps[1];
                if !Self::VALID_PROSODY_VOLUMES.contains(&volume) && !volume.ends_with("dB") {
                    errors.push(format!("Invalid prosody volume: {}", volume));
                }
            }
        }
    }

    fn validate_emphasis_elements(ssml: &str, errors: &mut Vec<String>) {
        use regex::Regex;
        
        let emphasis_regex = Regex::new(r#"<emphasis\s+level="([^"]+)""#).unwrap();
        
        for caps in emphasis_regex.captures_iter(ssml) {
            let level = &caps[1];
            if !Self::VALID_EMPHASIS_LEVELS.contains(&level) {
                errors.push(format!("Invalid emphasis level: {}", level));
            }
        }
    }

    fn validate_break_elements(ssml: &str, errors: &mut Vec<String>) {
        use regex::Regex;
        
        let break_regex = Regex::new(r"<break\s+([^>]+)/>").unwrap();
        
        for caps in break_regex.captures_iter(ssml) {
            let attrs = &caps[1];
            
            if let Some(time_caps) = Regex::new(r#"time="([^"]+)""#).unwrap().captures(attrs) {
                let time = &time_caps[1];
                if !time.ends_with('s') && !time.ends_with("ms") {
                    errors.push(format!("Invalid break time format: {}", time));
                }
            }

            if let Some(strength_caps) = Regex::new(r#"strength="([^"]+)""#).unwrap().captures(attrs) {
                let strength = &strength_caps[1];
                if !Self::VALID_BREAK_STRENGTHS.contains(&strength) {
                    errors.push(format!("Invalid break strength: {}", strength));
                }
            }
        }
    }
}

/// Predefined SSML templates
pub struct SSMLTemplates;

impl SSMLTemplates {
    /// Create SSML using a predefined template
    pub fn create_from_template(template_name: &str, text: &str, voice: &str) -> Result<String, String> {
        match template_name {
            "slow_speech" => Ok(SSMLBuilder::new(voice).add_prosody(text, Some("slow"), None, None).build()),
            "fast_speech" => Ok(SSMLBuilder::new(voice).add_prosody(text, Some("fast"), None, None).build()),
            "whisper" => Ok(SSMLBuilder::new(voice).add_prosody(text, Some("slow"), None, Some("x-soft")).build()),
            "excited" => Ok(SSMLBuilder::new(voice).add_prosody(text, Some("fast"), Some("high"), Some("loud")).build()),
            "calm" => Ok(SSMLBuilder::new(voice).add_prosody(text, Some("slow"), Some("low"), Some("soft")).build()),
            "emphasis_strong" => Ok(SSMLBuilder::new(voice).add_emphasis(text, "strong").build()),
            "with_pauses" => {
                if text.contains('.') {
                    let parts: Vec<&str> = text.split('.').collect();
                    if parts.len() >= 2 {
                        Ok(SSMLBuilder::new(voice)
                            .add_text(parts[0])
                            .add_break("1s")
                            .add_text(&parts[1..].join("."))
                            .build())
                    } else {
                        Ok(SSMLBuilder::new(voice).add_text(text).build())
                    }
                } else {
                    Ok(SSMLBuilder::new(voice).add_text(text).build())
                }
            },
            _ => {
                let available = "slow_speech, fast_speech, whisper, excited, calm, emphasis_strong, with_pauses";
                Err(format!("Unknown template '{}'. Available: {}", template_name, available))
            }
        }
    }

    /// Get list of available template names
    pub fn get_available_templates() -> Vec<&'static str> {
        vec![
            "slow_speech",
            "fast_speech", 
            "whisper",
            "excited",
            "calm",
            "emphasis_strong",
            "with_pauses"
        ]
    }
}

/// Validate SSML markup
pub fn validate_ssml(ssml: &str, raise_on_error: bool) -> Result<Vec<String>, String> {
    let errors = SSMLValidator::validate(ssml);
    
    if !errors.is_empty() && raise_on_error {
        return Err(format!("SSML validation failed: {}", errors.join("; ")));
    }
    
    Ok(errors)
}

/// Create SSML with prosody controls
pub fn create_ssml(text: &str, voice: &str, rate: Option<&str>, pitch: Option<&str>, volume: Option<&str>) -> String {
    SSMLBuilder::new(voice).add_prosody(text, rate, pitch, volume).build()
}

/// Create SSML with emphasis
pub fn create_emphasis_ssml(text: &str, voice: &str, level: &str) -> String {
    SSMLBuilder::new(voice).add_emphasis(text, level).build()
}

/// Create SSML with breaks between text parts
pub fn create_break_ssml(text_parts: &[&str], voice: &str, break_time: &str) -> String {
    let mut builder = SSMLBuilder::new(voice);
    
    for (i, part) in text_parts.iter().enumerate() {
        builder = builder.add_text(part);
        if i < text_parts.len() - 1 {
            builder = builder.add_break(break_time);
        }
    }
    
    builder.build()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ssml_builder_basic() {
        let ssml = SSMLBuilder::new("en-US-AriaNeural")
            .add_text("Hello, world!")
            .build();
        
        assert!(ssml.contains("<speak"));
        assert!(ssml.contains("en-US-AriaNeural"));
        assert!(ssml.contains("Hello, world!"));
    }

    #[test]
    fn test_ssml_builder_prosody() {
        let ssml = SSMLBuilder::new("en-US-AriaNeural")
            .add_prosody("Hello", Some("slow"), Some("high"), Some("loud"))
            .build();
        
        assert!(ssml.contains("rate=\"slow\""));
        assert!(ssml.contains("pitch=\"high\""));
        assert!(ssml.contains("volume=\"loud\""));
    }

    #[test]
    fn test_ssml_builder_emphasis() {
        let ssml = SSMLBuilder::new("en-US-AriaNeural")
            .add_emphasis("Important!", "strong")
            .build();
        
        assert!(ssml.contains("<emphasis level=\"strong\">Important!</emphasis>"));
    }

    #[test]
    fn test_ssml_builder_break() {
        let ssml = SSMLBuilder::new("en-US-AriaNeural")
            .add_text("First part")
            .add_break("2s")
            .add_text("Second part")
            .build();
        
        assert!(ssml.contains("<break time=\"2s\"/>"));
    }

    #[test]
    fn test_ssml_validation_valid() {
        let ssml = SSMLBuilder::new("en-US-AriaNeural")
            .add_text("Hello")
            .build();
        
        let errors = SSMLValidator::validate(&ssml);
        assert!(errors.is_empty());
    }

    #[test]
    fn test_ssml_validation_invalid() {
        let invalid_ssml = "<invalid>test</invalid>";
        let errors = SSMLValidator::validate(invalid_ssml);
        assert!(!errors.is_empty());
    }

    #[test]
    fn test_templates() {
        let result = SSMLTemplates::create_from_template("slow_speech", "Hello", "en-US-AriaNeural");
        assert!(result.is_ok());
        assert!(result.unwrap().contains("rate=\"slow\""));
    }

    #[test]
    fn test_template_unknown() {
        let result = SSMLTemplates::create_from_template("unknown", "Hello", "en-US-AriaNeural");
        assert!(result.is_err());
    }
}