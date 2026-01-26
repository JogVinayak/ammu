import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/water_intake.dart';
import '../../core/utils/helpers.dart';

class IntakeRepository {
  static const String _boxName = 'water_intakes';
  late Box<WaterIntake> _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<WaterIntake>(_boxName);
  }

  // Add water intake
  Future<WaterIntake> addIntake(int amountMl, {String? note}) async {
    final intake = WaterIntake(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
      note: note,
    );
    await _box.put(intake.id, intake);
    return intake;
  }

  // Remove water intake
  Future<void> removeIntake(String id) async {
    await _box.delete(id);
  }

  // Update water intake
  Future<WaterIntake?> updateIntake(String id, {int? amountMl, String? note}) async {
    final existing = _box.get(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      amountMl: amountMl ?? existing.amountMl,
      note: note ?? existing.note,
    );
    await _box.put(id, updated);
    return updated;
  }

  // Get all intakes for a specific date
  List<WaterIntake> getIntakesForDate(DateTime date) {
    final startOfDay = Helpers.startOfDay(date);
    final endOfDay = Helpers.endOfDay(date);

    return _box.values
        .where((intake) =>
            intake.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            intake.timestamp.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get today's intakes
  List<WaterIntake> getTodayIntakes() {
    return getIntakesForDate(DateTime.now());
  }

  // Get total intake for a specific date
  int getTotalIntakeForDate(DateTime date) {
    return getIntakesForDate(date).fold(0, (sum, intake) => sum + intake.amountMl);
  }

  // Get today's total intake
  int getTodayTotalIntake() {
    return getTotalIntakeForDate(DateTime.now());
  }

  // Get intakes for date range
  List<WaterIntake> getIntakesForRange(DateTime start, DateTime end) {
    final startOfStart = Helpers.startOfDay(start);
    final endOfEnd = Helpers.endOfDay(end);

    return _box.values
        .where((intake) =>
            intake.timestamp.isAfter(startOfStart.subtract(const Duration(seconds: 1))) &&
            intake.timestamp.isBefore(endOfEnd.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get daily summaries for a date range
  List<DailyIntakeSummary> getDailySummaries(DateTime start, DateTime end, int goalMl) {
    final summaries = <DailyIntakeSummary>[];
    var current = Helpers.startOfDay(start);
    final endDate = Helpers.startOfDay(end);

    while (!current.isAfter(endDate)) {
      final intakes = getIntakesForDate(current);
      final totalMl = intakes.fold(0, (sum, intake) => sum + intake.amountMl);

      summaries.add(DailyIntakeSummary(
        date: current,
        totalMl: totalMl,
        goalMl: goalMl,
        intakeCount: intakes.length,
        intakes: intakes,
      ));

      current = current.add(const Duration(days: 1));
    }

    return summaries;
  }

  // Get weekly summary (last 7 days)
  List<DailyIntakeSummary> getWeeklySummary(int goalMl) {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));
    return getDailySummaries(start, end, goalMl);
  }

  // Get monthly summary
  List<DailyIntakeSummary> getMonthlySummary(int goalMl) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return getDailySummaries(start, end, goalMl);
  }

  // Calculate average intake for a period
  double getAverageIntake(int days, int goalMl) {
    final summaries = getDailySummaries(
      DateTime.now().subtract(Duration(days: days - 1)),
      DateTime.now(),
      goalMl,
    );
    if (summaries.isEmpty) return 0;
    final total = summaries.fold(0, (sum, s) => sum + s.totalMl);
    return total / summaries.length;
  }

  // Calculate streak (consecutive days meeting goal)
  int calculateStreak(int goalMl) {
    int streak = 0;
    var currentDate = DateTime.now();

    while (true) {
      final total = getTotalIntakeForDate(currentDate);
      if (total >= goalMl) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // If it's today and we haven't met the goal yet, check yesterday
        if (Helpers.isSameDay(currentDate, DateTime.now())) {
          currentDate = currentDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }

      // Safety limit to prevent infinite loop
      if (streak > 365) break;
    }

    return streak;
  }

  // Get best day (highest intake)
  DailyIntakeSummary? getBestDay(int days, int goalMl) {
    final summaries = getDailySummaries(
      DateTime.now().subtract(Duration(days: days - 1)),
      DateTime.now(),
      goalMl,
    );
    if (summaries.isEmpty) return null;
    return summaries.reduce((a, b) => a.totalMl > b.totalMl ? a : b);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Get box for listening to changes
  Box<WaterIntake> get box => _box;
}
