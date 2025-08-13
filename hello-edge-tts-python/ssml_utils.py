"""
SSML (Speech Synthesis Markup Language) utilities for Edge TTS.

This module provides helper functions and classes for creating and validating
SSML markup for use with Microsoft Edge TTS service.
"""

from typing import List, Dict, Any
import xml.etree.ElementTree as ET


class SSMLBuilder:
    """Builder class for creating SSML markup."""
    
    def __init__(self, voice: str, lang: str = None):
        """
        Initialize SSML builder.
        
        Args:
            voice: Voice name to use
            lang: Language code (auto-detected from voice if not provided)
        """
        self.voice = voice
        self.lang = lang or self._extract_language(voice)
        self.elements = []
    
    def _extract_language(self, voice: str) -> str:
        """Extract language code from voice name."""
        parts = voice.split('-')
        if len(parts) >= 2:
            return f"{parts[0]}-{parts[1]}"
        return "en-US"
    
    def add_text(self, text: str) -> 'SSMLBuilder':
        """Add plain text."""
        self.elements.append(text)
        return self
    
    def add_prosody(self, text: str, rate: str = None, pitch: str = None, volume: str = None) -> 'SSMLBuilder':
        """Add text with prosody controls."""
        attrs = []
        if rate:
            attrs.append(f'rate="{rate}"')
        if pitch:
            attrs.append(f'pitch="{pitch}"')
        if volume:
            attrs.append(f'volume="{volume}"')
        
        attr_str = ' ' + ' '.join(attrs) if attrs else ''
        self.elements.append(f'<prosody{attr_str}>{text}</prosody>')
        return self
    
    def add_emphasis(self, text: str, level: str = "moderate") -> 'SSMLBuilder':
        """Add emphasized text."""
        self.elements.append(f'<emphasis level="{level}">{text}</emphasis>')
        return self
    
    def add_break(self, time: str = "1s") -> 'SSMLBuilder':
        """Add a break/pause."""
        self.elements.append(f'<break time="{time}"/>')
        return self
    
    def add_say_as(self, text: str, interpret_as: str, format: str = None) -> 'SSMLBuilder':
        """Add say-as element for special text interpretation."""
        format_attr = f' format="{format}"' if format else ''
        self.elements.append(f'<say-as interpret-as="{interpret_as}"{format_attr}>{text}</say-as>')
        return self
    
    def add_phoneme(self, text: str, alphabet: str, ph: str) -> 'SSMLBuilder':
        """Add phoneme pronunciation."""
        self.elements.append(f'<phoneme alphabet="{alphabet}" ph="{ph}">{text}</phoneme>')
        return self
    
    def add_sub(self, text: str, alias: str) -> 'SSMLBuilder':
        """Add substitution."""
        self.elements.append(f'<sub alias="{alias}">{text}</sub>')
        return self
    
    def build(self) -> str:
        """Build the complete SSML markup."""
        content = ''.join(self.elements)
        return f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{self.lang}">
    <voice name="{self.voice}">
        {content}
    </voice>
