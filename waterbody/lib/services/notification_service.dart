import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/constants/app_strings.dart';
import '../data/models/reminder_settings.dart';
import '../core/utils/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'water_reminder_channel';
  static const String _channelName = 'Water Reminders';
  static const String _channelDescription = 'Notifications for water drinking reminders';

  static const int _reminderNotificationId = 1;

  bool _isInitialized = false;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create notification channel for Android
    if (_isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to app
    debugPrint('Notification tapped: ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap
    debugPrint('Background notification tapped: ${response.payload}');
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    if (_isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (_isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  // Check if permissions are granted
  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    
    if (_isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  // Schedule recurring reminder
  Future<void> scheduleReminder(ReminderSettings settings) async {
    if (kIsWeb) return;
    
    // Cancel existing reminders first
    await cancelAllReminders();

    if (!settings.isEnabled) return;

    // Calculate next reminder time
    final nextReminderTime = _calculateNextReminderTime(settings);
    if (nextReminderTime == null) return;

    // Schedule the notification
    await _scheduleNotification(
      id: _reminderNotificationId,
      title: AppStrings.reminderTitle,
      body: AppStrings.reminderBody,
      scheduledTime: nextReminderTime,
      settings: settings,
    );
  }

  DateTime? _calculateNextReminderTime(ReminderSettings settings) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // Check if we're within active hours
    if (!Helpers.isWithinActiveHours(
      currentTime,
      settings.activeStartTime,
      settings.activeEndTime,
    )) {
      // Schedule for start of next active period
      var nextStart = DateTime(
        now.year,
        now.month,
        now.day,
        settings.activeStartTime.hour,
        settings.activeStartTime.minute,
      );

      // If we're past today's start time, schedule for tomorrow
      if (now.isAfter(nextStart)) {
        nextStart = nextStart.add(const Duration(days: 1));
      }

      return nextStart;
    }

    // Schedule for the next interval
    return now.add(Duration(minutes: settings.intervalMinutes));
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required ReminderSettings settings,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: settings.vibrationEnabled,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: const BigTextStyleInformation(''),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'drink',
          AppStrings.markAsDrunk,
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          AppStrings.snooze,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      AppStrings.reminderTitle,
      AppStrings.reminderBody,
      details,
    );
  }

  // Cancel all reminders
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  // Cancel specific reminder
  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }
}
