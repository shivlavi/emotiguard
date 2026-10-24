import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/ble_sensor_datasource.dart';
import '../providers/sensor_providers.dart';

class BlePairingScreen extends ConsumerStatefulWidget {
  const BlePairingScreen({super.key});

  @override
  ConsumerState<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends ConsumerState<BlePairingScreen> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    setState(() => _isScanning = true);
    final bleDs = ref.read(bleDataSourceProvider);

    bleDs.discoveredDevicesStream.listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
      }
    });

    await bleDs.startScan();
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  void _connect(BluetoothDevice device) async {
    final bleDs = ref.read(bleDataSourceProvider);
    final scaffold = ScaffoldMessenger.of(context);

    scaffold.showSnackBar(
      SnackBar(content: Text('Connecting to ${device.platformName.isNotEmpty ? device.platformName : "ESP32 Wearable"}...')),
    );

    final success = await bleDs.connect(device);
    if (success) {
      ref.read(settingsProvider.notifier).toggleMockMode(false);
      ref.read(sensorRepositoryProvider).startStreaming(useMock: false);
      if (mounted) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Connected to EmotiGuard Wearable via BLE!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Could not establish GATT connection. Ensure ESP32 is powered on.'),
            backgroundColor: AppColors.statusHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bleDs = ref.watch(bleDataSourceProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable Connection'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop_rounded : Icons.refresh_rounded),
            onPressed: _isScanning ? () => bleDs.stopScan() : _startScan,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection Mode Banner
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Simulator / Hardware Mode',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Switch.adaptive(
                        value: settings.mockDataMode,
                        activeColor: AppColors.sageGreen,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).toggleMockMode(val);
                          ref.read(sensorRepositoryProvider).startStreaming(useMock: val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.mockDataMode
                        ? 'Currently using Mock Sensor Mode. Switch off to bind directly to ESP32 hardware via Bluetooth LE.'
                        : 'Currently in Hardware Mode. BLE GATT notifications active.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Discovered BLE Devices Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Bluetooth Devices',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_scanResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_searching_rounded, size: 36, color: AppColors.skyBlue),
                    const SizedBox(height: 12),
                    Text(
                      _isScanning
                          ? 'Searching for EmotiGuard ESP32 wearable...'
                          : 'No BLE devices found. Ensure ESP32 is powered and broadcasting service UUID 19B1.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._scanResults.map((result) {
                final name = result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device';
                final isEmotiGuard = name.contains('EmotiGuard') ||
                    result.advertisementData.serviceUuids.any((u) => u.toString().toUpperCase().contains('19B1'));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEmotiGuard ? AppColors.primaryTeal : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isEmotiGuard ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isEmotiGuard ? AppColors.primaryTeal : AppColors.skyBlue).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bluetooth_audio_rounded,
                          color: isEmotiGuard ? AppColors.primaryTeal : AppColors.skyBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RSSI: ${result.rssi} dBm • ${result.device.remoteId.str}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _connect(result.device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Connect', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
