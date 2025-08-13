import 'package:test/test.dart';
import '../lib/hello_tts.dart';

void main() {
  group('TTS Client Tests', () {
    late TTSClient client;
    
    setUp(() {
      client = TTSClient();
    });
    
    test('TTSClient can be instantiated', () {
      expect(client, isNotNull);
      expect(client.config, isNotNull);
    });
    
    test('TTSConfig has default values', () {
      final config = TTSConfig();
      expect(config.defaultVoice, equals('en-US-AriaNeural'));
      expect(config.outputFormat, equals('mp3'));
      expect(config.autoPlay, isTrue);
      expect(config.cacheVoices, isTrue);
      expect(config.maxRetries, equals(3));
      expect(config.timeout, equals(30000));
    });
    
    test('Voice model works correctly', () {
      const voice = Voice(
        name: 'en-US-AriaNeural',
        displayName: 'Aria',
        locale: 'en-US',
        gender: 'Female',
      );
      
      expect(voice.name, equals('en-US-AriaNeural'));
      expect(voice.displayName, equals('Aria'));
      expect(voice.locale, equals('en-US'));
      expect(voice.gender, equals('Female'));
      expect(voice.languageCode, equals('en'));
      expect(voice.countryCode, equals('US'));
      expect(voice.matchesLanguage('en'), isTrue);
      expect(voice.matchesLanguage('en-US'), isTrue);
      expect(voice.matchesLanguage('fr'), isFalse);
    });
    
    test('AudioPlayer can be instantiated', () {
      final player = AudioPlayer();
      expect(player, isNotNull);
    });
    
    test('TTSError works correctly', () {
      final error = TTSError('Test error');
      expect(error.message, equals('Test error'));
      expect(error.toString(), equals('TTSError: Test error'));
    });
    
    test('AudioError works correctly', () {
      final error = AudioError('Audio test error');
      expect(error.message, equals('Audio test error'));
      expect(error.toString(), equals('AudioError: Audio test error'));
    });
    
    tearDown(() {
      client.dispose();
    });
  });
}