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
    // Convert to absolute path
    final absolutePath = path.isAbsolute(filePath) ? filePath : path.absolute(filePath);
    
    // Use the most reliable Windows audio playback method
    try {
      // Method 1: Use Windows Media Player via PowerShell (most reliable for MP3)
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -AssemblyName PresentationCore;
        \$player = New-Object System.Windows.Media.MediaPlayer;
        \$player.Open([System.Uri]"$absolutePath");
        \$player.Play();
        Start-Sleep -Seconds 5;
        \$player.Close();
        '''
      ]);
      
      if (result.exitCode == 0) {
        return; // Success
      }
    } catch (e) {
      // Continue to next method
    }
    
    // Method 2: Use system default program
    try {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '/wait',
        '""',
        '"$absolutePath"'
      ]);
      
      if (result.exitCode == 0) {
        // Give some time for the audio to play
        await Future.delayed(Duration(seconds: 3));
        return;
      }
    } catch (e) {
      // Continue to next method
    }
    
    // Method 3: PowerShell direct invocation
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Invoke-Item "$absolutePath"; Start-Sleep -Seconds 3'
      ]);
      
      if (result.exitCode == 0) {
        return;
      }
    } catch (e) {
      // Final fallback failed
    }
    
    throw Exception('Failed to play audio on Windows: All playback methods failed');
  }
}