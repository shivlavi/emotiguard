import 'dart:math';
import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/baseline_profile.dart';
import '../../domain/entities/distress_state.dart';
import '../../domain/entities/user_settings.dart';

/// Tunable parameters for the EmotiGuard Distress Scoring Algorithm.
/// Adjust these values to calibrate sensitivity, response times, and dampening.
class DistressScoringConfig {
  // Component Weights (Sum should ideally be 1.0)
  final double weightEda;      // Electrodermal activity (Skin conductance) weight
  final double weightHr;       // Heart rate elevation weight
  final double weightHrv;      // Heart rate variability suppression weight

  // Activity Dampening: High movement indicates physical exertion (gym, brisk walk),
  // which causes physiological arousal without emotional distress.
  final double movementThresholdActive;  // g threshold where activity dampening begins
  final double minActivityDampener;      // Floor for dampener (0.15 = 85% score reduction under intense movement)

  // Smoothing
  final double emaAlpha;                 // Exponential Moving Average factor (0.0 to 1.0)

  // Gradual Trend Detection (48-Hour Window)
  final double gradualHrZThreshold;      // Standard deviations above baseline
  final double gradualEdaZThreshold;     // Standard deviations above baseline
  final int minSustainedHours;           // Hours deviation must persist to trigger gradual alert (e.g. 36-48h)

  const DistressScoringConfig({
    this.weightEda = 0.40,               // EDA is often the most specific biomarker for emotional arousal
    this.weightHr = 0.35,
    this.weightHrv = 0.25,
    this.movementThresholdActive = 0.25, // Above ~0.25g is active locomotion
    this.minActivityDampener = 0.20,
    this.emaAlpha = 0.25,                // Smooths 5-second samples over ~20-30 seconds
    this.gradualHrZThreshold = 1.15,
    this.gradualEdaZThreshold = 1.30,
    this.minSustainedHours = 48,
  });

  /// Factory preset based on user sensitivity preference in settings
  factory DistressScoringConfig.forSensitivity(SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.low:
        return const DistressScoringConfig(
          weightEda: 0.35,
          weightHr: 0.35,
          weightHrv: 0.30,
          gradualHrZThreshold: 1.4,
          gradualEdaZThreshold: 1.5,
        );
      case SensitivityLevel.high:
        return const DistressScoringConfig(
          weightEda: 0.45,
          weightHr: 0.35,
          weightHrv: 0.20,
          gradualHrZThreshold: 0.9,
          gradualEdaZThreshold: 1.1,
        );
      case SensitivityLevel.medium:
      default:
        return const DistressScoringConfig();
    }
  }
}

/// The core mathematical engine that converts raw biometrics into an emotional distress metric.
class DistressScoringEngine {
  final DistressScoringConfig config;
  double _lastEmaScore = 15.0; // Running exponential moving average

  DistressScoringEngine({DistressScoringConfig? config})
      : config = config ?? const DistressScoringConfig();

  /// Evaluates an incoming [SensorPacket] against the user's learned [BaselineProfile].
  /// Returns an immutable [DistressState] containing the 0-100 score, friendly copy,
  /// and component ratios.
  DistressState evaluatePacket({
    required SensorPacket packet,
    required BaselineProfile baseline,
    SensitivityLevel sensitivity = SensitivityLevel.medium,
  }) {
    // 1. Calculate Standard Normalized Deviations (Z-Scores)
    // Z-score = (Observed - Mean) / StdDev
    final hrStd = (baseline.stdHr > 0) ? baseline.stdHr : 8.0;
    final edaStd = (baseline.stdEda > 0) ? baseline.stdEda : 0.6;
    final hrvStd = (baseline.stdHrv > 0) ? baseline.stdHrv : 12.0;

    // Heart Rate: Elevated above baseline signals sympathetic activation
    final zHr = (packet.heartRate - baseline.meanHr) / hrStd;

    // Skin Conductance (EDA): High microSiemens indicates eccrine sweat gland arousal
    final zEda = (packet.eda - baseline.meanEda) / edaStd;

    // HRV (RMSSD): Decreased variability indicates loss of vagal parasympathetic braking
    // Inverted so positive z means stress (lower HRV than baseline)
    final zHrv = (baseline.meanHrv - packet.hrv) / hrvStd;

    // 2. Sigmoidal Component Normalization (Maps z-scores smoothly into 0..100)
    // Positive z-scores push score towards 100; negative clamp smoothly near 0.
    final hrScore = _sigmoidScale(zHr);
    final edaScore = _sigmoidScale(zEda);
    final hrvScore = _sigmoidScale(zHrv);

    // 3. Physical Activity Modulation (Disambiguating Exercise vs Anxiety)
    // Emotional distress typically occurs while sedentary or pacing mildly.
    // Intense physical workout causes high HR and high sweat, but shouldn't trigger distress alarms!
    final movement = packet.movementMagnitude;
    double activityDampener = 1.0;

    if (movement > config.movementThresholdActive) {
      // Scale dampener down smoothly as motion increases
      final excessMotion = (movement - config.movementThresholdActive);
      activityDampener = max(
        config.minActivityDampener,
        1.0 - (excessMotion * 1.5),
      );
    }

    // 4. Weighted Composite Score
    final rawComposite = (hrScore * config.weightHr) +
        (edaScore * config.weightEda) +
        (hrvScore * config.weightHrv);

    // Apply activity modulation: if running on a treadmill, reduce emotional distress score
    final modulatedScore = rawComposite * activityDampener;

    // 5. Exponential Moving Average (EMA) to prevent single-sample sensor spikes
    final smoothedScore = (_lastEmaScore * (1.0 - config.emaAlpha)) +
        (modulatedScore * config.emaAlpha);
    _lastEmaScore = smoothedScore.clamp(0.0, 100.0);

    // 6. Map to Distress Level & Friendly Narrative Copy
    final level = _determineLevel(_lastEmaScore);
    final friendlyCopy = _generateFriendlyNarrative(
      level: level,
      zHr: zHr,
      zEda: zEda,
      isExercising: activityDampener < 0.6,
    );

    return DistressState(
      score: double.parse(_lastEmaScore.toStringAsFixed(1)),
      level: level,
      label: _getLevelLabel(level),
      friendlySummary: friendlyCopy,
      hrDeviationRatio: double.parse(zHr.toStringAsFixed(2)),
      edaElevationRatio: double.parse(zEda.toStringAsFixed(2)),
      hrvSuppressionRatio: double.parse(zHrv.toStringAsFixed(2)),
      activityDampener: double.parse(activityDampener.toStringAsFixed(2)),
      timestamp: DateTime.fromMillisecondsSinceEpoch(packet.timestamp * 1000),
    );
  }

