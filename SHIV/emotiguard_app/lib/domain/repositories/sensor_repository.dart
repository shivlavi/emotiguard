import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/distress_state.dart';
import '../../domain/entities/baseline_profile.dart';
import '../../data/datasources/ble_sensor_datasource.dart';
import '../../data/datasources/mock_sensor_datasource.dart';

abstract class SensorRepository {
  Stream<SensorPacket> get sensorStream;
  Stream<BleConnectionState> get bleStateStream;
  BleConnectionState get currentBleState;

  void startStreaming({bool useMock = true});
  void stopStreaming();
  void setMockScenario(MockScenario scenario);

  Future<void> startBleScan();
  Future<void> stopBleScan();
  Future<bool> connectToBleDevice(dynamic device);
  Future<void> disconnectBle();

  DistressState evaluateLatest(SensorPacket packet, BaselineProfile baseline);
  Future<List<SensorPacket>> getHistory({required Duration duration});
  Future<void> persistPacket(SensorPacket packet);
}
