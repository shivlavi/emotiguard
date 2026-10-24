import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MetricSparklineCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String baselineNote;
  final Color accentColor;
  final IconData icon;
  final List<double> sparklineData;
  final bool isPulseActive;

  const MetricSparklineCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.baselineNote,
    required this.accentColor,
    required this.icon,
    this.sparklineData = const [],
    this.isPulseActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
              if (isPulseActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Value & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mini Sparkline
          SizedBox(
            height: 28,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                data: sparklineData.isNotEmpty ? sparklineData : [2.0, 2.1, 2.3, 2.2, 2.4, 2.3],
                lineColor: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Baseline note
          Text(
            baselineNote,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _SparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 4)) - 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}
