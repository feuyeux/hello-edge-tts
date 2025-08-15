#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../lib/hello_tts.dart';

/// SSML examples for different speech modifications
const Map<String, String> ssmlExamples = {
  'rate': '<speak><prosody rate="slow">This is spoken slowly.</prosody> <prosody rate="fast">This is spoken quickly.</prosody></speak>',
  'pitch': '<speak><prosody pitch="high">This is high pitch.</prosody> <prosody pitch="low">This is low pitch.</prosody></speak>',
  'volume': '<speak><prosody volume="loud">This is loud.</prosody> <prosody volume="soft">This is soft.</prosody></speak>',
  'emphasis': '<speak>This is <emphasis level="strong">strongly emphasized</emphasis> text.</speak>',
  'break': '<speak>This sentence has a <break time="2s"/> two second pause.</speak>',
  'mixed': '<speak><prosody rate="slow" pitch="low">Slow and low,</prosody> <break time="1s"/> <prosody rate="fast" pitch="high">fast and high!</prosody></speak>'
};

/// Sample texts in different languages
const Map<String, String> multilingualSamples = {
  'en': 'Hello, this is a test of the text-to-speech system.',
  'es': 'Hola, esta es una prueba del sistema de texto a voz.',
  'fr': 'Bonjour, ceci est un test du système de synthèse vocale.',
  'de': 'Hallo, dies ist ein Test des Text-zu-Sprache-Systems.',
  'it': 'Ciao, questo è un test del sistema di sintesi vocale.',
  'pt': 'Olá, este é um teste do sistema de texto para fala.',
  'ja': 'こんにちは、これはテキスト読み上げシステムのテストです。',
  'ko': '안녕하세요, 이것은 텍스트 음성 변환 시스템의 테스트입니다.',
  'zh': '你好，这是文本转语音系统的测试。'
};

/// Create output directory if it doesn't exist
Future<void> createOutputDirectory(String directory) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

/// Generate a safe filename from text
String getSafeFilename(String text, {int maxLength = 50}) {
  // Remove or replace unsafe characters
  const safeChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_. ';
  final filename = text.split('').map((c) => safeChars.contains(c) ? c : '_').join('');
  
  // Truncate if too long
  final truncated = filename.length > maxLength ? filename.substring(0, maxLength) : filename;
  
  // Remove trailing spaces and dots
  return truncated.replaceAll(RegExp(r'[\s.]+$'), '');
}

/// Display available voices grouped by language
Future<void> displayVoicesByLanguage(TTSClient client, {String? filterLanguage}) async {
  try {
    final voices = await client.getVoices();
    
    // Group voices by language
    final Map<String, List<Voice>> voicesByLanguage = <String, List<Voice>>{};
    
    for (final voice in voices) {
      final lang = voice.language;
      voicesByLanguage.putIfAbsent(lang, () => []).add(voice);
    }
    
    if (filterLanguage != null) {
      if (voicesByLanguage.containsKey(filterLanguage)) {
        final langVoices = voicesByLanguage[filterLanguage]!;
        print('\n${filterLanguage.toUpperCase()} Voices (${langVoices.length} voices):');
        
        // Show first 5 voices
        for (final voice in langVoices.take(5)) {
          print('  ${voice.name} - ${voice.displayName} (${voice.gender})');
        }
        
        if (langVoices.length > 5) {
          print('  ... and ${langVoices.length - 5} more voices');
        }
      } else {
        print('No voices found for language: $filterLanguage');
      }
    } else {
      // Group voices by language
      print('\nAvailable voices by language:');
      
      for (final entry in voicesByLanguage.entries) {
        final lang = entry.key;
        final langVoices = entry.value;
        print('\n${lang.toUpperCase()} (${langVoices.length} voices):');
        
        // Show first 5 voices
        for (final voice in langVoices.take(5)) {
          print('  ${voice.name} - ${voice.displayName} (${voice.gender})');
        }
        
        if (langVoices.length > 5) {
          print('  ... and ${langVoices.length - 5} more voices');
        }
      }
    }
  } catch (e) {
    print('Error displaying voices: $e');
  }
}

/// Run SSML examples
Future<void> runSSMLExamples(TTSClient client, String voice, String outputDir) async {
  print('\n🎵 Running SSML Examples');
  print('========================');
  
  for (final entry in ssmlExamples.entries) {
    final name = entry.key;
    final ssml = entry.value;
    
    try {
      print('\nTesting $name...');
      final audioData = await client.synthesizeSSML(ssml, voice);
      
      final filename = 'edgetts_ssml_${name}_dart_example.mp3';
      final outputPath = path.join(outputDir, filename);
      
      final file = File(outputPath);
      await file.writeAsBytes(audioData);
      
      print('✅ Saved: $outputPath');
      
      // Play audio if possible
      try {
        final player = AudioPlayer();
        await player.play(outputPath);
        print('🔊 Playing audio...');
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('⚠️  Could not play audio: $e');
      }
    } catch (e) {
      print('❌ Error with $name: $e');
    }
  }
}

