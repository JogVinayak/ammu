import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/interval_picker.dart';
import 'sound_picker_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool showIntervalPickerOnLoad;
  
  const SettingsScreen({
    super.key,
    this.showIntervalPickerOnLoad = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasShownIntervalPicker = false;

  @override
  void initState() {
    super.initState();
    _checkShowIntervalPicker();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if we should show the interval picker (when navigating back with flag set)
    if (widget.showIntervalPickerOnLoad && !oldWidget.showIntervalPickerOnLoad) {
      _hasShownIntervalPicker = false;
      _checkShowIntervalPicker();
    }
  }

  void _checkShowIntervalPicker() {
    if (widget.showIntervalPickerOnLoad && !_hasShownIntervalPicker) {
      _hasShownIntervalPicker = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = context.read<SettingsProvider>();
          _showIntervalPicker(context, provider);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradientDark
            : AppColors.backgroundGradientLight,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  AppStrings.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Reminder Section
                  _SectionHeader(title: AppStrings.reminder),
                  const SizedBox(height: 12),
                  _buildReminderSection(context),
                  const SizedBox(height: 24),
                  // Sound Section
                  _SectionHeader(title: AppStrings.sound),
                  const SizedBox(height: 12),
                  _buildSoundSection(context),
                  const SizedBox(height: 24),
                  // Goals Section
                  _SectionHeader(title: AppStrings.goals),
                  const SizedBox(height: 12),
                  _buildGoalsSection(context),
                  const SizedBox(height: 24),
                  // Appearance Section
                  _SectionHeader(title: AppStrings.appearance),
                  const SizedBox(height: 12),
                  _buildAppearanceSection(context),
                  const SizedBox(height: 24),
                  // About Section
                  _SectionHeader(title: AppStrings.about),
                  const SizedBox(height: 12),
                  _buildAboutSection(context),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enable toggle
              SwitchListTile(
                title: Text(
                  AppStrings.reminderEnabled,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                value: settings.isEnabled,
                onChanged: (value) => provider.setReminderEnabled(value),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Interval
              ListTile(
                title: const Text(AppStrings.reminderInterval),
                subtitle: Text(
                  'Every ${Helpers.formatInterval(settings.intervalMinutes)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showIntervalPicker(context, provider),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Active hours
              ListTile(
                title: const Text(AppStrings.activeHours),
                subtitle: Text(
                  '${Helpers.formatTime(settings.activeStartTime)} - ${Helpers.formatTime(settings.activeEndTime)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showActiveHoursPicker(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final selectedSound = provider.selectedSound;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sound picker
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      selectedSound.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: const Text(AppStrings.reminderSound),
                subtitle: Text(
                  selectedSound.name,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => provider.previewSound(selectedSound),
                      icon: const Icon(Icons.play_circle, color: AppColors.primary),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SoundPickerScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Vibration toggle
              SwitchListTile(
                title: Text(
                  AppStrings.vibration,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                value: provider.settings.vibrationEnabled,
                onChanged: (value) => provider.setVibration(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Daily target
              ListTile(
                title: const Text(AppStrings.dailyTarget),
                subtitle: Text(
                  Helpers.formatMl(settings.dailyGoalMl),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGoalPicker(context, provider),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Glass size
              ListTile(
                title: const Text(AppStrings.glassSize),
                subtitle: Text(
                  Helpers.formatMl(settings.defaultGlassSizeMl),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGlassSizePicker(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            title: const Text(AppStrings.theme),
            subtitle: Text(
              _getThemeName(provider.themeMode),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Text('💧', style: TextStyle(fontSize: 24)),
            title: const Text(AppStrings.appName),
            subtitle: Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.favorite, color: AppColors.error),
            title: const Text('Made with love'),
            subtitle: Text(
              'Stay hydrated, stay healthy!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => IntervalPicker(
        currentInterval: provider.settings.intervalMinutes,
        onChanged: (interval) => provider.setInterval(interval),
      ),
    );
  }

  void _showActiveHoursPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ActiveHoursPicker(
        startTime: provider.settings.activeStartTime,
        endTime: provider.settings.activeEndTime,
        onChanged: (start, end) => provider.setActiveHours(start, end),
      ),
    );
  }

  void _showGoalPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => GoalPicker(
        currentGoal: provider.settings.dailyGoalMl,
        onChanged: (goal) => provider.setDailyGoal(goal),
      ),
    );
  }

  void _showGlassSizePicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Glass Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [150, 200, 250, 300, 350, 500]
              .map((size) => ListTile(
                    title: Text(Helpers.formatMl(size)),
                    leading: Radio<int>(
                      value: size,
                      groupValue: provider.settings.defaultGlassSizeMl,
                      onChanged: (value) {
                        if (value != null) {
                          provider.setGlassSize(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    onTap: () {
                      provider.setGlassSize(size);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              icon: Icons.brightness_auto,
              title: 'System',
              isSelected: provider.themeMode == 0,
              onTap: () {
                provider.setThemeMode(0);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              title: 'Light',
              isSelected: provider.themeMode == 1,
              onTap: () {
                provider.setThemeMode(1);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark',
              isSelected: provider.themeMode == 2,
              onTap: () {
                provider.setThemeMode(2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(int mode) {
    switch (mode) {
      case 1:
        return 'Light';
      case 2:
        return 'Dark';
      default:
        return 'System';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}
