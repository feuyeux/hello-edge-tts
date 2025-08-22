#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../lib/hello_tts.dart';

/// Language configuration structure
class LanguageConfig {
  final String code;
  final String name;
  final String flag;
  final String text;
  final String voice;
  final String? altVoice;

  LanguageConfig({
    required this.code,
    required this.name,
    required this.flag,
    required this.text,
    required this.voice,
    this.altVoice,
  });

  factory LanguageConfig.fromJson(Map<String, dynamic> json) {
    return LanguageConfig(
      code: json['code'] as String,
      name: json['name'] as String,
      flag: json['flag'] as String,
      text: json['text'] as String,
      voice: json['voice'] as String,
      altVoice: json['alt_voice'] as String?,
    );
  }
}

/// Load language configuration from JSON file
Future<List<LanguageConfig>> loadLanguageConfig() async {
  const configPath = '../shared/multilingual_demo_config.json';
  
  try {
    final file = File(configPath);
    if (!await file.exists()) {
      print('❌ Configuration file not found: $configPath');
      return [];
    }

    final content = await file.readAsString();
    final Map<String, dynamic> config = json.decode(content);
    final List<dynamic> languagesJson = config['languages'] ?? [];

    return languagesJson
        .map((lang) => LanguageConfig.fromJson(lang as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('❌ Error loading configuration: $e');
    return [];
  }
}

/// Create output directory if it doesn't exist
Future<void> createOutputDirectory(String directory) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

/// Generate audio for a single language
Future<bool> generateAudioForLanguage(
  TTSClient client,
  LanguageConfig languageConfig,
  String outputDir, {
  bool playAudio = false,
}) async {
  final langCode = languageConfig.code;
  final langName = languageConfig.name;
  final flag = languageConfig.flag;
  final text = languageConfig.text;
  final voice = languageConfig.voice;
  final altVoice = languageConfig.altVoice;

  print('\n$flag $langName (${langCode.toUpperCase()})');
  print('Text: $text');
  print('Voice: $voice');

  try {
    // Try primary voice first
    Uint8List? audioData;
    String usedVoice = voice;

    try {
      audioData = await client.synthesizeText(text, voice);
    } catch (e) {
      print('Primary voice failed: $e');
      if (altVoice != null) {
        print('Trying alternative voice: $altVoice');
        try {
          audioData = await client.synthesizeText(text, altVoice);
          usedVoice = altVoice;
        } catch (e2) {
          print('Alternative voice also failed: $e2');
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    // Generate filename
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final langPrefix = langCode.split('-')[0]; // e.g., 'zh' from 'zh-cn'
    final filename = 'multilingual_${langPrefix}_dart_$timestamp.mp3';
    final outputPath = path.join(outputDir, filename);

    // Save audio
    final file = File(outputPath);
    await file.writeAsBytes(audioData);

    print('✅ Generated: $filename');
    print('📁 Saved to: $outputPath');
    print('🎤 Used voice: $usedVoice');

    // Play audio if requested
    if (playAudio) {
      try {
        print('🔊 Playing audio...');
        final player = AudioPlayer();
        await player.play(outputPath);
        print('✅ Playback completed');
      } catch (e) {
        print('⚠️  Could not play audio: $e');
      }
    }

    return true;
  } catch (e) {
    print('❌ Failed to generate audio for $langName: $e');
    return false;
  }
}

/// Main function for multilingual demo
Future<void> main() async {
  print('🌍 Multilingual Edge TTS Demo - Dart Implementation');
  print('=' * 60);
  print('Generating audio for 12 languages with custom sentences...');

  // Load language configuration
  final languages = await loadLanguageConfig();
  if (languages.isEmpty) {
    print('❌ Failed to load language configuration or no languages found');
    exit(1);
  }

  print('📋 Found ${languages.length} languages to process');

  // Create output directory
  const outputDir = 'output';
  await createOutputDirectory(outputDir);
  final outputPath = path.absolute(outputDir);
  print('📁 Output directory: $outputPath');

  // Initialize TTS client
  late TTSClient client;
  try {
    client = TTSClient();
    print('✅ TTS client initialized');
  } catch (e) {
    print('❌ Failed to initialize TTS client: $e');
    exit(1);
  }

  // Process each language
  int successfulCount = 0;
  int failedCount = 0;
  final startTime = DateTime.now();

  for (int i = 0; i < languages.length; i++) {
    final languageConfig = languages[i];
    print('\n📍 Processing language ${i + 1}/${languages.length}');

    final success = await generateAudioForLanguage(
      client,
      languageConfig,
      outputDir,
      playAudio: false, // Set to true if you want to play each audio
    );

    if (success) {
      successfulCount++;
    } else {
      failedCount++;
    }

    // Small delay between languages to be polite to the service
    if (i < languages.length - 1) {
      print('⏳ Waiting before next language...');
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // Summary
  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  print('\n🏁 Processing Complete!');
  print('=' * 40);
  print('✅ Successful: $successfulCount');
  print('❌ Failed: $failedCount');
  print('⏱️  Total time: ${duration.inSeconds}.${duration.inMilliseconds % 1000} seconds');
  print('📁 Output files saved in: $outputPath');

  if (successfulCount > 0) {
    print('\n🎉 Successfully generated audio files for $successfulCount languages!');
    print('You can find all generated MP3 files in the output directory.');
  }

  exit(failedCount == 0 ? 0 : 1);
}