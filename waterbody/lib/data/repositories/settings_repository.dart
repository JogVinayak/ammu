import 'package:flutter/material.dart';
import '../local/shared_prefs_service.dart';
import '../models/reminder_settings.dart';
import '../models/sound_option.dart';

class SettingsRepository {
  final SharedPrefsService _prefsService;

  SettingsRepository(this._prefsService);

  // Get current settings
  ReminderSettings getSettings() {
    return _prefsService.getSettings();
  }

  // Save settings
  Future<void> saveSettings(ReminderSettings settings) async {
    await _prefsService.saveSettings(settings);
  }

  // Update specific setting
  Future<ReminderSettings> updateIsEnabled(bool isEnabled) async {
    final settings = getSettings().copyWith(isEnabled: isEnabled);
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateInterval(int minutes) async {
    final settings = getSettings().copyWith(intervalMinutes: minutes);
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateActiveHours(TimeOfDay start, TimeOfDay end) async {
    final settings = getSettings().copyWith(
      activeStartTime: start,
      activeEndTime: end,
    );
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateSound(String soundId, {String? customPath}) async {
    final settings = getSettings().copyWith(
      selectedSoundId: soundId,
      customSoundPath: customPath,
    );
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateVibration(bool enabled) async {
    final settings = getSettings().copyWith(vibrationEnabled: enabled);
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateDailyGoal(int goalMl) async {
    final settings = getSettings().copyWith(dailyGoalMl: goalMl);
    await saveSettings(settings);
    return settings;
  }

  Future<ReminderSettings> updateGlassSize(int sizeMl) async {
    final settings = getSettings().copyWith(defaultGlassSizeMl: sizeMl);
    await saveSettings(settings);
    return settings;
  }

  // Theme mode
  int getThemeMode() {
    return _prefsService.getThemeMode();
  }

  Future<void> setThemeMode(int mode) async {
    await _prefsService.setThemeMode(mode);
  }

  // Onboarding
  bool isOnboardingComplete() {
    return _prefsService.isOnboardingComplete();
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefsService.setOnboardingComplete(complete);
  }

  // Custom sound
  Future<void> saveCustomSound(SoundOption? sound) async {
    await _prefsService.saveCustomSound(sound);
  }

  SoundOption? getCustomSound() {
    return _prefsService.getCustomSound();
  }

  // Last reminder time
  DateTime? getLastReminderTime() {
    return _prefsService.getLastReminderTime();
  }

  Future<void> setLastReminderTime(DateTime time) async {
    await _prefsService.setLastReminderTime(time);
  }
}
