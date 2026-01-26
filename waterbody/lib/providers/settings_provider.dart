import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../data/models/reminder_settings.dart';
import '../data/models/sound_option.dart';
import '../data/repositories/settings_repository.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  late final AlarmService? _alarmService;
  late final NotificationService? _notificationService;
  // SoundService works on web for previewing sounds
  final SoundService _soundService = SoundService();

  ReminderSettings _settings = const ReminderSettings();
  SoundOption? _customSound;
  int _themeMode = 0; // 0: system, 1: light, 2: dark
  bool _isOnboardingComplete = false;

  SettingsProvider(this._repository) {
    // Only initialize platform-specific services on non-web
    if (!kIsWeb) {
      _alarmService = AlarmService();
      _notificationService = NotificationService();
    } else {
      _alarmService = null;
      _notificationService = null;
    }
    _loadSettings();
  }

  // Getters
  ReminderSettings get settings => _settings;
  SoundOption? get customSound => _customSound;
  int get themeMode => _themeMode;
  bool get isOnboardingComplete => _isOnboardingComplete;

  // Theme mode as ThemeMode enum
  ThemeMode get themeModeEnum {
    switch (_themeMode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Get selected sound
  SoundOption get selectedSound {
    if (_settings.selectedSoundId.startsWith('custom') && _customSound != null) {
      return _customSound!;
    }
    return SoundOption.getById(_settings.selectedSoundId) ?? SoundOption.defaultSound;
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    _settings = _repository.getSettings();
    _customSound = _repository.getCustomSound();
    _themeMode = _repository.getThemeMode();
    _isOnboardingComplete = _repository.isOnboardingComplete();
    notifyListeners();
  }

  // Update reminder enabled
  Future<void> setReminderEnabled(bool enabled) async {
    _settings = await _repository.updateIsEnabled(enabled);
    await _updateAlarm();
    notifyListeners();
  }

  // Update interval
  Future<void> setInterval(int minutes) async {
    _settings = await _repository.updateInterval(minutes);
    await _updateAlarm();
    notifyListeners();
  }

  // Update active hours
  Future<void> setActiveHours(TimeOfDay start, TimeOfDay end) async {
    _settings = await _repository.updateActiveHours(start, end);
    await _updateAlarm();
    notifyListeners();
  }

  // Update sound
  Future<void> setSound(SoundOption sound) async {
    if (sound.isCustom) {
      await _repository.saveCustomSound(sound);
      _customSound = sound;
    }
    
    _settings = await _repository.updateSound(
      sound.id,
      customPath: sound.isCustom ? sound.filePath : null,
    );
    notifyListeners();
  }

  // Update vibration
  Future<void> setVibration(bool enabled) async {
    _settings = await _repository.updateVibration(enabled);
    notifyListeners();
  }

  // Update daily goal
  Future<void> setDailyGoal(int goalMl) async {
    _settings = await _repository.updateDailyGoal(goalMl);
    notifyListeners();
  }

  // Update glass size
  Future<void> setGlassSize(int sizeMl) async {
    _settings = await _repository.updateGlassSize(sizeMl);
    notifyListeners();
  }

  // Update theme mode
  Future<void> setThemeMode(int mode) async {
    _themeMode = mode;
    await _repository.setThemeMode(mode);
    notifyListeners();
  }

  // Set onboarding complete
  Future<void> setOnboardingComplete(bool complete) async {
    _isOnboardingComplete = complete;
    await _repository.setOnboardingComplete(complete);
    notifyListeners();
  }

  // Preview a sound (works on web!)
  Future<void> previewSound(SoundOption sound) async {
    await _soundService.playSound(sound);
  }

  // Stop sound preview
  Future<void> stopSoundPreview() async {
    await _soundService.stopSound();
  }

  // Pick custom sound (not on web)
  Future<SoundOption?> pickCustomSound() async {
    return await _soundService.pickCustomSound();
  }

  // Update alarm based on settings
  Future<void> _updateAlarm() async {
    if (_alarmService == null) return;
    
    if (_settings.isEnabled) {
      await _alarmService!.startReminder(_settings);
    } else {
      await _alarmService!.stopReminder();
    }
  }

  // Get next reminder time
  DateTime? get nextReminderTime {
    if (_alarmService == null) return null;
    return _alarmService!.getNextReminderTime(_settings);
  }

  // Initialize services
  Future<void> initServices() async {
    // Sound service works on all platforms
    await _soundService.init();
    
    if (kIsWeb) return;
    
    await _notificationService?.init();
    await _alarmService?.init();

    // Start reminder if enabled
    if (_settings.isEnabled) {
      await _alarmService?.startReminder(_settings);
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (_notificationService == null) return true;
    return await _notificationService!.requestPermissions();
  }

  // Test notification
  Future<void> testNotification() async {
    if (kIsWeb) {
      // On web, just play the sound
      await _soundService.playSoundById(
        _settings.selectedSoundId,
        customPath: _settings.customSoundPath,
      );
      return;
    }
    
    await _notificationService?.showTestNotification();
    await _soundService.playSoundById(
      _settings.selectedSoundId,
      customPath: _settings.customSoundPath,
    );
  }
}
