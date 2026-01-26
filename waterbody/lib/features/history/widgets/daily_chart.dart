import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/water_intake.dart';

class WeeklyChart extends StatelessWidget {
  final List<DailyIntakeSummary> summaries;
  final int goalMl;

  const WeeklyChart({
    super.key,
    required this.summaries,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (goalMl * 1.2).toDouble(),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.primary,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        Helpers.formatMl(rod.toY.toInt()),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < summaries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              Helpers.getDayName(
                                summaries[index].date.weekday,
                                short: true,
                              ),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goalMl / 2,
                  getDrawingHorizontalLine: (value) {
                    final isGoalLine = value == goalMl;
                    return FlLine(
                      color: isGoalLine
                          ? AppColors.success.withValues(alpha: 0.5)
                          : (isDark
                              ? AppColors.textDark.withValues(alpha: 0.1)
                              : AppColors.waterLight),
                      strokeWidth: isGoalLine ? 2 : 1,
                      dashArray: isGoalLine ? [5, 5] : null,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: summaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  final isToday = Helpers.isSameDay(summary.date, DateTime.now());
                  final goalReached = summary.goalReached;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.totalMl.toDouble(),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: goalReached
                              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                              : isToday
                                  ? [AppColors.primary, AppColors.primaryLight]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.6),
                                      AppColors.primaryLight.withValues(alpha: 0.4),
                                    ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklySummaryCard extends StatelessWidget {
  final int streak;
  final double averageIntake;
  final DailyIntakeSummary? bestDay;
  final int totalWeekMl;

  const WeeklySummaryCard({
    super.key,
    required this.streak,
    required this.averageIntake,
    this.bestDay,
    required this.totalWeekMl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  value: '$streak',
                  label: 'Day Streak',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark
                    ? AppColors.textDark.withValues(alpha: 0.1)
                    : AppColors.waterLight,
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.show_chart,
                  iconColor: AppColors.primary,
                  value: Helpers.formatMl(averageIntake.round()),
                  label: 'Daily Avg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  value: bestDay != null
                      ? Helpers.formatMl(bestDay!.totalMl)
                      : '--',
                  label: 'Best Day',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark
                    ? AppColors.textDark.withValues(alpha: 0.1)
                    : AppColors.waterLight,
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.water_drop,
                  iconColor: AppColors.waterBlue,
                  value: Helpers.formatMl(totalWeekMl),
                  label: 'Total Week',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
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
        ),
      ],
    );
  }
}
