import 'dart:async';
import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/distress_state.dart';
import '../../domain/entities/baseline_profile.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../core/scoring/distress_scoring_engine.dart';
import '../datasources/mock_sensor_datasource.dart';
import '../datasources/ble_sensor_datasource.dart';
import '../datasources/local_database_service.dart';

class SensorRepositoryImpl implements SensorRepository {
  final MockSensorDataSource mockDataSource;
  final BleSensorDataSource bleDataSource;
  final LocalDatabaseService localDatabase;
  final DistressScoringEngine scoringEngine;

  bool _isUsingMock = true;
  final StreamController<SensorPacket> _unifiedStreamController = StreamController<SensorPacket>.broadcast();
  StreamSubscription? _mockSub;
  StreamSubscription? _bleSub;

  SensorRepositoryImpl({
    required this.mockDataSource,
    required this.bleDataSource,
    required this.localDatabase,
    required this.scoringEngine,
  }) {
    _initSubscribers();
  }

  void _initSubscribers() {
    _mockSub = mockDataSource.sensorStream.listen((packet) {
      if (_isUsingMock && !_unifiedStreamController.isClosed) {
        _unifiedStreamController.add(packet);
      }
    });

    _bleSub = bleDataSource.sensorStream.listen((packet) {
      if (!_isUsingMock && !_unifiedStreamController.isClosed) {
        _unifiedStreamController.add(packet);
      }
    });
  }

  @override
  Stream<SensorPacket> get sensorStream => _unifiedStreamController.stream;

  @override
  Stream<BleConnectionState> get bleStateStream => bleDataSource.stateStream;

  @override
  BleConnectionState get currentBleState => bleDataSource.currentState;

  @override
  void startStreaming({bool useMock = true}) {
    _isUsingMock = useMock;
    if (_isUsingMock) {
      mockDataSource.startStreaming();
    }
  }

  @override
  void stopStreaming() {
    mockDataSource.stopStreaming();
  }

  @override
  void setMockScenario(MockScenario scenario) {
    mockDataSource.setScenario(scenario);
  }

  @override
  Future<void> startBleScan() => bleDataSource.startScan();

  @override
  Future<void> stopBleScan() => bleDataSource.stopScan();

  @override
  Future<bool> connectToBleDevice(dynamic device) => bleDataSource.connect(device);

  @override
  Future<void> disconnectBle() => bleDataSource.disconnect();

  @override
  DistressState evaluateLatest(SensorPacket packet, BaselineProfile baseline) {
    return scoringEngine.evaluatePacket(packet: packet, baseline: baseline);
  }

  @override
  Future<List<SensorPacket>> getHistory({required Duration duration}) async {
    // If using mock, return synthetic realistic data points for instant demo
    if (_isUsingMock) {
      return mockDataSource.generateHistory(duration: duration);
    }
    return localDatabase.getRecentHistory(duration: duration);
  }

  @override
  Future<void> persistPacket(SensorPacket packet) async {
    await localDatabase.saveSensorPacket(packet);
  }

  void dispose() {
    _mockSub?.cancel();
    _bleSub?.cancel();
    _unifiedStreamController.close();
  }
}
