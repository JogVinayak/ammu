import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_settings.dart';
import '../models/sound_option.dart';

class SharedPrefsService {
  static SharedPrefsService? _instance;
  static SharedPreferences? _prefs;

  SharedPrefsService._();

  static Future<SharedPrefsService> getInstance() async {
    _instance ??= SharedPrefsService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Keys
  static const String _keySettings = 'reminder_settings';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyCustomSound = 'custom_sound';
  static const String _keyLastReminderTime = 'last_reminder_time';

  // Settings
  Future<void> saveSettings(ReminderSettings settings) async {
    final json = jsonEncode(settings.toJson());
    await _prefs!.setString(_keySettings, json);
  }

  ReminderSettings getSettings() {
    final json = _prefs!.getString(_keySettings);
    if (json == null) {
      return const ReminderSettings();
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ReminderSettings.fromJson(map);
    } catch (_) {
      return const ReminderSettings();
    }
  }

  // Onboarding
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs!.setBool(_keyOnboardingComplete, complete);
  }

  bool isOnboardingComplete() {
    return _prefs!.getBool(_keyOnboardingComplete) ?? false;
  }

  // Theme Mode (0: system, 1: light, 2: dark)
  Future<void> setThemeMode(int mode) async {
    await _prefs!.setInt(_keyThemeMode, mode);
  }

  int getThemeMode() {
    return _prefs!.getInt(_keyThemeMode) ?? 0;
  }

  // Custom Sound
  Future<void> saveCustomSound(SoundOption? sound) async {
    if (sound == null) {
      await _prefs!.remove(_keyCustomSound);
    } else {
      final json = jsonEncode(sound.toJson());
      await _prefs!.setString(_keyCustomSound, json);
    }
  }

  SoundOption? getCustomSound() {
    final json = _prefs!.getString(_keyCustomSound);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SoundOption.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Last Reminder Time
  Future<void> setLastReminderTime(DateTime time) async {
    await _prefs!.setString(_keyLastReminderTime, time.toIso8601String());
  }

  DateTime? getLastReminderTime() {
    final timeStr = _prefs!.getString(_keyLastReminderTime);
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      return null;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs!.clear();
  }
}
