import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/mock_sensor_datasource.dart';

class MockScenarioBanner extends StatelessWidget {
  final bool isMockActive;
  final MockScenario currentScenario;
  final ValueChanged<bool> onToggleMockMode;
  final ValueChanged<MockScenario> onSelectScenario;
  final VoidCallback onOpenBleScreen;

  const MockScenarioBanner({
    super.key,
    required this.isMockActive,
    required this.currentScenario,
    required this.onToggleMockMode,
    required this.onSelectScenario,
    required this.onOpenBleScreen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isMockActive
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMockActive
              ? AppColors.sageGreen.withOpacity(0.35)
              : AppColors.skyBlue.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isMockActive ? Icons.science_outlined : Icons.bluetooth_connected_rounded,
                    size: 18,
                    color: isMockActive ? AppColors.sageGreen : AppColors.skyBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMockActive ? 'Mock Data Simulator' : 'ESP32 Wearable Connected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMockActive ? AppColors.sageGreen : AppColors.skyBlue,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    isMockActive ? 'Simulating' : 'Hardware',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch.adaptive(
                    value: isMockActive,
                    activeColor: AppColors.sageGreen,
                    onChanged: onToggleMockMode,
                  ),
                ],
              ),
            ],
          ),
          if (isMockActive) ...[
            const SizedBox(height: 8),
            Text(
              'Select a scenario to simulate biometrics in real time:',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildScenarioChip(
                    label: 'Resting Calm',
                    scenario: MockScenario.restingCalm,
                    isSelected: currentScenario == MockScenario.restingCalm,
                  ),
                  const SizedBox(width: 6),
                  _buildScenarioChip(
                    label: 'Work Stress',
                    scenario: MockScenario.workStressRising,
                    isSelected: currentScenario == MockScenario.workStressRising,
                  ),
                  const SizedBox(width: 6),
                  _buildScenarioChip(
                    label: 'Distress Spike',
                    scenario: MockScenario.acuteDistressSpike,
                    isSelected: currentScenario == MockScenario.acuteDistressSpike,
                  ),
                  const SizedBox(width: 6),
                  _buildScenarioChip(
                    label: 'Workout (Active)',
                    scenario: MockScenario.physicalExercise,
                    isSelected: currentScenario == MockScenario.physicalExercise,
                  ),
                  const SizedBox(width: 6),
                  _buildScenarioChip(
                    label: 'Post-Breathing',
                    scenario: MockScenario.breathingRecovery,
                    isSelected: currentScenario == MockScenario.breathingRecovery,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Listening for 5-sec packets on GATT 19B1...',
                  style: TextStyle(fontSize: 11, color: AppColors.textLightSecondary),
                ),
                TextButton(
                  onPressed: onOpenBleScreen,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Manage Device', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioChip({
    required String label,
    required MockScenario scenario,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelectScenario(scenario),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sageGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.sageGreen : AppColors.borderLight.withOpacity(0.8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textLightSecondary,
          ),
        ),
      ),
    );
  }
}
