import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/settings_provider.dart';
import 'providers/intake_provider.dart';
import 'providers/reminder_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';

class AquaReminderApp extends StatelessWidget {
  const AquaReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.themeModeEnum,
          home: settingsProvider.isOnboardingComplete
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

/// Widget that initializes all providers
class AppProviders extends StatefulWidget {
  final Widget child;
  final SettingsProvider settingsProvider;
  final IntakeProvider intakeProvider;

  const AppProviders({
    super.key,
    required this.child,
    required this.settingsProvider,
    required this.intakeProvider,
  });

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final ReminderProvider _reminderProvider;

  @override
  void initState() {
    super.initState();
    _reminderProvider = ReminderProvider();
    
    // Listen to settings changes and update reminder
    widget.settingsProvider.addListener(_onSettingsChanged);
    
    // Initial update after settings load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reminderProvider.updateReminderState(widget.settingsProvider.settings);
    });
  }

  void _onSettingsChanged() {
    debugPrint('AppProviders: Settings changed, updating reminder');
    debugPrint('AppProviders: New interval = ${widget.settingsProvider.settings.intervalMinutes}');
    _reminderProvider.updateReminderState(widget.settingsProvider.settings);
  }

  @override
  void dispose() {
    widget.settingsProvider.removeListener(_onSettingsChanged);
    _reminderProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsProvider),
        ChangeNotifierProvider.value(value: widget.intakeProvider),
        ChangeNotifierProvider.value(value: _reminderProvider),
      ],
      child: widget.child,
    );
  }
}
