import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/water_intake.dart';
import '../../../providers/intake_provider.dart';
import '../widgets/daily_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your hydration progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.waterLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'This Week'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _WeeklyTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<IntakeProvider>(
      builder: (context, provider, _) {
        final weeklySummary = provider.getWeeklySummary();
        final totalWeekMl = weeklySummary.fold(0, (sum, s) => sum + s.totalMl);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // Weekly chart
            WeeklyChart(
              summaries: weeklySummary,
              goalMl: provider.dailyGoal,
            ),
            const SizedBox(height: 20),
            // Weekly summary
            WeeklySummaryCard(
              streak: provider.streak,
              averageIntake: provider.getAverageIntake(7),
              bestDay: provider.getBestDay(7),
              totalWeekMl: totalWeekMl,
            ),
            const SizedBox(height: 20),
            // Daily breakdown
            _buildDailyBreakdown(context, weeklySummary),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildDailyBreakdown(
    BuildContext context,
    List<DailyIntakeSummary> summaries,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reversedSummaries = summaries.reversed.toList();

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
            'Daily Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...reversedSummaries.map((summary) => _DailyBreakdownTile(
                summary: summary,
              )),
        ],
      ),
    );
  }
}

class _DailyBreakdownTile extends StatelessWidget {
  final DailyIntakeSummary summary;

  const _DailyBreakdownTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = Helpers.isSameDay(summary.date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : Helpers.getDayName(summary.date.weekday, short: true),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppColors.primary : null,
                  ),
                ),
                Text(
                  Helpers.formatDate(summary.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary.percentage / 100,
                    backgroundColor: isDark
                        ? AppColors.textDark.withValues(alpha: 0.1)
                        : AppColors.waterLight,
                    valueColor: AlwaysStoppedAnimation(
                      summary.goalReached ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.intakeCount} drinks',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatMl(summary.totalMl),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (summary.goalReached)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<IntakeProvider>(
      builder: (context, provider, _) {
        final monthlySummary = provider.getMonthlySummary();

        if (monthlySummary.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group by date
        final groupedIntakes = <DateTime, List<WaterIntake>>{};
        for (final summary in monthlySummary) {
          groupedIntakes[summary.date] = summary.intakes;
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: monthlySummary.length,
          itemBuilder: (context, index) {
            final summary = monthlySummary[monthlySummary.length - 1 - index];
            
            if (summary.intakes.isEmpty) {
              return const SizedBox.shrink();
            }

            return _DateSection(
              date: summary.date,
              intakes: summary.intakes,
              totalMl: summary.totalMl,
              goalMl: summary.goalMl,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.waterLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '📊',
              style: TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No history yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your water intake\nto see your history here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final DateTime date;
  final List<WaterIntake> intakes;
  final int totalMl;
  final int goalMl;

  const _DateSection({
    required this.date,
    required this.intakes,
    required this.totalMl,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = Helpers.isSameDay(date, DateTime.now());
    final goalReached = totalMl >= goalMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? 'Today' : Helpers.formatFullDate(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    Helpers.formatMl(totalMl),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: goalReached ? AppColors.success : null,
                    ),
                  ),
                  if (goalReached) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Intakes list
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: intakes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 60,
              color: isDark
                  ? AppColors.textDark.withValues(alpha: 0.1)
                  : AppColors.waterLight,
            ),
            itemBuilder: (context, index) {
              final intake = intakes[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('💧', style: TextStyle(fontSize: 18)),
                  ),
                ),
                title: Text(
                  Helpers.formatMl(intake.amountMl),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  Helpers.formatDateTime(intake.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
