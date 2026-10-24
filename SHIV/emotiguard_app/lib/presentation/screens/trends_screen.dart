import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/scoring/distress_scoring_engine.dart';
import '../providers/sensor_providers.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseline = ref.watch(baselineProfileProvider);
    final scoringEngine = ref.watch(scoringEngineProvider);
    final historyAsync = ref.watch(historyDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Long-term Biometric Trends'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Baseline Calibration Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '7-Day Baseline Calibration',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Day 4 of 7',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        value: 4.0 / 7.0,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EmotiGuard learns your unique resting vitals (heart rate, skin conductance, circadian fluctuations) over the first week to personalize distress thresholds instead of generic population averages.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBaselineStat('Resting HR', '${baseline.meanHr.toInt()} bpm', isDark),
                        _buildBaselineStat('Baseline EDA', '${baseline.meanEda.toStringAsFixed(1)} uS', isDark),
                        _buildBaselineStat('Vagal HRV', '${baseline.meanHrv.toInt()} ms', isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. 48-Hour Gradual Stress Deviation Analysis
              historyAsync.when(
                data: (history) {
                  final trendResult = scoringEngine.evaluate48HourTrend(
                    history48h: history,
                    baseline: baseline,
                  );

                  final isAlert = trendResult.isGraduallyWorsening;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAlert
                            ? AppColors.statusElevated
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isAlert ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                              color: isAlert ? AppColors.statusElevated : AppColors.sageGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '48-Hour Gradual Drift Detection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isAlert ? AppColors.statusElevated : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trendResult.summary,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why 48-Hour Gradual Detection Matters:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Acute distress spikes (e.g., sudden fright) resolve quickly. Worsening mental strain shows up as a sustained upward drift in baseline resting pulse and skin conductance combined with incomplete nocturnal HRV recovery over 36-48 hours.',
                                style: TextStyle(fontSize: 11, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // 3. Circadian Sleep & Restlessness Pattern
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nocturnal Recovery & Sleep Quality',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Overnight movement variance: 0.03g (Restful). Nocturnal heart rate dipped to 58 bpm, confirming healthy parasympathetic rest-and-digest cycles.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaselineStat(String title, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }
}