/// Run multilingual examples
Future<void> runMultilingualExamples(TTSClient client, String outputDir) async {
  print('\n🌍 Running Multilingual Examples');
  print('=================================');
  
  for (final entry in multilingualSamples.entries) {
    final lang = entry.key;
    final text = entry.value;
    
    try {
      print('\nTesting $lang...');
      
      // Get voices for this language
      final voices = await client.getVoices();
      final langVoices = voices.where((v) => v.language.startsWith(lang)).toList();
      
      if (langVoices.isEmpty) {
        print('⚠️  No voices found for language: $lang');
        continue;
      }
      
      final voice = langVoices.first.name;
      print('Using voice: $voice');
      
      final audioData = await client.synthesizeText(text, voice);
      
      final filename = 'edgetts_${lang}_dart_multilingual.mp3';
      final outputPath = path.join(outputDir, filename);
      
      final file = File(outputPath);
      await file.writeAsBytes(audioData);
      
      print('✅ Saved: $outputPath');
      
      // Play audio if possible
      try {
        final player = AudioPlayer();
        await player.play(outputPath);
        print('🔊 Playing audio...');
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('⚠️  Could not play audio: $e');
      }
    } catch (e) {
      print('❌ Error with $lang: $e');
    }
  }
}

/// Main function
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('text', abbr: 't', help: 'Text to synthesize')
    ..addOption('voice', abbr: 'v', help: 'Voice to use', defaultsTo: 'en-US-AriaNeural')
    ..addOption('output', abbr: 'o', help: 'Output file path')
    ..addOption('format', abbr: 'f', help: 'Audio format', defaultsTo: 'mp3', allowed: ['mp3', 'wav', 'ogg'])
    ..addOption('rate', abbr: 'r', help: 'Speech rate', defaultsTo: 'medium')
    ..addOption('pitch', abbr: 'p', help: 'Speech pitch', defaultsTo: 'medium')
    ..addOption('volume', help: 'Speech volume', defaultsTo: 'medium')
    ..addOption('language', abbr: 'l', help: 'Filter voices by language')
    ..addOption('ssml', help: 'SSML text to synthesize')
    ..addOption('config', abbr: 'c', help: 'Configuration file path')
    ..addOption('output-dir', help: 'Output directory for batch operations', defaultsTo: 'output')
    ..addFlag('list-voices', help: 'List available voices', negatable: false)
    ..addFlag('play', help: 'Play audio after synthesis (default: true)', defaultsTo: true)
    ..addFlag('no-play', help: 'Don\'t play audio after synthesis', negatable: false)
    ..addFlag('ssml-examples', help: 'Run SSML examples', negatable: false)
    ..addFlag('multilingual-examples', help: 'Run multilingual examples', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false)
    ..addFlag('verbose', help: 'Verbose output', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Hello Edge TTS - Dart Implementation');
      print('====================================');
      print('');
      print('Usage: dart run bin/main.dart [options]');
      print('');
      print(parser.usage);
      print('');
      print('Examples:');
      print('  dart run bin/main.dart --text "Hello World"');
      print('  dart run bin/main.dart --text "Hello" --voice "en-US-JennyNeural" --output hello.mp3');
      print('  dart run bin/main.dart --list-voices');
      print('  dart run bin/main.dart --list-voices --language en');
      print('  dart run bin/main.dart --ssml-examples');
      print('  dart run bin/main.dart --multilingual-examples');
      return;
    }

    // Initialize TTS client
    final client = TTSClient();
    
    // Load configuration if provided
    if (results['config'] != null) {
      final configManager = ConfigManager();
      await configManager.loadFromFile(results['config'] as String);
      // Apply configuration to client
    }

    // Create output directory
    final outputDir = results['output-dir'] as String;
    await createOutputDirectory(outputDir);

    // List voices
    if (results['list-voices'] as bool) {
      await displayVoicesByLanguage(client, filterLanguage: results['language'] as String?);
      return;
    }

    // Run SSML examples
    if (results['ssml-examples'] as bool) {
      final voice = results['voice'] as String;
      await runSSMLExamples(client, voice, outputDir);
      return;
    }

    // Run multilingual examples
    if (results['multilingual-examples'] as bool) {
      await runMultilingualExamples(client, outputDir);
      return;
    }

    // Synthesize text or SSML
    final text = results['text'] as String?;
    final ssml = results['ssml'] as String?;
    final voice = results['voice'] as String;
    final format = results['format'] as String;
    final play = results['play'] as bool && !(results['no-play'] as bool);

    if (text == null && ssml == null) {
      print('Error: Either --text or --ssml must be provided');
      print('Use --help for usage information');
      exit(1);
    }

    try {
      print('🎤 Synthesizing speech...');
      print('Voice: $voice');
      print('Format: $format');
      
      final Uint8List audioData;
      if (ssml != null) {
        print('SSML: $ssml');
        audioData = await client.synthesizeSSML(ssml, voice, format: format);
      } else {
        print('Text: $text');
        audioData = await client.synthesizeText(text!, voice, format: format);
      }

      // Determine output path
      String outputPath;
      if (results['output'] != null) {
        outputPath = results['output'] as String;
      } else {
        // Extract language from voice (e.g., 'en' from 'en-US-AriaNeural')
        final lang = voice.split('-')[0];
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final filename = 'edgetts_${lang}_dart_$timestamp.mp3';
        outputPath = path.join(outputDir, filename);
      }

      // Save audio file
      final file = File(outputPath);
      await file.writeAsBytes(audioData);
      
      print('✅ Audio saved to: $outputPath');
      print('📊 File size: ${(audioData.length / 1024).toStringAsFixed(1)} KB');

      // Play audio (default behavior, unless --no-play is specified)
      if (play) {
        try {
          print('🔊 Playing audio...');
          final player = AudioPlayer();
          await player.play(outputPath);
          print('✅ Playback completed!');
        } catch (e) {
          print('⚠️  Could not play audio: $e');
          print('💡 Audio file was saved successfully though.');
        }
      }

    } catch (e) {
      print('❌ Error during synthesis: $e');
      exit(1);
    }

  } catch (e) {
    print('❌ Error parsing arguments: $e');
    print('Use --help for usage information');
    exit(1);
  }
}