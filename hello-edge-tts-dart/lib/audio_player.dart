import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

/// Simple audio player for cross-platform audio playback
class AudioPlayer {
  /// Play audio file
  Future<void> play(String filePath) async {
    if (!File(filePath).existsSync()) {
      throw Exception('Audio file not found: $filePath');
    }

    try {
      // Try different audio players based on platform
      if (Platform.isLinux) {
        await _playOnLinux(filePath);
      } else if (Platform.isMacOS) {
        await _playOnMacOS(filePath);
      } else if (Platform.isWindows) {
        await _playOnWindows(filePath);
      } else {
        throw Exception('Unsupported platform for audio playback');
      }
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Play audio from bytes
  Future<void> playBytes(Uint8List audioData, {String format = 'mp3'}) async {
    // Create temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File(path.join(tempDir.path, 'temp_audio.$format'));
    
    try {
      await tempFile.writeAsBytes(audioData);
      await play(tempFile.path);
    } finally {
      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _playOnLinux(String filePath) async {
    // Try different Linux audio players
    final players = ['paplay', 'aplay', 'mpg123', 'ffplay'];
    
    for (final player in players) {
      try {
        final result = await Process.run('which', [player]);
        if (result.exitCode == 0) {
          final playResult = await Process.run(player, [filePath]);
          if (playResult.exitCode == 0) {
            return;
          }
        }
      } catch (e) {
        // Try next player
        continue;
      }
    }
    
    throw Exception('No suitable audio player found on Linux');
  }

  Future<void> _playOnMacOS(String filePath) async {
    final result = await Process.run('afplay', [filePath]);
    if (result.exitCode != 0) {
      throw Exception('Failed to play audio on macOS: ${result.stderr}');
    }
  }

  Future<void> _playOnWindows(String filePath) async {
    final result = await Process.run('powershell', [
      '-c',
      '(New-Object Media.SoundPlayer "$filePath").PlaySync()'
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to play audio on Windows: ${result.stderr}');
    }
  }
}