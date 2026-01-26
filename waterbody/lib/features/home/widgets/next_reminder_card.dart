import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NextReminderCard extends StatelessWidget {
  final String countdownText;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onSettings;

  const NextReminderCard({
    super.key,
    required this.countdownText,
    required this.isActive,
    required this.onToggle,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isActive
            ? AppColors.primaryGradient
            : null,
        color: isActive
            ? null
            : (isDark ? AppColors.surfaceDark : AppColors.backgroundWhite),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? Icons.notifications_active : Icons.notifications_off,
              color: isActive
                  ? Colors.white
                  : (isDark ? AppColors.textLight : AppColors.textSecondary),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Next Reminder' : 'Reminders Paused',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? countdownText : 'Tap to enable',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isActive
                        ? Colors.white
                        : (isDark ? AppColors.textDark : AppColors.textPrimary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle button
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isActive ? Icons.pause_circle : Icons.play_circle,
                  color: isActive ? Colors.white : AppColors.primary,
                  size: 32,
                ),
              ),
              // Settings button
              IconButton(
                onPressed: onSettings,
                icon: Icon(
                  Icons.settings,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReminderStatsRow extends StatelessWidget {
  final int streak;
  final double averageIntake;
  final int dailyGoal;

  const ReminderStatsRow({
    super.key,
    required this.streak,
    required this.averageIntake,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: '$streak',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.show_chart,
            iconColor: AppColors.primary,
            value: '${(averageIntake / 1000).toStringAsFixed(1)}L',
            label: 'Daily Avg',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.flag,
            iconColor: AppColors.success,
            value: '${(dailyGoal / 1000).toStringAsFixed(1)}L',
            label: 'Daily Goal',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
