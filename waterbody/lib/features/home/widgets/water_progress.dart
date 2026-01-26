import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class WaterProgress extends StatefulWidget {
  final int currentMl;
  final int goalMl;
  final double size;

  const WaterProgress({
    super.key,
    required this.currentMl,
    required this.goalMl,
    this.size = 220,
  });

  @override
  State<WaterProgress> createState() => _WaterProgressState();
}

class _WaterProgressState extends State<WaterProgress>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0, end: _calculateProgress())
        .animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _progressController.forward();
  }

  @override
  void didUpdateWidget(WaterProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMl != widget.currentMl ||
        oldWidget.goalMl != widget.goalMl) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: _calculateProgress(),
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController
        ..reset()
        ..forward();
    }
  }

  double _calculateProgress() {
    if (widget.goalMl == 0) return 0;
    return (widget.currentMl / widget.goalMl).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = Helpers.calculatePercentage(widget.currentMl, widget.goalMl);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_waveController, _progressAnimation]),
            builder: (context, child) {
              return CustomPaint(
                painter: _WaterProgressPainter(
                  progress: _progressAnimation.value,
                  waveAnimation: _waveController.value,
                  isDark: isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '💧',
                        style: TextStyle(fontSize: widget.size * 0.15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Helpers.formatMl(widget.currentMl),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: percentage >= 100
                              ? AppColors.success
                              : (isDark ? AppColors.textDark : AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '/ ${Helpers.formatMl(widget.goalMl)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildPercentageIndicator(context, percentage),
      ],
    );
  }

  Widget _buildPercentageIndicator(BuildContext context, double percentage) {
    final isGoalReached = percentage >= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isGoalReached
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGoalReached ? Icons.celebration : Icons.trending_up,
            size: 20,
            color: isGoalReached ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isGoalReached
                ? 'Goal Reached! 🎉'
                : '${percentage.toStringAsFixed(0)}% Complete',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isGoalReached ? AppColors.success : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterProgressPainter extends CustomPainter {
  final double progress;
  final double waveAnimation;
  final bool isDark;

  _WaterProgressPainter({
    required this.progress,
    required this.waveAnimation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw background circle
    final bgPaint = Paint()
      ..color = isDark
          ? AppColors.surfaceDark
          : AppColors.waterLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isDark
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);

    if (progress <= 0) return;

    // Create clipping circle
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 3));
    canvas.clipPath(clipPath);

    // Calculate water level
    final waterHeight = size.height * progress;
    final waterTop = size.height - waterHeight;

    // Draw waves
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.8),
          AppColors.primary,
          AppColors.primaryDark,
        ],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, waterHeight));

    final wavePath = Path();
    wavePath.moveTo(0, size.height);

    // Create wave effect
    for (double x = 0; x <= size.width; x++) {
      final waveOffset = math.sin((x / size.width * 4 * math.pi) + (waveAnimation * 2 * math.pi)) * 8;
      final waveOffset2 = math.sin((x / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi) + math.pi) * 4;
      final y = waterTop + waveOffset + waveOffset2;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);

    // Draw secondary wave for depth effect
    final wave2Paint = Paint()
      ..color = AppColors.accentLight.withValues(alpha: 0.3);

    final wave2Path = Path();
    wave2Path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final waveOffset = math.sin((x / size.width * 3 * math.pi) + (waveAnimation * 2 * math.pi) + 1) * 6;
      final y = waterTop + 10 + waveOffset;
      wave2Path.lineTo(x, y);
    }

    wave2Path.lineTo(size.width, size.height);
    wave2Path.close();

    canvas.drawPath(wave2Path, wave2Paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.isDark != isDark;
  }
}
