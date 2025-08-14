import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'hello_tts.dart';

/// TTS Client for Microsoft Edge TTS service
class TTSClient {
  static const String _baseUrl = 'https://speech.platform.bing.com';
  static const String _voicesUrl = '$_baseUrl/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const String _synthesizeUrl = 'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
  
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
      return await _synthesizeViaEdgeTTS(ssml, voiceName, format);
    } catch (e) {
      throw TTSError('Error during synthesis: $e');
    }
  }

  /// Use Python edge-tts library via process execution
  Future<Uint8List> _synthesizeViaEdgeTTS(String ssml, String voiceName, String format) async {
    try {
      // Extract text from SSML for edge-tts command line
      final text = _extractTextFromSSML(ssml);
      
      // Create temporary file for output (use MP3 format)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/tts_output_${DateTime.now().millisecondsSinceEpoch}.mp3');
      
      try {
        // Use edge-tts command line tool
        final result = await Process.run('edge-tts', [
          '--voice', voiceName,
          '--text', text,
          '--write-media', tempFile.path,
        ]);
        
        if (result.exitCode != 0) {
          // Try with python -m edge_tts if direct command fails
          final pythonResult = await Process.run('python', [
            '-m', 'edge_tts',
            '--voice', voiceName,
            '--text', text,
            '--write-media', tempFile.path,
          ]);
          
          if (pythonResult.exitCode != 0) {
            throw TTSError('Edge TTS failed: ${pythonResult.stderr}');
          }
        }
        
        // Read the generated audio file
        if (await tempFile.exists()) {
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        } else {
          throw TTSError('Audio file was not generated');
        }
        
      } finally {
        // Clean up temporary file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
      
    } catch (e) {
      throw TTSError('Failed to synthesize via Edge TTS: $e');
    }
  }

  /// Extract plain text from SSML
  String _extractTextFromSSML(String ssml) {
    // Simple SSML text extraction - remove XML tags
    return ssml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }



  /// Build SSML from plain text
  String _buildSSML(String text, String voiceName) {
    // Extract language from voice name
    final parts = voiceName.split('-');
    final lang = parts.length >= 2 ? '${parts[0]}-${parts[1]}' : 'en-US';
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="$lang">
  <voice name="$voiceName">$text</voice>
</speak>''';
  }

  /// Clear voice cache
  void clearVoiceCache() {
    _cachedVoices = null;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}