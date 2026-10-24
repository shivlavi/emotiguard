/// User's learned physiological baseline over 7 days.
/// Used to calculate personalized z-scores rather than arbitrary one-size-fits-all clinical cutoffs.
class BaselineProfile {
  final double meanHr;
  final double stdHr;
  final double meanEda;
  final double stdEda;
  final double meanHrv;
  final double stdHrv;
  final double meanRestingMovement;
  final int daysOfData;
  final bool isCalibrated;
  final DateTime lastUpdated;

  const BaselineProfile({
    this.meanHr = 72.0,
    this.stdHr = 8.5,
    this.meanEda = 2.2,
    this.stdEda = 0.7,
    this.meanHrv = 52.0,
    this.stdHrv = 14.0,
    this.meanRestingMovement = 0.05,
    this.daysOfData = 1,
    this.isCalibrated = false,
    required this.lastUpdated,
  });

  factory BaselineProfile.defaults() {
    return BaselineProfile(
      meanHr: 72.0,
      stdHr: 8.5,
      meanEda: 2.2,
      stdEda: 0.7,
      meanHrv: 52.0,
      stdHrv: 14.0,
      meanRestingMovement: 0.05,
      daysOfData = 0,
      isCalibrated: false,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'meanHr': meanHr,
        'stdHr': stdHr,
        'meanEda': meanEda,
        'stdEda': stdEda,
        'meanHrv': meanHrv,
        'stdHrv': stdHrv,
        'meanRestingMovement': meanRestingMovement,
        'daysOfData': daysOfData,
        'isCalibrated': isCalibrated,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory BaselineProfile.fromJson(Map<String, dynamic> json) {
    return BaselineProfile(
      meanHr: (json['meanHr'] as num?)?.toDouble() ?? 72.0,
      stdHr: (json['stdHr'] as num?)?.toDouble() ?? 8.5,
      meanEda: (json['meanEda'] as num?)?.toDouble() ?? 2.2,
      stdEda: (json['stdEda'] as num?)?.toDouble() ?? 0.7,
      meanHrv: (json['meanHrv'] as num?)?.toDouble() ?? 52.0,
      stdHrv: (json['stdHrv'] as num?)?.toDouble() ?? 14.0,
      meanRestingMovement: (json['meanRestingMovement'] as num?)?.toDouble() ?? 0.05,
      daysOfData: (json['daysOfData'] as num?)?.toInt() ?? 1,
      isCalibrated: json['isCalibrated'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  BaselineProfile copyWith({
    double? meanHr,
    double? stdHr,
    double? meanEda,
    double? stdEda,
    double? meanHrv,
    double? stdHrv,
    double? meanRestingMovement,
    int? daysOfData,
    bool? isCalibrated,
    DateTime? lastUpdated,
  }) {
    return BaselineProfile(
      meanHr: meanHr ?? this.meanHr,
      stdHr: stdHr ?? this.stdHr,
      meanEda: meanEda ?? this.meanEda,
      stdEda: stdEda ?? this.stdEda,
      meanHrv: meanHrv ?? this.meanHrv,
      stdHrv: stdHrv ?? this.stdHrv,
      meanRestingMovement: meanRestingMovement ?? this.meanRestingMovement,
      daysOfData: daysOfData ?? this.daysOfData,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
