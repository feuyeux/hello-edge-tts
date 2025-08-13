

/// SSML Builder for creating Speech Synthesis Markup Language
class SSMLBuilder {
  final StringBuffer _buffer = StringBuffer();
  bool _hasStarted = false;

  /// Start SSML document
  SSMLBuilder start({String language = 'en-US'}) {
    _buffer.write('<?xml version="1.0" encoding="UTF-8"?>');
    _buffer.write('<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="$language">');
    _hasStarted = true;
    return this;
  }

  /// Add voice element
  SSMLBuilder voice(String voiceName, String text) {
    _buffer.write('<voice name="$voiceName">$text</voice>');
    return this;
  }

  /// Add prosody element
  SSMLBuilder prosody(String text, {String? rate, String? pitch, String? volume}) {
    _buffer.write('<prosody');
    if (rate != null) _buffer.write(' rate="$rate"');
    if (pitch != null) _buffer.write(' pitch="$pitch"');
    if (volume != null) _buffer.write(' volume="$volume"');
    _buffer.write('>$text</prosody>');
    return this;
  }

  /// Add emphasis element
  SSMLBuilder emphasis(String text, {String level = 'moderate'}) {
    _buffer.write('<emphasis level="$level">$text</emphasis>');
    return this;
  }

  /// Add break element
  SSMLBuilder pause({String? time, String? strength}) {
    _buffer.write('<break');
    if (time != null) _buffer.write(' time="$time"');
    if (strength != null) _buffer.write(' strength="$strength"');
    _buffer.write('/>');
    return this;
  }

  /// Add raw text
  SSMLBuilder text(String text) {
    _buffer.write(_escapeXml(text));
    return this;
  }

  /// Build final SSML string
  String build() {
    if (!_hasStarted) {
      start();
    }
    _buffer.write('</speak>');
    return _buffer.toString();
  }

  /// Escape XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Clear the builder
  void clear() {
    _buffer.clear();
    _hasStarted = false;
  }
}

/// Validate SSML content
bool validateSSML(String ssml) {
  try {
    // Basic validation - check if it's well-formed XML
    if (!ssml.contains('<speak') || !ssml.contains('</speak>')) {
      return false;
    }
    
    // Check for balanced tags (simplified)
    final openTags = RegExp(r'<(\w+)').allMatches(ssml);
    final closeTags = RegExp(r'</(\w+)>').allMatches(ssml);
    
    // This is a very basic check - in production you'd want proper XML validation
    return openTags.length >= closeTags.length;
  } catch (e) {
    return false;
  }
}

/// SSML utility functions
class SSMLUtils {
  /// Create simple SSML from text and voice
  static String createSimpleSSML(String text, String voiceName, {String language = 'en-US'}) {
    return SSMLBuilder()
        .start(language: language)
        .voice(voiceName, text)
        .build();
  }

  /// Create SSML with prosody
  static String createProsodySSML(String text, String voiceName, {
    String language = 'en-US',
    String? rate,
    String? pitch,
    String? volume,
  }) {
    return SSMLBuilder()
        .start(language: language)
        .voice(voiceName, '')
        .prosody(text, rate: rate, pitch: pitch, volume: volume)
        .build();
  }

  /// Create SSML with emphasis
  static String createEmphasisSSML(String text, String voiceName, {
    String language = 'en-US',
    String level = 'moderate',
  }) {
    return SSMLBuilder()
        .start(language: language)
        .voice(voiceName, '')
        .emphasis(text, level: level)
        .build();
  }

  /// Extract text content from SSML
  static String extractTextFromSSML(String ssml) {
    // Remove XML tags and return plain text
    return ssml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }
}