  /// Sigmoid function centered at z=0, scaling roughly:
  /// z = -2.0 -> ~5
  /// z =  0.0 -> 25 (calm resting baseline)
  /// z = +1.5 -> 65 (noticeable stress)
  /// z = +3.0 -> 92 (acute distress)
  double _sigmoidScale(double z) {
    final clampedZ = z.clamp(-3.0, 4.0);
    // Sigmoid curve with baseline offset
    return 100.0 / (1.0 + exp(-1.1 * (clampedZ - 0.5)));
  }

  DistressLevel _determineLevel(double score) {
    if (score < 30.0) return DistressLevel.calm;
    if (score < 55.0) return DistressLevel.mild;
    if (score < 80.0) return DistressLevel.elevated;
    return DistressLevel.acute;
  }

  String _getLevelLabel(DistressLevel level) {
    switch (level) {
      case DistressLevel.calm:
        return 'Calm & Centered';
      case DistressLevel.mild:
        return 'Gentle Tension';
      case DistressLevel.elevated:
        return 'Elevated Arousal';
      case DistressLevel.acute:
        return 'High Distress';
    }
  }

  String _generateFriendlyNarrative({
    required DistressLevel level,
    required double zHr,
    required double zEda,
    required bool isExercising,
  }) {
    if (isExercising) {
      return 'Physical movement detected. Elevated vitals reflect healthy physical exertion.';
    }

    switch (level) {
      case DistressLevel.calm:
        return 'Vitals are relaxed and steady within your typical baseline zone.';
      case DistressLevel.mild:
        if (zEda > 1.0) {
          return 'Slight rise in skin response detected. A short pause might feel nice.';
        }
        return 'Slightly elevated pulse. You might be focusing intently or moving about.';
      case DistressLevel.elevated:
        return 'Your body is signaling heightened stress while sitting. Would you like a 2-minute breathing exercise?';
      case DistressLevel.acute:
        return 'Sustained sympathetic activation detected. We are here with you. Take slow, gentle breaths.';
    }
  }

  /// Evaluates historical 48-hour sensor packets for gradual worsening trends.
  /// Detects insidious elevation over days rather than acute momentary spikes.
  GradualTrendResult evaluate48HourTrend({
    required List<SensorPacket> history48h,
    required BaselineProfile baseline,
  }) {
    if (history48h.length < 50) {
      return const GradualTrendResult(
        isGraduallyWorsening: false,
        summary: 'Still collecting baseline history for 48-hour trend analysis.',
        meanDeviationScore: 0.0,
      );
    }

    // Filter out active exercise periods to prevent skewed baseline trends
    final sedentaryPackets = history48h.where((p) => !p.isPhysicallyActive).toList();
    if (sedentaryPackets.isEmpty) {
      return const GradualTrendResult(
        isGraduallyWorsening: false,
        summary: 'Baseline activity within normal bounds.',
        meanDeviationScore: 0.0,
      );
    }

    final avgHr = sedentaryPackets.map((p) => p.heartRate).reduce((a, b) => a + b) / sedentaryPackets.length;
    final avgEda = sedentaryPackets.map((p) => p.eda).reduce((a, b) => a + b) / sedentaryPackets.length;

    final hrZ = (avgHr - baseline.meanHr) / (baseline.stdHr > 0 ? baseline.stdHr : 8.0);
    final edaZ = (avgEda - baseline.meanEda) / (baseline.stdEda > 0 ? baseline.stdEda : 0.6);

    final isWorsening = (hrZ >= config.gradualHrZThreshold) && (edaZ >= config.gradualEdaZThreshold);

    String summary;
    if (isWorsening) {
      summary = 'Noticeable gradual rise over the last 48 hours: heart rate is +${(avgHr - baseline.meanHr).toStringAsFixed(1)} bpm and skin conductance is +${(avgEda - baseline.meanEda).toStringAsFixed(1)} uS compared to baseline.';
    } else {
      summary = '48-hour vitals remain comfortably aligned with your established baseline.';
    }

    return GradualTrendResult(
      isGraduallyWorsening: isWorsening,
      summary: summary,
      meanDeviationScore: (hrZ + edaZ) / 2.0,
    );
  }
}

class GradualTrendResult {
  final bool isGraduallyWorsening;
  final String summary;
  final double meanDeviationScore;

  const GradualTrendResult({
    required this.isGraduallyWorsening,
    required this.summary,
    required this.meanDeviationScore,
  });
}
