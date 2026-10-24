import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/sensor_packet.dart';
import '../providers/sensor_providers.dart';

class TimeframeHistoryChart extends StatelessWidget {
  final ChartTimeframe selectedTimeframe;
  final Function(ChartTimeframe) onTimeframeChanged;
  final List<SensorPacket> history;

  const TimeframeHistoryChart({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biometric Trend Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              // Segmented Timeframe Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildTimeframeTab('1H', ChartTimeframe.oneHour, isDark),
                    _buildTimeframeTab('24H', ChartTimeframe.twentyFourHours, isDark),
                    _buildTimeframeTab('7D', ChartTimeframe.sevenDays, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _buildLegendItem(AppColors.heartRate, 'Heart Rate (BPM)'),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.edaArousal, 'EDA Skin Cond. (uS)'),
            ],
          ),
          const SizedBox(height: 18),
          // Trend Visualizer Canvas
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _MultiTrendPainter(
                history: history,
                hrColor: AppColors.heartRate,
                edaColor: AppColors.edaArousal,
                gridColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeTab(String label, ChartTimeframe timeframe, bool isDark) {
    final isSelected = selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () => onTimeframeChanged(timeframe),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardDarkElevated : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryTeal
                : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MultiTrendPainter extends CustomPainter {
  final List<SensorPacket> history;
  final Color hrColor;
  final Color edaColor;
  final Color gridColor;

  _MultiTrendPainter({
    required this.history,
    required this.hrColor,
    required this.edaColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw 3 horizontal guideline dashes
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (history.length < 2) return;

    // Normalization bounds
    final minHr = 50.0;
    final maxHr = 130.0;
    final minEda = 1.0;
    final maxEda = 8.5;

    final hrPath = Path();
    final edaPath = Path();
    final stepX = size.width / (history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final hrNorm = ((history[i].heartRate - minHr) / (maxHr - minHr)).clamp(0.0, 1.0);
      final edaNorm = ((history[i].eda - minEda) / (maxEda - minEda)).clamp(0.0, 1.0);

      final yHr = size.height - (hrNorm * (size.height - 10)) - 5;
      final yEda = size.height - (edaNorm * (size.height - 10)) - 5;

      if (i == 0) {
        hrPath.moveTo(x, yHr);
        edaPath.moveTo(x, yEda);
      } else {
        hrPath.lineTo(x, yHr);
        edaPath.lineTo(x, yEda);
      }
    }

    // Draw EDA Line
    final edaPaint = Paint()
      ..color = edaColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(edaPath, edaPaint);

    // Draw HR Line
    final hrPaint = Paint()
      ..color = hrColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hrPath, hrPaint);
  }

  @override
  bool shouldRepaint(covariant _MultiTrendPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
