import 'package:flutter/material.dart';
import '../data/models/water_intake.dart';
import '../data/repositories/intake_repository.dart';

class IntakeProvider extends ChangeNotifier {
  final IntakeRepository _repository;
  final int Function() _getDailyGoal;

  List<WaterIntake> _todayIntakes = [];
  int _todayTotal = 0;
  List<DailyIntakeSummary> _weeklySummary = [];
  int _streak = 0;
  bool _isLoading = false;

  IntakeProvider(this._repository, this._getDailyGoal) {
    _loadTodayData();
  }

  // Getters
  List<WaterIntake> get todayIntakes => _todayIntakes;
  int get todayTotal => _todayTotal;
  List<DailyIntakeSummary> get weeklySummary => _weeklySummary;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  int get dailyGoal => _getDailyGoal();

  // Progress percentage (0-100)
  double get progress => dailyGoal > 0 ? (_todayTotal / dailyGoal * 100).clamp(0, 100) : 0;

  // Progress as fraction (0-1)
  double get progressFraction => progress / 100;

  // Remaining amount
  int get remaining => (dailyGoal - _todayTotal).clamp(0, dailyGoal);

  // Goal reached
  bool get goalReached => _todayTotal >= dailyGoal;

  // Load today's data
  Future<void> _loadTodayData() async {
    _isLoading = true;
    notifyListeners();

    _todayIntakes = _repository.getTodayIntakes();
    _todayTotal = _repository.getTodayTotalIntake();
    _streak = _repository.calculateStreak(dailyGoal);
    _weeklySummary = _repository.getWeeklySummary(dailyGoal);

    _isLoading = false;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadTodayData();
  }

  // Add water intake
  Future<WaterIntake> addIntake(int amountMl, {String? note}) async {
    final intake = await _repository.addIntake(amountMl, note: note);
    await _loadTodayData();
    return intake;
  }

  // Add quick intake (uses default glass size)
  Future<WaterIntake> addQuickIntake(int amountMl) async {
    return await addIntake(amountMl);
  }

  // Remove intake
  Future<void> removeIntake(String id) async {
    await _repository.removeIntake(id);
    await _loadTodayData();
  }

  // Update intake
  Future<void> updateIntake(String id, {int? amountMl, String? note}) async {
    await _repository.updateIntake(id, amountMl: amountMl, note: note);
    await _loadTodayData();
  }

  // Get intakes for a specific date
  List<WaterIntake> getIntakesForDate(DateTime date) {
    return _repository.getIntakesForDate(date);
  }

  // Get total for a specific date
  int getTotalForDate(DateTime date) {
    return _repository.getTotalIntakeForDate(date);
  }

  // Get weekly summary
  List<DailyIntakeSummary> getWeeklySummary() {
    return _repository.getWeeklySummary(dailyGoal);
  }

  // Get monthly summary
  List<DailyIntakeSummary> getMonthlySummary() {
    return _repository.getMonthlySummary(dailyGoal);
  }

  // Get average intake
  double getAverageIntake(int days) {
    return _repository.getAverageIntake(days, dailyGoal);
  }

  // Get best day
  DailyIntakeSummary? getBestDay(int days) {
    return _repository.getBestDay(days, dailyGoal);
  }

  // Clear all data (for testing/reset)
  Future<void> clearAll() async {
    await _repository.clearAll();
    await _loadTodayData();
  }
}
