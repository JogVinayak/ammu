import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../data/models/sound_option.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Initialize
  Future<void> init() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  // Play a sound (works on web too!)
  Future<void> playSound(SoundOption sound) async {
    try {
      await stopSound();

      if (sound.type == SoundType.builtin && sound.assetPath != null) {
        // Play from assets - works on web
        final assetPath = sound.assetPath!.replaceFirst('assets/', '');
        debugPrint('Playing sound: $assetPath');
        await _audioPlayer.play(AssetSource(assetPath));
      } else if (sound.type == SoundType.custom && sound.filePath != null) {
        // Play from file (not supported on web)
        if (!kIsWeb) {
          await _audioPlayer.play(DeviceFileSource(sound.filePath!));
        }
      }

      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  // Play sound by ID
  Future<void> playSoundById(String soundId, {String? customPath}) async {
    final sound = SoundOption.getById(soundId);
    if (sound != null) {
      await playSound(sound);
    } else if (customPath != null && !kIsWeb) {
      await playSound(SoundOption(
        id: 'custom',
        name: 'Custom',
        filePath: customPath,
        type: SoundType.custom,
      ));
    }
  }

  // Stop playing
  Future<void> stopSound() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }

  // Pause playing
  Future<void> pauseSound() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  // Resume playing
  Future<void> resumeSound() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  // Check if playing
  bool get isPlaying => _isPlaying;

  // Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  // Pick a custom sound file from device (not supported on web)
  Future<SoundOption?> pickCustomSound() async {
    if (kIsWeb) return null;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          // Get file name without extension
          final name = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          
          return SoundOption.createCustom(
            filePath: file.path!,
            name: name.isNotEmpty ? name : 'Custom Sound',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking sound file: $e');
    }
    return null;
  }

  // Validate if a file path looks valid
  Future<bool> validateSoundFile(String filePath) async {
    if (kIsWeb) return false;
    
    try {
      // Check if it's a supported audio format
      final extension = filePath.split('.').last.toLowerCase();
      const supportedFormats = ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'];
      
      return supportedFormats.contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Get duration of a sound
  Future<Duration?> getSoundDuration(SoundOption sound) async {
    try {
      if (sound.type == SoundType.builtin && sound.assetPath != null) {
        await _audioPlayer.setSource(AssetSource(sound.assetPath!.replaceFirst('assets/', '')));
      } else if (sound.type == SoundType.custom && sound.filePath != null && !kIsWeb) {
        await _audioPlayer.setSource(DeviceFileSource(sound.filePath!));
      }
      return await _audioPlayer.getDuration();
    } catch (e) {
      debugPrint('Error getting sound duration: $e');
      return null;
    }
  }

  // Dispose
  void dispose() {
    _audioPlayer.dispose();
  }
}
