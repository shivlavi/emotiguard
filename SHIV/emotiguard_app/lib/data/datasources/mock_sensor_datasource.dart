import 'dart:async';
import 'dart:math';
import '../../domain/entities/sensor_packet.dart';

enum MockScenario {
  restingCalm,
  workStressRising,
  acuteDistressSpike,
  physicalExercise,
  breathingRecovery,
}

/// Emulates real ESP32 wearable sensor packets streaming every 5 seconds.
/// Allows full UI testing, distress algorithm verification, and dashboard demos
/// even without the ESP32 hardware connected.
class MockSensorDataSource {
  final Random _rng = Random();
  Timer? _ticker;
  final StreamController<SensorPacket> _streamController = StreamController<SensorPacket>.broadcast();

  MockScenario currentScenario = MockScenario.restingCalm;
  double _currentHr = 72.0;
  double _currentHrv = 52.0;
  double _currentEda = 2.2;
  double _accelX = 0.02;
  double _accelY = 0.04;
  double _accelZ = 0.98;

  Stream<SensorPacket> get sensorStream => _streamController.stream;

  void startStreaming({Duration interval = const Duration(seconds: 5)}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) => _generateNextPacket());
    // Emit initial packet immediately
    _generateNextPacket();
  }

  void stopStreaming() {
    _ticker?.cancel();
    _ticker = null;
  }

  void setScenario(MockScenario scenario) {
    currentScenario = scenario;
    _generateNextPacket();
  }

  void _generateNextPacket() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    switch (currentScenario) {
      case MockScenario.restingCalm:
        // Gentle resting vitals with small natural respiratory sinus arrhythmia
        _currentHr = _driftTowards(target: 70.0 + _rng.nextDouble() * 4, current: _currentHr, step: 1.5);
        _currentHrv = _driftTowards(target: 50.0 + _rng.nextDouble() * 8, current: _currentHrv, step: 2.0);
        _currentEda = _driftTowards(target: 2.1 + _rng.nextDouble() * 0.3, current: _currentEda, step: 0.1);
        _accelX = 0.01 + (_rng.nextDouble() - 0.5) * 0.02;
        _accelY = 0.02 + (_rng.nextDouble() - 0.5) * 0.02;
        _accelZ = 0.99 + (_rng.nextDouble() - 0.5) * 0.03;
        break;

      case MockScenario.workStressRising:
        // Gradual buildup of sympathetic tension while seated
        _currentHr = _driftTowards(target: 92.0 + _rng.nextDouble() * 6, current: _currentHr, step: 2.5);
        _currentHrv = _driftTowards(target: 26.0 + _rng.nextDouble() * 5, current: _currentHrv, step: 3.0);
        _currentEda = _driftTowards(target: 5.6 + _rng.nextDouble() * 0.8, current: _currentEda, step: 0.3);
        _accelX = 0.03 + (_rng.nextDouble() - 0.5) * 0.04;
        _accelY = 0.04 + (_rng.nextDouble() - 0.5) * 0.04;
        _accelZ = 0.98 + (_rng.nextDouble() - 0.5) * 0.04;
        break;

      case MockScenario.acuteDistressSpike:
        // High emotional distress / panic arousal while stationary
        _currentHr = _driftTowards(target: 114.0 + _rng.nextDouble() * 10, current: _currentHr, step: 4.0);
        _currentHrv = _driftTowards(target: 17.0 + _rng.nextDouble() * 4, current: _currentHrv, step: 3.5);
        _currentEda = _driftTowards(target: 8.4 + _rng.nextDouble() * 1.2, current: _currentEda, step: 0.6);
        _accelX = 0.05 + (_rng.nextDouble() - 0.5) * 0.06;
        _accelY = 0.06 + (_rng.nextDouble() - 0.5) * 0.06;
        _accelZ = 0.97 + (_rng.nextDouble() - 0.5) * 0.06;
        break;

      case MockScenario.physicalExercise:
        // Heavy movement: HR & EDA rise, but movement > 0.6g dampens distress score!
        _currentHr = _driftTowards(target: 132.0 + _rng.nextDouble() * 10, current: _currentHr, step: 5.0);
        _currentHrv = _driftTowards(target: 28.0 + _rng.nextDouble() * 6, current: _currentHrv, step: 2.0);
        _currentEda = _driftTowards(target: 6.8 + _rng.nextDouble() * 1.0, current: _currentEda, step: 0.4);
        _accelX = 0.65 + (_rng.nextDouble() - 0.5) * 0.5;
        _accelY = 0.72 + (_rng.nextDouble() - 0.5) * 0.5;
        _accelZ = 1.45 + (_rng.nextDouble() - 0.5) * 0.6;
        break;

      case MockScenario.breathingRecovery:
        // Parasympathetic activation post-guided breathing
        _currentHr = _driftTowards(target: 64.0 + _rng.nextDouble() * 3, current: _currentHr, step: 2.5);
        _currentHrv = _driftTowards(target: 74.0 + _rng.nextDouble() * 10, current: _currentHrv, step: 4.0);
        _currentEda = _driftTowards(target: 1.8 + _rng.nextDouble() * 0.2, current: _currentEda, step: 0.2);
        _accelX = 0.01 + (_rng.nextDouble() - 0.5) * 0.01;
        _accelY = 0.01 + (_rng.nextDouble() - 0.5) * 0.01;
        _accelZ = 1.00 + (_rng.nextDouble() - 0.5) * 0.02;
        break;
    }

    // Calculate simple XOR checksum matching ESP32 firmware
    final packet = SensorPacket(
      timestamp: now,
      heartRate: double.parse(_currentHr.toStringAsFixed(1)),
      hrv: double.parse(_currentHrv.toStringAsFixed(1)),
      eda: double.parse(_currentEda.toStringAsFixed(2)),
      accelX: double.parse(_accelX.toStringAsFixed(3)),
      accelY: double.parse(_accelY.toStringAsFixed(3)),
      accelZ: double.parse(_accelZ.toStringAsFixed(3)),
      checksum: _calculateChecksum(now, _currentHr, _currentEda),
      isValid: true,
    );

    if (!_streamController.isClosed) {
      _streamController.add(packet);
    }
  }

  double _driftTowards({required double target, required double current, required double step}) {
    if ((target - current).abs() <= step) return target;
    return current + (target > current ? step : -step);
  }

  int _calculateChecksum(int ts, double hr, double eda) {
    return (ts ^ hr.toInt() ^ (eda * 100).toInt()) & 0xFFFF;
  }

  /// Generates synthetic historical packets for 1-hour, 24-hour, and 7-day sparklines
  List<SensorPacket> generateHistory({required Duration duration, int sampleCount = 40}) {
    final List<SensorPacket> history = [];
    final now = DateTime.now();
    final intervalSeconds = duration.inSeconds ~/ sampleCount;

    for (int i = sampleCount; i >= 0; i--) {
      final sampleTime = now.subtract(Duration(seconds: i * intervalSeconds));
      final ts = sampleTime.millisecondsSinceEpoch ~/ 1000;

      // Realistic circadian fluctuation
      final hourOfDay = sampleTime.hour;
      final circadianOffset = sin((hourOfDay - 6) / 24 * 2 * pi) * 6; // Peak afternoon, low nighttime
      final noiseHr = (_rng.nextDouble() - 0.5) * 5;
      final hr = (70.0 + circadianOffset + noiseHr).clamp(55.0, 120.0);

      final edaNoise = (_rng.nextDouble() - 0.5) * 0.6;
      final eda = (2.2 + (circadianOffset * 0.08) + edaNoise).clamp(1.2, 7.5);

      final hrv = (55.0 - (circadianOffset * 0.8) + (_rng.nextDouble() - 0.5) * 8).clamp(20.0, 85.0);

      history.add(SensorPacket(
        timestamp: ts,
        heartRate: double.parse(hr.toStringAsFixed(1)),
        hrv: double.parse(hrv.toStringAsFixed(1)),
        eda: double.parse(eda.toStringAsFixed(2)),
        accelX: 0.02,
        accelY: 0.03,
        accelZ: 0.99,
        checksum: _calculateChecksum(ts, hr, eda),
        isValid: true,
      ));
    }

    return history;
  }

  void dispose() {
    _ticker?.cancel();
    _streamController.close();
  }
}
