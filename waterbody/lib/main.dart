import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/local/shared_prefs_service.dart';
import 'data/models/water_intake.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/intake_repository.dart';
import 'providers/settings_provider.dart';
import 'providers/intake_provider.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (not supported on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(WaterIntakeAdapter());

  // Initialize services
  final prefsService = await SharedPrefsService.getInstance();
  
  // Initialize platform-specific services (not on web)
  if (!kIsWeb) {
    final notificationService = NotificationService();
    await notificationService.init();

    final alarmService = AlarmService();
    await alarmService.init();
  }

  // Initialize repositories
  final settingsRepository = SettingsRepository(prefsService);
  final intakeRepository = IntakeRepository();
  await intakeRepository.init();

  // Initialize providers
  final settingsProvider = SettingsProvider(settingsRepository);
  final intakeProvider = IntakeProvider(
    intakeRepository,
    () => settingsProvider.settings.dailyGoalMl,
  );

  runApp(
    AppProviders(
      settingsProvider: settingsProvider,
      intakeProvider: intakeProvider,
      child: const AquaReminderApp(),
    ),
  );
}
