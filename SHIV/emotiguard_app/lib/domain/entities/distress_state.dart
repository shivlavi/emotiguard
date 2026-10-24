enum DistressLevel {
  calm,      // 0 - 29: Parasympathetic dominance, steady baseline
  mild,      // 30 - 54: Low level tension or slight arousal
  elevated,  // 55 - 79: Significant sympathetic activation (stress/anxiety)
  acute      // 80 - 100: Sustained high arousal, physiological distress
}

/// Represents the evaluated distress state at a point in time
class DistressState {
  final double score; // 0.0 to 100.0
  final DistressLevel level;
  final String label;
  final String friendlySummary;
  final double hrDeviationRatio;
  final double edaElevationRatio;
  final double hrvSuppressionRatio;
  final double activityDampener; // High motion lowers false positives
  final DateTime timestamp;

  const DistressState({
    required this.score,
    required this.level,
    required this.label,
    required this.friendlySummary,
    required this.hrDeviationRatio,
    required this.edaElevationRatio,
    required this.hrvSuppressionRatio,
    required this.activityDampener,
    required this.timestamp,
  });

  /// Factory for a calm resting state
  factory DistressState.calm() {
    return DistressState(
      score: 18.0,
      level: DistressLevel.calm,
      label: 'Calm & Centered',
      friendlySummary: 'Vitals are steady within your typical baseline zone.',
      hrDeviationRatio: 0.0,
      edaElevationRatio: 0.0,
      hrvSuppressionRatio: 0.0,
      activityDampener: 1.0,
      timestamp: DateTime.now(),
    );
  }

  bool get requiresGentleIntervention => score >= 55.0;
  bool get requiresEscalationPrompt => score >= 80.0;
}
