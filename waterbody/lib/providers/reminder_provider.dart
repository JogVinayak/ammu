import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../data/models/reminder_settings.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../core/utils/helpers.dart';

class ReminderProvider extends ChangeNotifier {
  AlarmService? _alarmService;
  Timer? _countdownTimer;
  final SoundService _soundService = SoundService();
  NotificationService? _notificationService;
  
  DateTime? _nextReminderTime;
  String _countdownText = '--:--';
  bool _isActive = false;
  ReminderSettings? _currentSettings;
  bool _initialized = false;

  ReminderProvider() {
    if (!kIsWeb) {
      _alarmService = AlarmService();
      _notificationService = NotificationService();
    }
    debugPrint('ReminderProvider: Created, kIsWeb=$kIsWeb');
  }

  // Getters
  DateTime? get nextReminderTime => _nextReminderTime;
  String get countdownText => _countdownText;
  bool get isActive => _isActive;

  // Update reminder state
  void updateReminderState(ReminderSettings settings) {
    debugPrint('ReminderProvider: updateReminderState called');
    debugPrint('ReminderProvider: isEnabled=${settings.isEnabled}, interval=${settings.intervalMinutes}');
    
    // Check if interval changed - if so, reset the timer
    final intervalChanged = _currentSettings != null && 
        _currentSettings!.intervalMinutes != settings.intervalMinutes;
    
    _isActive = settings.isEnabled;
    _currentSettings = settings;
    _initialized = true;
    
    if (!_isActive) {
      // If not active, show --:--
      _nextReminderTime = null;
      _countdownText = '--:--';
      _countdownTimer?.cancel();
      notifyListeners();
      return;
    }
    
    // Always recalculate next reminder time when interval changes or on first load
    final now = DateTime.now();
    if (intervalChanged || _nextReminderTime == null) {
      // Reset countdown from now with new interval
      _nextReminderTime = now.add(Duration(minutes: settings.intervalMinutes));
      debugPrint('ReminderProvider: Timer RESET! New countdown: ${settings.intervalMinutes} minutes');
    } else if (_alarmService != null) {
      _nextReminderTime = _alarmService!.getNextReminderTime(settings);
    } else {
      _nextReminderTime = _calculateNextReminderTime(settings);
    }
    
    debugPrint('ReminderProvider: Next reminder at $_nextReminderTime');
    
    _updateCountdown();
    _startCountdownTimer();
    notifyListeners();
  }

  // Calculate next reminder time (for web)
  DateTime? _calculateNextReminderTime(ReminderSettings settings) {
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

  // Start countdown timer - updates every second
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    if (!_isActive || _nextReminderTime == null) {
      _countdownText = '--:--';
      notifyListeners();
      return;
    }

    // Update immediately
    _updateCountdown();

    // Then update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  // Update countdown text with seconds
  void _updateCountdown() {
    if (_nextReminderTime == null) {
      _countdownText = '--:--';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    
    if (_nextReminderTime!.isBefore(now)) {
      _countdownText = '00:00';
      
      // RING THE BELL when timer finishes!
      _triggerReminder();
      
      // Reset to next interval if we have settings
      if (_currentSettings != null) {
        _nextReminderTime = now.add(Duration(minutes: _currentSettings!.intervalMinutes));
        debugPrint('ReminderProvider: Timer reset, next at $_nextReminderTime');
      }
      
      notifyListeners();
      return;
    }

    // Show countdown with seconds (MM:SS or HH:MM:SS)
    _countdownText = Helpers.getRemainingTime(_nextReminderTime!, showSeconds: true);
    notifyListeners();
  }

  // Trigger reminder - play sound and show notification
  Future<void> _triggerReminder() async {
    if (_currentSettings == null) return;
    
    debugPrint('ReminderProvider: 🔔 TRIGGERING REMINDER!');
    
    // Check if within active hours
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    if (!Helpers.isWithinActiveHours(
      currentTime,
      _currentSettings!.activeStartTime,
      _currentSettings!.activeEndTime,
    )) {
      debugPrint('ReminderProvider: Outside active hours, skipping bell');
      return;
    }
    
    // Play the reminder sound
    await _soundService.playSoundById(
      _currentSettings!.selectedSoundId,
      customPath: _currentSettings!.customSoundPath,
    );
    
    // Show notification (on mobile only)
    if (!kIsWeb && _notificationService != null) {
      await _notificationService!.showTestNotification();
    }
  }

  // Format next reminder time
  String get formattedNextReminderTime {
    if (_nextReminderTime == null) return '--:--';
    return Helpers.formatDateTime(_nextReminderTime!);
  }

  // Dispose
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
