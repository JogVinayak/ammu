import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Ocean Blues
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryLight = Color(0xFF7DD3FC);
  static const Color primaryDark = Color(0xFF0369A1);

  // Accent Colors
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF67E8F9);

  // Water Theme
  static const Color waterBlue = Color(0xFF38BDF8);
  static const Color waterDeep = Color(0xFF0284C7);
  static const Color waterLight = Color(0xFFE0F2FE);
  static const Color waterDrop = Color(0xFF22D3EE);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF0F9FF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0C1929);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFE2E8F0);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
  );

  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7DD3FC), Color(0xFF0EA5E9), Color(0xFF0369A1)],
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C1929), Color(0xFF1E293B)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
  );

  // Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
}
