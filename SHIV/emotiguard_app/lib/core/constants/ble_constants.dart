class BleConstants {
  // ESP32 EmotiGuard GATT Service & Characteristic UUIDs
  static const String serviceUuid = '19B10000-E8F2-537E-4F6C-D104768A1214';
  static const String sensorDataCharUuid = '19B10001-E8F2-537E-4F6C-D104768A1214';
  static const String commandCharUuid = '19B10002-E8F2-537E-4F6C-D104768A1214';

  static const String deviceNamePrefix = 'EmotiGuard';
  static const int packetIntervalSeconds = 5;
  static const int scanTimeoutSeconds = 12;
}
