import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/ble_constants.dart';
import '../../domain/entities/sensor_packet.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BleSensorDataSource {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription? _scanSub;
  StreamSubscription? _charSub;
  StreamSubscription? _connectionStateSub;

  final StreamController<SensorPacket> _packetController = StreamController<SensorPacket>.broadcast();
  final StreamController<BleConnectionState> _stateController = StreamController<BleConnectionState>.broadcast();
  final StreamController<List<ScanResult>> _devicesController = StreamController<List<ScanResult>>.broadcast();

  BleConnectionState _currentState = BleConnectionState.disconnected;
  String _incomingBuffer = '';

  Stream<SensorPacket> get sensorStream => _packetController.stream;
  Stream<BleConnectionState> get stateStream => _stateController.stream;
  Stream<List<ScanResult>> get discoveredDevicesStream => _devicesController.stream;
  BleConnectionState get currentState => _currentState;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  void _setState(BleConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Start scanning for EmotiGuard ESP32 BLE Wearable
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      _setState(BleConnectionState.scanning);

      // Listen to scan results
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!_devicesController.isClosed) {
          _devicesController.add(results);
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: timeout,
      );

      await Future.delayed(timeout);
      if (_currentState == BleConnectionState.scanning) {
        _setState(BleConnectionState.disconnected);
      }
    } catch (e) {
      _setState(BleConnectionState.error);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_currentState == BleConnectionState.scanning) {
      _setState(BleConnectionState.disconnected);
    }
  }

  /// Connect to ESP32 Wearable
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _setState(BleConnectionState.connecting);
      _connectedDevice = device;

      // Monitor hardware connection state
      _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _setState(BleConnectionState.connected);
        } else if (state == BluetoothConnectionState.disconnected) {
          _setState(BleConnectionState.disconnected);
          _charSub?.cancel();
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: true,
      );

      // Request higher MTU for clean JSON payloads
      try {
        await device.requestMtu(256);
      } catch (_) {
        // MTU request might not be supported on all iOS/Android versions
      }

      // Discover GATT services
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toUpperCase() == BleConstants.serviceUuid.toUpperCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toUpperCase() == BleConstants.sensorDataCharUuid.toUpperCase()) {
              _notifyCharacteristic = char;
              await _subscribeToNotifications(char);
              _setState(BleConnectionState.connected);
              return true;
            }
          }
        }
      }

      return true;
    } catch (e) {
      _setState(BleConnectionState.error);
      return false;
    }
  }

  Future<void> _subscribeToNotifications(BluetoothCharacteristic char) async {
    await char.setNotifyValue(true);
    _charSub?.cancel();
    _charSub = char.onValueReceived.listen((bytes) {
      _handleRawBytes(bytes);
    });
  }

  void _handleRawBytes(List<int> bytes) {
    try {
      final chunk = utf8.decode(bytes);
      _incomingBuffer += chunk;

      // Check for newline or complete JSON delimiter
      if (_incomingBuffer.contains('\n') || (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}'))) {
        final rawJson = _incomingBuffer.trim();
        _incomingBuffer = '';

        final Map<String, dynamic> parsed = jsonDecode(rawJson);
        final packet = SensorPacket.fromJson(parsed);

        // Verify simple checksum if provided
        if (packet.checksum != null) {
          final computedCs = (packet.timestamp ^ packet.heartRate.toInt() ^ (packet.eda * 100).toInt()) & 0xFFFF;
          if (computedCs != packet.checksum) {
            // Checksum failed, discard corrupted packet
            return;
          }
        }

        if (!_packetController.isClosed) {
          _packetController.add(packet);
        }
      }
    } catch (_) {
      // If parsing fails, reset buffer if it grows too large
      if (_incomingBuffer.length > 512) {
        _incomingBuffer = '';
      }
    }
  }

  Future<void> disconnect() async {
    _charSub?.cancel();
    _connectionStateSub?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _setState(BleConnectionState.disconnected);
  }

  void dispose() {
    _scanSub?.cancel();
    _charSub?.cancel();
    _connectionStateSub?.cancel();
    _packetController.close();
    _stateController.close();
    _devicesController.close();
  }
}
