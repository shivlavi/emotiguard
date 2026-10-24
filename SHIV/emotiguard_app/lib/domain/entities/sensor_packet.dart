import 'dart:math';

/// Domain entity representing a single 5-second biophysical packet from the ESP32 wearable.
class SensorPacket {
  final int timestamp; // UNIX timestamp in seconds
  final double heartRate; // Beats Per Minute (BPM) from MAX30102
  final double hrv; // Heart Rate Variability RMSSD in ms from MAX30102
  final double eda; // Electrodermal Activity / Galvanic Skin Response in microSiemens (uS)
  final double accelX; // Accelerometer X-axis in g
  final double accelY; // Accelerometer Y-axis in g
  final double accelZ; // Accelerometer Z-axis in g
  final int? checksum; // Checksum for packet integrity
  final bool isValid; // Verified checksum and sensor validity

  const SensorPacket({
    required this.timestamp,
    required this.heartRate,
    required this.hrv,
    required this.eda,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    this.checksum,
    this.isValid = true,
  });

  /// Dynamic acceleration magnitude (gravity subtracted).
  /// Normal quiet resting is close to 0.0g - 0.1g.
  /// Walking is 0.2g - 0.6g. Intense motion is > 1.0g.
  double get movementMagnitude {
    final rawTotal = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    // Subtract earth gravity (approx 1.0g or 9.8 m/s^2 normalized)
    return (rawTotal > 1.0) ? (rawTotal - 1.0) : (1.0 - rawTotal);
  }

  /// Whether user is currently physically active vs sedentary/resting.
  bool get isPhysicallyActive => movementMagnitude > 0.35;

  Map<String, dynamic> toJson() => {
        'ts': timestamp,
        'hr': heartRate,
        'hrv': hrv,
        'eda': eda,
        'accel': {
          'x': accelX,
          'y': accelY,
          'z': accelZ,
        },
        if (checksum != null) 'cs': checksum,
      };

  factory SensorPacket.fromJson(Map<String, dynamic> json) {
    final accel = json['accel'] is Map<String, dynamic>
        ? json['accel'] as Map<String, dynamic>
        : {'x': 0.0, 'y': 0.0, 'z': 1.0};

    final ts = json['ts'] is num ? (json['ts'] as num).toInt() : DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hr = (json['hr'] as num?)?.toDouble() ?? 72.0;
    final hrv = (json['hrv'] as num?)?.toDouble() ?? 50.0;
    final eda = (json['eda'] as num?)?.toDouble() ?? 2.2;
    final x = (accel['x'] as num?)?.toDouble() ?? 0.0;
    final y = (accel['y'] as num?)?.toDouble() ?? 0.0;
    final z = (accel['z'] as num?)?.toDouble() ?? 1.0;
    final cs = (json['cs'] as num?)?.toInt();

    return SensorPacket(
      timestamp: ts,
      heartRate: hr,
      hrv: hrv,
      eda: eda,
      accelX: x,
      accelY: y,
      accelZ: z,
      checksum: cs,
      isValid: true,
    );
  }

  /// Creates a copy with modified fields
  SensorPacket copyWith({
    int? timestamp,
    double? heartRate,
    double? hrv,
    double? eda,
    double? accelX,
    double? accelY,
    double? accelZ,
    int? checksum,
    bool? isValid,
  }) {
    return SensorPacket(
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      hrv: hrv ?? this.hrv,
      eda: eda ?? this.eda,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      checksum: checksum ?? this.checksum,
      isValid: isValid ?? this.isValid,
    );
  }
}
