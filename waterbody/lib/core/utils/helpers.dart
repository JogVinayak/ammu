import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Format time from TimeOfDay to readable string
  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hours';
      }
      return '$hours h ${minutes} min';
    }
  }

  /// Format interval minutes to readable string
  static String formatInterval(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 hour';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60} hours';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours h $mins min';
    }
  }

  /// Format milliliters to readable string
  static String formatMl(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000;
      if (liters == liters.toInt()) {
        return '${liters.toInt()} L';
      }
      return '${liters.toStringAsFixed(1)} L';
    }
    return '$ml ml';
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format full date
  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  /// Get remaining time until next reminder (with seconds)
  static String getRemainingTime(DateTime nextReminder, {bool showSeconds = true}) {
    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return 'Due now';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (showSeconds) {
      // Show MM:SS or HH:MM:SS format
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    } else {
      // Original format without seconds
      if (difference.inMinutes < 1) {
        return 'Less than a minute';
      }

      if (difference.inMinutes < 60) {
        return '$minutes min';
      }

      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }

      return '$hours h $minutes min';
    }
  }

  /// Calculate percentage
  static double calculatePercentage(int current, int total) {
    if (total == 0) return 0;
    return (current / total * 100).clamp(0, 100);
  }

  /// Get day name from weekday
  static String getDayName(int weekday, {bool short = false}) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return short ? days[weekday - 1] : fullDays[weekday - 1];
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  /// Validate time is within active hours
  static bool isWithinActiveHours(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}
