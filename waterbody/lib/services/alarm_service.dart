import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../data/models/reminder_settings.dart';
import '../core/utils/helpers.dart';
import 'notification_service.dart';
import 'sound_service.dart';

// Workmanager callback dispatcher - must be top-level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case AlarmService.reminderTaskName:
        await _handleReminderTask(inputData);
        break;
    }
    return true;
  });
}

Future<void> _handleReminderTask(Map<String, dynamic>? inputData) async {
  // Initialize notification service and show reminder
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.showTestNotification();
}

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  static const String reminderTaskName = 'water_reminder_task';
  static const String reminderUniqueId = 'water_reminder_periodic';

  Timer? _reminderTimer;
  bool _isInitialized = false;

  final NotificationService _notificationService = NotificationService();
  final SoundService _soundService = SoundService();

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Initialize workmanager
  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
  }

  // Start reminder with settings
  Future<void> startReminder(ReminderSettings settings) async {
    if (kIsWeb) return;
    
    if (!settings.isEnabled) {
      await stopReminder();
      return;
    }

    // Cancel any existing reminders
    await stopReminder();

    // Schedule the notification
    await _notificationService.scheduleReminder(settings);

    // For foreground reminders, use a timer
    _startForegroundTimer(settings);

    // For background, use Workmanager
    if (_isAndroid) {
      await _scheduleBackgroundTask(settings);
    }
  }

  void _startForegroundTimer(ReminderSettings settings) {
    if (kIsWeb) return;
    
    _reminderTimer?.cancel();

    // Calculate delay until next reminder
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // Check if within active hours
    if (!Helpers.isWithinActiveHours(
      currentTime,
      settings.activeStartTime,
      settings.activeEndTime,
    )) {
      // Calculate time until active hours start
      var nextStart = DateTime(
        now.year,
        now.month,
        now.day,
        settings.activeStartTime.hour,
        settings.activeStartTime.minute,
      );

      if (now.isAfter(nextStart)) {
        nextStart = nextStart.add(const Duration(days: 1));
      }

      final delay = nextStart.difference(now);
      
      // Set a timer to start checking when active hours begin
      Timer(delay, () => _startForegroundTimer(settings));
      return;
    }

    // Start periodic timer for foreground reminders
    _reminderTimer = Timer.periodic(
      Duration(minutes: settings.intervalMinutes),
      (_) => _triggerReminder(settings),
    );
  }

  Future<void> _triggerReminder(ReminderSettings settings) async {
    if (kIsWeb) return;
    
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // Check if still within active hours
    if (!Helpers.isWithinActiveHours(
      currentTime,
      settings.activeStartTime,
      settings.activeEndTime,
    )) {
      return;
    }

    // Schedule next notification
    await _notificationService.scheduleReminder(settings);

    // Play sound
    await _soundService.playSoundById(
      settings.selectedSoundId,
      customPath: settings.customSoundPath,
    );
  }

  Future<void> _scheduleBackgroundTask(ReminderSettings settings) async {
    if (kIsWeb || !_isAndroid) return;
    
    await Workmanager().registerPeriodicTask(
      reminderUniqueId,
      reminderTaskName,
      frequency: Duration(minutes: settings.intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      inputData: {
        'soundId': settings.selectedSoundId,
        'customSoundPath': settings.customSoundPath,
        'vibration': settings.vibrationEnabled,
      },
    );
  }

  // Stop reminder
  Future<void> stopReminder() async {
    _reminderTimer?.cancel();
    _reminderTimer = null;

    if (!kIsWeb) {
      await Workmanager().cancelByUniqueName(reminderUniqueId);
      await _notificationService.cancelAllReminders();
    }
  }

  // Snooze reminder (5 minutes)
  Future<void> snoozeReminder(ReminderSettings settings, {int minutes = 5}) async {
    if (kIsWeb) return;
    
    // Schedule a one-time notification for snooze
    // This is simplified - in production you'd want more robust handling
    Timer(Duration(minutes: minutes), () => _triggerReminder(settings));
  }

  // Get next reminder time
  DateTime? getNextReminderTime(ReminderSettings settings) {
    if (!settings.isEnabled) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    if (Helpers.isWithinActiveHours(
      currentTime,
      settings.activeStartTime,
      settings.activeEndTime,
    )) {
      return now.add(Duration(minutes: settings.intervalMinutes));
    }

    // Calculate next active period start
    var nextStart = DateTime(
      now.year,
      now.month,
      now.day,
      settings.activeStartTime.hour,
      settings.activeStartTime.minute,
    );

    if (now.isAfter(nextStart)) {
      nextStart = nextStart.add(const Duration(days: 1));
    }

    return nextStart;
  }

  // Dispose
  void dispose() {
    _reminderTimer?.cancel();
    _soundService.dispose();
  }
}
