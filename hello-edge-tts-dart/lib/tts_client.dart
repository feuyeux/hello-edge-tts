import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'hello_tts.dart';

/// TTS Client for Microsoft Edge TTS service
class TTSClient {
  static const String _baseUrl = 'https://speech.platform.bing.com';
  static const String _voicesUrl = '$_baseUrl/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  
  final http.Client _httpClient;
  List<Voice>? _cachedVoices;

  TTSClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Get list of available voices
  Future<List<Voice>> getVoices() async {
    if (_cachedVoices != null) {
      return _cachedVoices!;
    }

    try {
      final response = await _httpClient.get(
        Uri.parse(_voicesUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> voicesJson = json.decode(response.body);
        _cachedVoices = voicesJson.map((v) => Voice.fromJson(v)).toList();
        return _cachedVoices!;
      } else {
        throw TTSError('Failed to fetch voices: ${response.statusCode}');
      }
    } catch (e) {
      throw TTSError('Error fetching voices: $e');
    }
  }

  /// Synthesize text to speech
  Future<Uint8List> synthesizeText(String text, String voiceName, {String format = 'mp3'}) async {
    final ssml = _buildSSML(text, voiceName);
    return synthesizeSSML(ssml, voiceName, format: format);
  }

  /// Synthesize SSML to speech
  Future<Uint8List> synthesizeSSML(String ssml, String voiceName, {String format = 'mp3'}) async {
    try {
      // This is a simplified implementation
      // In a real implementation, you would use WebSocket connection to Edge TTS service
      // For now, we'll return a placeholder
      throw TTSError('TTS synthesis not implemented in this demo version');
    } catch (e) {
      throw TTSError('Error during synthesis: $e');
    }
  }

  /// Build SSML from plain text
  String _buildSSML(String text, String voiceName) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
  <voice name="$voiceName">$text</voice>
</speak>''';
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}