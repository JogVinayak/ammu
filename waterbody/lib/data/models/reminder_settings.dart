import 'package:flutter/material.dart';

class ReminderSettings {
  final bool isEnabled;
  final int intervalMinutes; // Reminder interval in minutes
  final TimeOfDay activeStartTime; // Start of active hours
  final TimeOfDay activeEndTime; // End of active hours
  final String selectedSoundId; // ID of selected sound
  final String? customSoundPath; // Path to custom sound file (if any)
  final bool vibrationEnabled;
  final int dailyGoalMl; // Daily water goal in ml
  final int defaultGlassSizeMl; // Default glass size in ml

  const ReminderSettings({
    this.isEnabled = true,
    this.intervalMinutes = 60,
    this.activeStartTime = const TimeOfDay(hour: 7, minute: 0),
    this.activeEndTime = const TimeOfDay(hour: 22, minute: 0),
    this.selectedSoundId = 'bell',
    this.customSoundPath,
    this.vibrationEnabled = true,
    this.dailyGoalMl = 2000,
    this.defaultGlassSizeMl = 250,
  });

  ReminderSettings copyWith({
    bool? isEnabled,
    int? intervalMinutes,
    TimeOfDay? activeStartTime,
    TimeOfDay? activeEndTime,
    String? selectedSoundId,
    String? customSoundPath,
    bool? vibrationEnabled,
    int? dailyGoalMl,
    int? defaultGlassSizeMl,
  }) {
    return ReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      activeStartTime: activeStartTime ?? this.activeStartTime,
      activeEndTime: activeEndTime ?? this.activeEndTime,
      selectedSoundId: selectedSoundId ?? this.selectedSoundId,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      defaultGlassSizeMl: defaultGlassSizeMl ?? this.defaultGlassSizeMl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'intervalMinutes': intervalMinutes,
      'activeStartHour': activeStartTime.hour,
      'activeStartMinute': activeStartTime.minute,
      'activeEndHour': activeEndTime.hour,
      'activeEndMinute': activeEndTime.minute,
      'selectedSoundId': selectedSoundId,
      'customSoundPath': customSoundPath,
      'vibrationEnabled': vibrationEnabled,
      'dailyGoalMl': dailyGoalMl,
      'defaultGlassSizeMl': defaultGlassSizeMl,
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      isEnabled: json['isEnabled'] ?? true,
      intervalMinutes: json['intervalMinutes'] ?? 60,
      activeStartTime: TimeOfDay(
        hour: json['activeStartHour'] ?? 7,
        minute: json['activeStartMinute'] ?? 0,
      ),
      activeEndTime: TimeOfDay(
        hour: json['activeEndHour'] ?? 22,
        minute: json['activeEndMinute'] ?? 0,
      ),
      selectedSoundId: json['selectedSoundId'] ?? 'bell',
      customSoundPath: json['customSoundPath'],
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      dailyGoalMl: json['dailyGoalMl'] ?? 2000,
      defaultGlassSizeMl: json['defaultGlassSizeMl'] ?? 250,
    );
  }

  @override
  String toString() {
    return 'ReminderSettings(isEnabled: $isEnabled, intervalMinutes: $intervalMinutes, '
        'activeStartTime: $activeStartTime, activeEndTime: $activeEndTime, '
        'selectedSoundId: $selectedSoundId, customSoundPath: $customSoundPath, '
        'vibrationEnabled: $vibrationEnabled, dailyGoalMl: $dailyGoalMl, '
        'defaultGlassSizeMl: $defaultGlassSizeMl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderSettings &&
        other.isEnabled == isEnabled &&
        other.intervalMinutes == intervalMinutes &&
        other.activeStartTime == activeStartTime &&
        other.activeEndTime == activeEndTime &&
        other.selectedSoundId == selectedSoundId &&
        other.customSoundPath == customSoundPath &&
        other.vibrationEnabled == vibrationEnabled &&
        other.dailyGoalMl == dailyGoalMl &&
        other.defaultGlassSizeMl == defaultGlassSizeMl;
  }

  @override
  int get hashCode {
    return Object.hash(
      isEnabled,
      intervalMinutes,
      activeStartTime,
      activeEndTime,
      selectedSoundId,
      customSoundPath,
      vibrationEnabled,
      dailyGoalMl,
      defaultGlassSizeMl,
    );
  }
}
