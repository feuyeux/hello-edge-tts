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
    });
    
    test('Voice model works correctly', () {
      const voice = Voice(
        name: 'en-US-AriaNeural',
        displayName: 'Aria',
        locale: 'en-US',
        gender: 'Female',
        language: 'en-US',
      );
      
      expect(voice.name, equals('en-US-AriaNeural'));
      expect(voice.displayName, equals('Aria'));
      expect(voice.locale, equals('en-US'));
      expect(voice.gender, equals('Female'));
      expect(voice.language, equals('en-US'));
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
    
    tearDown(() {
      client.dispose();
    });
  });
}