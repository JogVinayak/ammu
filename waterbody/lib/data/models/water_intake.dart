import 'package:hive/hive.dart';

part 'water_intake.g.dart';

@HiveType(typeId: 0)
class WaterIntake extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int amountMl;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? note;

  WaterIntake({
    required this.id,
    required this.amountMl,
    required this.timestamp,
    this.note,
  });

  WaterIntake copyWith({
    String? id,
    int? amountMl,
    DateTime? timestamp,
    String? note,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountMl': amountMl,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'] as String,
      amountMl: json['amountMl'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );
  }

  @override
  String toString() {
    return 'WaterIntake(id: $id, amountMl: $amountMl, timestamp: $timestamp, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterIntake &&
        other.id == id &&
        other.amountMl == amountMl &&
        other.timestamp == timestamp &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(id, amountMl, timestamp, note);
  }
}

/// Daily summary for statistics
class DailyIntakeSummary {
  final DateTime date;
  final int totalMl;
  final int goalMl;
  final int intakeCount;
  final List<WaterIntake> intakes;

  const DailyIntakeSummary({
    required this.date,
    required this.totalMl,
    required this.goalMl,
    required this.intakeCount,
    required this.intakes,
  });

  double get percentage => goalMl > 0 ? (totalMl / goalMl * 100).clamp(0, 100) : 0;
  bool get goalReached => totalMl >= goalMl;

  @override
  String toString() {
    return 'DailyIntakeSummary(date: $date, totalMl: $totalMl, goalMl: $goalMl, intakeCount: $intakeCount)';
  }
}