</speak>'''


class SSMLValidator:
    """Validator for SSML markup."""
    
    VALID_PROSODY_RATES = {
        'x-slow', 'slow', 'medium', 'fast', 'x-fast'
    }
    
    VALID_PROSODY_PITCHES = {
        'x-low', 'low', 'medium', 'high', 'x-high'
    }
    
    VALID_PROSODY_VOLUMES = {
        'silent', 'x-soft', 'soft', 'medium', 'loud', 'x-loud'
    }
    
    VALID_EMPHASIS_LEVELS = {
        'strong', 'moderate', 'reduced'
    }
    
    VALID_BREAK_STRENGTHS = {
        'none', 'x-weak', 'weak', 'medium', 'strong', 'x-strong'
    }
    
    @staticmethod
    def validate(ssml: str) -> List[str]:
        """
        Validate SSML markup and return list of errors.
        
        Args:
            ssml: SSML markup to validate
            
        Returns:
            List of validation error messages (empty if valid)
        """
        errors = []
        
        try:
            # Parse XML
            root = ET.fromstring(ssml)
            
            # Check root element
            if root.tag != 'speak':
                errors.append("Root element must be <speak>")
            
            # Check required attributes
            if 'version' not in root.attrib:
                errors.append("Missing version attribute in <speak> element")
            
            if 'xmlns' not in root.attrib:
                errors.append("Missing xmlns attribute in <speak> element")
            
            # Validate child elements
            SSMLValidator._validate_element(root, errors)
            
        except ET.ParseError as e:
            errors.append(f"XML parsing error: {str(e)}")
        
        return errors
    
    @staticmethod
    def _validate_element(element: ET.Element, errors: List[str]) -> None:
        """Recursively validate SSML elements."""
        tag = element.tag
        
        if tag == 'prosody':
            SSMLValidator._validate_prosody(element, errors)
        elif tag == 'emphasis':
            SSMLValidator._validate_emphasis(element, errors)
        elif tag == 'break':
            SSMLValidator._validate_break(element, errors)
        elif tag == 'say-as':
            SSMLValidator._validate_say_as(element, errors)
        
        # Recursively validate children
        for child in element:
            SSMLValidator._validate_element(child, errors)
    
    @staticmethod
    def _validate_prosody(element: ET.Element, errors: List[str]) -> None:
        """Validate prosody element."""
        if 'rate' in element.attrib:
            rate = element.attrib['rate']
            if not (rate in SSMLValidator.VALID_PROSODY_RATES or 
                   rate.endswith('%') or rate.endswith('Hz')):
                errors.append(f"Invalid prosody rate: {rate}")
        
        if 'pitch' in element.attrib:
            pitch = element.attrib['pitch']
            if not (pitch in SSMLValidator.VALID_PROSODY_PITCHES or 
                   pitch.endswith('Hz') or pitch.endswith('st')):
                errors.append(f"Invalid prosody pitch: {pitch}")
        
        if 'volume' in element.attrib:
            volume = element.attrib['volume']
            if not (volume in SSMLValidator.VALID_PROSODY_VOLUMES or 
                   volume.endswith('dB')):
                errors.append(f"Invalid prosody volume: {volume}")
    
    @staticmethod
    def _validate_emphasis(element: ET.Element, errors: List[str]) -> None:
        """Validate emphasis element."""
        if 'level' in element.attrib:
            level = element.attrib['level']
            if level not in SSMLValidator.VALID_EMPHASIS_LEVELS:
                errors.append(f"Invalid emphasis level: {level}")
    
    @staticmethod
    def _validate_break(element: ET.Element, errors: List[str]) -> None:
        """Validate break element."""
        if 'time' in element.attrib:
            time = element.attrib['time']
            if not (time.endswith('s') or time.endswith('ms')):
                errors.append(f"Invalid break time format: {time}")
        
        if 'strength' in element.attrib:
            strength = element.attrib['strength']
            if strength not in SSMLValidator.VALID_BREAK_STRENGTHS:
                errors.append(f"Invalid break strength: {strength}")
    
    @staticmethod
    def _validate_say_as(element: ET.Element, errors: List[str]) -> None:
        """Validate say-as element."""
        if 'interpret-as' not in element.attrib:
            errors.append("say-as element missing interpret-as attribute")


# Predefined SSML templates
SSML_TEMPLATES = {
    'slow_speech': lambda text, voice: SSMLBuilder(voice).add_prosody(text, rate="slow").build(),
    'fast_speech': lambda text, voice: SSMLBuilder(voice).add_prosody(text, rate="fast").build(),
    'whisper': lambda text, voice: SSMLBuilder(voice).add_prosody(text, volume="x-soft", rate="slow").build(),
    'excited': lambda text, voice: SSMLBuilder(voice).add_prosody(text, rate="fast", pitch="high", volume="loud").build(),
    'calm': lambda text, voice: SSMLBuilder(voice).add_prosody(text, rate="slow", pitch="low", volume="soft").build(),
    'emphasis_strong': lambda text, voice: SSMLBuilder(voice).add_emphasis(text, "strong").build(),
    'with_pauses': lambda text, voice: SSMLBuilder(voice).add_text(text.split('.')[0]).add_break("1s").add_text('.'.join(text.split('.')[1:])).build() if '.' in text else SSMLBuilder(voice).add_text(text).build(),
}


def create_ssml_from_template(template_name: str, text: str, voice: str) -> str:
    """
    Create SSML using a predefined template.
    
    Args:
        template_name: Name of the template to use
        text: Text content
        voice: Voice name
        
    Returns:
        SSML markup string
        
    Raises:
        ValueError: If template name is not found
    """
    if template_name not in SSML_TEMPLATES:
        available = ', '.join(SSML_TEMPLATES.keys())
        raise ValueError(f"Unknown template '{template_name}'. Available: {available}")
    
    return SSML_TEMPLATES[template_name](text, voice)


def validate_ssml(ssml: str, raise_on_error: bool = True) -> List[str]:
    """
    Validate SSML markup.
    
    Args:
        ssml: SSML markup to validate
        raise_on_error: Whether to raise exception on validation errors
        
    Returns:
        List of validation error messages
        
    Raises:
        ValueError: If validation fails and raise_on_error is True
    """
    errors = SSMLValidator.validate(ssml)
    
    if errors and raise_on_error:
        raise ValueError(f"SSML validation failed: {'; '.join(errors)}")
    
    return errors