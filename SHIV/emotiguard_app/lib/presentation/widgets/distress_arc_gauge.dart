import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/distress_state.dart';

class DistressArcGauge extends StatelessWidget {
  final DistressState state;
  final VoidCallback? onInterventionTap;

  const DistressArcGauge({
    super.key,
    required this.state,
    this.onInterventionTap,
  });

  Color _getScoreColor(double score) {
    if (score < 30.0) return AppColors.statusCalm;
    if (score < 55.0) return AppColors.statusMild;
    if (score < 80.0) return AppColors.statusElevated;
    return AppColors.statusHigh;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scoreColor = _getScoreColor(state.score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(isDark ? 0.12 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distress Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withOpacity(0.4)),
                ),
                child: Text(
                  state.label,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Arc Gauge
          SizedBox(
            height: 140,
            width: 220,
            child: CustomPaint(
              painter: _ArcGaugePainter(
                score: state.score,
                activeColor: scoreColor,
                trackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '${state.score.toInt()}',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Friendly narrative description
          Text(
            state.friendlySummary,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              height: 1.4,
            ),
          ),
          if (state.requiresGentleIntervention) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onInterventionTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.air, size: 16, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Text(
                      'Try 4-7-8 Breathing (2 min)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double score;
  final Color activeColor;
  final Color trackColor;

  _ArcGaugePainter({
    required this.score,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const strokeWidth = 14.0;

    const startAngle = pi * 0.85;
    const sweepAngle = pi * 1.3;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active Progress
    final progressSweep = sweepAngle * (score / 100.0).clamp(0.02, 1.0);
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.activeColor != activeColor;
  }
}
