import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/intake_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../widgets/water_progress.dart';
import '../widgets/quick_add_button.dart';
import '../widgets/next_reminder_card.dart';
import '../widgets/intake_log_list.dart';
import '../../settings/screens/settings_screen.dart';
import '../../history/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _showIntervalPickerOnSettings = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  Future<void> _initServices() async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.initServices();
    
    // Update reminder provider state
    if (mounted) {
      final reminderProvider = context.read<ReminderProvider>();
      reminderProvider.updateReminderState(settingsProvider.settings);
    }
  }

  // Navigate to settings and show interval picker
  void navigateToSettingsWithIntervalPicker() {
    setState(() {
      _showIntervalPickerOnSettings = true;
    });
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Reset the flag after navigating away from settings
            if (index != 2) {
              _showIntervalPickerOnSettings = false;
            }
          });
        },
        children: [
          const _HomeContent(),
          const HistoryScreen(),
          SettingsScreen(showIntervalPickerOnLoad: _showIntervalPickerOnSettings),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.water_drop_outlined,
                activeIcon: Icons.water_drop,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _navigateToPage(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Stats',
                isActive: _currentIndex == 1,
                onTap: () => _navigateToPage(1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                isActive: _currentIndex == 2,
                onTap: () => _navigateToPage(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  void _navigateToSettingsWithIntervalPicker(BuildContext context) {
    // Find the HomeScreen state and navigate to settings with interval picker
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.navigateToSettingsWithIntervalPicker();
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
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<IntakeProvider>().refresh();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: _buildAppBar(context),
              ),
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Water Progress
                    Consumer<IntakeProvider>(
                      builder: (context, provider, _) {
                        return Center(
                          child: WaterProgress(
                            currentMl: provider.todayTotal,
                            goalMl: provider.dailyGoal,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Next Reminder Card
                    Consumer2<SettingsProvider, ReminderProvider>(
                      builder: (context, settings, reminder, _) {
                        return NextReminderCard(
                          countdownText: reminder.countdownText,
                          isActive: settings.settings.isEnabled,
                          onToggle: () async {
                            final newState = !settings.settings.isEnabled;
                            await settings.setReminderEnabled(newState);
                            // Update reminder with new settings after state change
                            reminder.updateReminderState(settings.settings);
                          },
                          onSettings: () {
                            // Navigate to settings and show interval picker
                            _navigateToSettingsWithIntervalPicker(context);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Stats Row
                    Consumer<IntakeProvider>(
                      builder: (context, provider, _) {
                        return ReminderStatsRow(
                          streak: provider.streak,
                          averageIntake: provider.getAverageIntake(7),
                          dailyGoal: provider.dailyGoal,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Quick Add
                    Consumer<IntakeProvider>(
                      builder: (context, provider, _) {
                        return QuickAddGrid(
                          onAmountSelected: (amount) async {
                            HapticFeedback.mediumImpact();
                            await provider.addQuickIntake(amount);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${amount}ml 💧'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      // Undo last intake
                                      if (provider.todayIntakes.isNotEmpty) {
                                        provider.removeIntake(
                                          provider.todayIntakes.first.id,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          onCustomTap: () {
                            _showCustomAmountDialog(context, provider);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Today's Log
                    Consumer<IntakeProvider>(
                      builder: (context, provider, _) {
                        return IntakeLogList(
                          intakes: provider.todayIntakes,
                          onDelete: (id) async {
                            await provider.removeIntake(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Intake removed'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💧 Aqua Reminder',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stay hydrated, stay healthy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Test notification button (for development)
          IconButton(
            onPressed: () {
              context.read<SettingsProvider>().testNotification();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, IntakeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => CustomAmountDialog(
        initialAmount: 250,
        onConfirm: (amount) async {
          HapticFeedback.mediumImpact();
          await provider.addQuickIntake(amount);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${amount}ml 💧'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
