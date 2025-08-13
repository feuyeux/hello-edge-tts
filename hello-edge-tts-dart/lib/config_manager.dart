import 'dart:io';
import 'dart:convert';

/// TTS Configuration class
class TTSConfig {
  final String defaultVoice;
  final String defaultFormat;
  final String defaultRate;
  final String defaultPitch;
  final String defaultVolume;
  final String outputDirectory;
  final bool enableCaching;
  final bool enablePlayback;

  const TTSConfig({
    this.defaultVoice = 'en-US-AriaNeural',
    this.defaultFormat = 'mp3',
    this.defaultRate = 'medium',
    this.defaultPitch = 'medium',
    this.defaultVolume = 'medium',
    this.outputDirectory = 'output',
    this.enableCaching = true,
    this.enablePlayback = false,
  });

  factory TTSConfig.fromJson(Map<String, dynamic> json) {
    return TTSConfig(
      defaultVoice: json['defaultVoice'] ?? 'en-US-AriaNeural',
      defaultFormat: json['defaultFormat'] ?? 'mp3',
      defaultRate: json['defaultRate'] ?? 'medium',
      defaultPitch: json['defaultPitch'] ?? 'medium',
      defaultVolume: json['defaultVolume'] ?? 'medium',
      outputDirectory: json['outputDirectory'] ?? 'output',
      enableCaching: json['enableCaching'] ?? true,
      enablePlayback: json['enablePlayback'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultVoice': defaultVoice,
      'defaultFormat': defaultFormat,
      'defaultRate': defaultRate,
      'defaultPitch': defaultPitch,
      'defaultVolume': defaultVolume,
      'outputDirectory': outputDirectory,
      'enableCaching': enableCaching,
      'enablePlayback': enablePlayback,
    };
  }

  TTSConfig copyWith({
    String? defaultVoice,
    String? defaultFormat,
    String? defaultRate,
    String? defaultPitch,
    String? defaultVolume,
    String? outputDirectory,
    bool? enableCaching,
    bool? enablePlayback,
  }) {
    return TTSConfig(
      defaultVoice: defaultVoice ?? this.defaultVoice,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultRate: defaultRate ?? this.defaultRate,
      defaultPitch: defaultPitch ?? this.defaultPitch,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      enableCaching: enableCaching ?? this.enableCaching,
      enablePlayback: enablePlayback ?? this.enablePlayback,
    );
  }
}

/// Configuration manager for TTS settings
class ConfigManager {
  static const String _defaultConfigFile = 'tts_config.json';

  /// Load configuration from file
  Future<TTSConfig> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const TTSConfig();
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return TTSConfig.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  /// Save configuration to file
  Future<void> saveToFile(TTSConfig config, String filePath) async {
    try {
      final file = File(filePath);
      final json = jsonEncode(config.toJson());
      await file.writeAsString(json);
    } catch (e) {
      throw Exception('Failed to save configuration: $e');
    }
  }

  /// Load default configuration
  Future<TTSConfig> loadDefault() async {
    return loadFromFile(_defaultConfigFile);
  }

  /// Save as default configuration
  Future<void> saveDefault(TTSConfig config) async {
    return saveToFile(config, _defaultConfigFile);
  }
}