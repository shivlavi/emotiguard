import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/scoring/distress_scoring_engine.dart';
import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/distress_state.dart';
import '../../domain/entities/baseline_profile.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../data/datasources/mock_sensor_datasource.dart';
import '../../data/datasources/ble_sensor_datasource.dart';
import '../../data/datasources/local_database_service.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';

// --- Singletons / Core Instances ---

final mockDataSourceProvider = Provider<MockSensorDataSource>((ref) {
  final ds = MockSensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

final bleDataSourceProvider = Provider<BleSensorDataSource>((ref) {
  final ds = BleSensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

final localDbProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final scoringEngineProvider = Provider<DistressScoringEngine>((ref) {
  return DistressScoringEngine();
});

// --- Repository Providers ---

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  final bleDs = ref.watch(bleDataSourceProvider);
  final localDb = ref.watch(localDbProvider);
  final engine = ref.watch(scoringEngineProvider);

  final repo = SensorRepositoryImpl(
    mockDataSource: mockDs,
    bleDataSource: bleDs,
    localDatabase: localDb,
    scoringEngine: engine,
  );

  // Start with mock streaming by default for immediate preview
  repo.startStreaming(useMock: true);

  ref.onDispose(() => repo.dispose());
  return repo;
});

// --- State Providers ---

final mockScenarioProvider = StateProvider<MockScenario>((ref) {
  return MockScenario.restingCalm;
});

enum ChartTimeframe { oneHour, twentyFourHours, sevenDays }

final selectedTimeframeProvider = StateProvider<ChartTimeframe>((ref) {
  return ChartTimeframe.oneHour;
});

final baselineProfileProvider = StateProvider<BaselineProfile>((ref) {
  return BaselineProfile.defaults();
});

// --- Stream & Reactive Evaluation Providers ---

final sensorStreamProvider = StreamProvider<SensorPacket>((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.sensorStream;
});

/// Evaluates distress state reactively on every 5-second sensor packet tick
final distressStateProvider = Provider<DistressState>((ref) {
  final sensorAsync = ref.watch(sensorStreamProvider);
  final baseline = ref.watch(baselineProfileProvider);
  final scoringEngine = ref.watch(scoringEngineProvider);

  return sensorAsync.when(
    data: (packet) => scoringEngine.evaluatePacket(packet: packet, baseline: baseline),
    loading: () => DistressState.calm(),
    error: (_, __) => DistressState.calm(),
  );
});

/// Provides historical sensor data for charts based on selected timeframe
final historyDataProvider = FutureProvider<List<SensorPacket>>((ref) async {
  final repo = ref.watch(sensorRepositoryProvider);
  final timeframe = ref.watch(selectedTimeframeProvider);

  Duration duration;
  switch (timeframe) {
    case ChartTimeframe.oneHour:
      duration = const Duration(hours: 1);
      break;
    case ChartTimeframe.twentyFourHours:
      duration = const Duration(hours: 24);
      break;
    case ChartTimeframe.sevenDays:
      duration = const Duration(days: 7);
      break;
  }

  return await repo.getHistory(duration: duration);
});

// --- Settings & Preferences Providers ---

class SettingsNotifier extends StateNotifier<UserSettings> {
  final SharedPreferences? _prefs;

  SettingsNotifier(this._prefs) : super(const UserSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString('emotiguard_settings');
    if (jsonStr != null) {
      try {
        // Simple mock load
      } catch (_) {}
    }
  }

  void toggleMockMode(bool enabled) {
    state = state.copyWith(mockDataMode: enabled);
  }

  void setSensitivity(SensitivityLevel level) {
    state = state.copyWith(sensitivity: level);
  }

  void setLanguage(String lang) {
    state = state.copyWith(selectedLanguage: lang);
  }

  void setCloudSync(bool enabled) {
    state = state.copyWith(cloudSyncEnabled: enabled);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier(null);
});
