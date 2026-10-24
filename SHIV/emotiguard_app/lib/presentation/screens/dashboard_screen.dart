import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/distress_state.dart';
import '../providers/sensor_providers.dart';
import '../widgets/distress_arc_gauge.dart';
import '../widgets/metric_sparkline_card.dart';
import '../widgets/timeframe_history_chart.dart';
import '../widgets/quick_intervention_bar.dart';
import '../widgets/mock_scenario_banner.dart';
import 'auth_screen.dart';
import 'breathing_screen.dart';
import 'journal_screen.dart';
import 'escalation_screen.dart';
import 'ble_pairing_screen.dart';
import 'settings_screen.dart';
import 'trends_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<double> _hrSparkline = [];
  final List<double> _hrvSparkline = [];
  final List<double> _edaSparkline = [];
  final List<double> _movementSparkline = [];

  void _updateSparklines(double hr, double hrv, double eda, double movement) {
    if (_hrSparkline.length > 20) _hrSparkline.removeAt(0);
    _hrSparkline.add(hr);

    if (_hrvSparkline.length > 20) _hrvSparkline.removeAt(0);
    _hrvSparkline.add(hrv);

    if (_edaSparkline.length > 20) _edaSparkline.removeAt(0);
    _edaSparkline.add(eda);

    if (_movementSparkline.length > 20) _movementSparkline.removeAt(0);
    _movementSparkline.add(movement);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sensorAsync = ref.watch(sensorStreamProvider);
    final distress = ref.watch(distressStateProvider);
    final timeframe = ref.watch(selectedTimeframeProvider);
    final historyAsync = ref.watch(historyDataProvider);
    final currentScenario = ref.watch(mockScenarioProvider);
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(currentUserSessionProvider);

    // Update sparkline buffers on each live packet
    sensorAsync.whenData((packet) {
      _updateSparklines(
        packet.heartRate,
        packet.hrv,
        packet.eda,
        packet.movementMagnitude,
      );
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session != null ? 'EmotiGuard • ${session.fullName}' : 'EmotiGuard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
                Text(
                  session != null ? '${session.deviceId} • ${settings.mockDataMode ? "Simulator" : "Hardware"}' : (settings.mockDataMode ? 'Demo Simulator Mode' : 'Connected to ESP32 Wearable'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Long-term Trends',
            icon: const Icon(Icons.insights_rounded, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrendsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'BLE Hardware Pairing',
            icon: const Icon(Icons.bluetooth_searching_rounded, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlePairingScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings & Privacy',
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Switch User / Log Out',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () {
              ref.read(currentUserSessionProvider.notifier).state = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mock Data / Hardware Mode Banner
              MockScenarioBanner(
                isMockActive: settings.mockDataMode,
                currentScenario: currentScenario,
                onToggleMockMode: (val) {
                  ref.read(settingsProvider.notifier).toggleMockMode(val);
                  ref.read(sensorRepositoryProvider).startStreaming(useMock: val);
                },
                onSelectScenario: (scenario) {
                  ref.read(mockScenarioProvider.notifier).state = scenario;
                  ref.read(mockDataSourceProvider).setScenario(scenario);
                },
                onOpenBleScreen: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlePairingScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Distress Score Arc Gauge
              DistressArcGauge(
                state: distress,
                onInterventionTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BreathingScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Four Live Metric Cards
              sensorAsync.when(
                data: (packet) {
                  const baselineHr = 72.0;
                  final hrDiff = packet.heartRate - baselineHr;
                  final hrNote = hrDiff >= 0
                      ? '+${hrDiff.toStringAsFixed(0)} bpm from baseline'
                      : '${hrDiff.toStringAsFixed(0)} bpm from baseline';

                  final activityLabel = packet.isPhysicallyActive
                      ? 'Active (${packet.movementMagnitude.toStringAsFixed(2)}g)'
                      : 'Sedentary (${packet.movementMagnitude.toStringAsFixed(2)}g)';

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      MetricSparklineCard(
                        title: 'Heart Rate',
                        value: packet.heartRate.toStringAsFixed(0),
                        unit: 'BPM',
                        baselineNote: hrNote,
                        accentColor: AppColors.heartRate,
                        icon: Icons.favorite_rounded,
                        sparklineData: _hrSparkline,
                        isPulseActive: true,
                      ),
                      MetricSparklineCard(
                        title: 'HRV (RMSSD)',
                        value: packet.hrv.toStringAsFixed(0),
                        unit: 'ms',
                        baselineNote: packet.hrv > 45 ? 'Good parasympathetic tone' : 'Vagal tone reduced',
                        accentColor: AppColors.hrvParasympathetic,
                        icon: Icons.graphic_eq_rounded,
                        sparklineData: _hrvSparkline,
                      ),
                      MetricSparklineCard(
                        title: 'Skin Conductance',
                        value: packet.eda.toStringAsFixed(1),
                        unit: 'uS',
                        baselineNote: packet.eda > 4.5 ? 'Sympathetic arousal high' : 'Steady baseline',
                        accentColor: AppColors.edaArousal,
                        icon: Icons.water_drop_outlined,
                        sparklineData: _edaSparkline,
                      ),
                      MetricSparklineCard(
                        title: 'Movement Accel',
                        value: packet.movementMagnitude.toStringAsFixed(2),
                        unit: 'g',
                        baselineNote: activityLabel,
                        accentColor: AppColors.movementAccel,
                        icon: Icons.directions_walk_rounded,
                        sparklineData: _movementSparkline,
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Sensor streaming error: $e'),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Timeframe Trend History Chart (1h, 24h, 7d)
              historyAsync.when(
                data: (history) => TimeframeHistoryChart(
                  selectedTimeframe: timeframe,
                  onTimeframeChanged: (tf) {
                    ref.read(selectedTimeframeProvider.notifier).state = tf;
                    ref.invalidate(historyDataProvider);
                  },
                  history: history,
                ),
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // 5. Quick Interventions Action Bar
              QuickInterventionBar(
                onBreatheTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BreathingScreen()),
                ),
                onJournalTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalScreen()),
                ),
                onMoodTap: () => _showQuickMoodDialog(context),
                onReachOutTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EscalationScreen()),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickMoodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Mood Check-in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you feeling in this moment?',
                style: TextStyle(fontSize: 14, color: AppColors.textLightSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMoodEmoji(ctx, '😣', 'Stressed', 1),
                  _buildMoodEmoji(ctx, '😕', 'Tense', 2),
                  _buildMoodEmoji(ctx, '😐', 'Neutral', 3),
                  _buildMoodEmoji(ctx, '🙂', 'Good', 4),
                  _buildMoodEmoji(ctx, '😌', 'Peaceful', 5),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodEmoji(BuildContext ctx, String emoji, String label, int score) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood logged: $label ($score/5). Take care of yourself!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
