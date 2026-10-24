import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/user_settings.dart';
import '../../data/datasources/local_database_service.dart';
import '../providers/sensor_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportData(BuildContext context) async {
    final db = LocalDatabaseService();
    final csv = await db.exportCsv();
    await Share.share(csv, subject: 'EmotiGuard_Biometrics_Export.csv');
  }

  void _confirmDeleteAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Stored Data?'),
        content: const Text(
          'This will permanently erase all local encrypted biometrics, learned baselines, and private reflections from this device.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusHigh, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = LocalDatabaseService();
              await db.deleteAllUserData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local encrypted data has been permanently deleted.'),
                    backgroundColor: AppColors.statusHigh,
                  ),
                );
              }
            },
            child: const Text('Erase Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Distress Sensitivity
            _buildSectionHeader('Distress Detection Sensitivity', isDark),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adjust how quickly the system flags elevated physiological arousal:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<SensitivityLevel>(
                    segments: const [
                      ButtonSegment(value: SensitivityLevel.low, label: Text('Low')),
                      ButtonSegment(value: SensitivityLevel.medium, label: Text('Medium')),
                      ButtonSegment(value: SensitivityLevel.high, label: Text('High')),
                    ],
                    selected: {settings.sensitivity},
                    onSelectionChanged: (val) {
                      ref.read(settingsProvider.notifier).setSensitivity(val.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Language Switcher (English / Hindi)
            _buildSectionHeader('Language / भाषा', isDark),
            Container(
              decoration: _cardDecoration(isDark),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('English'),
                    subtitle: const Text('Standard English interface'),
                    value: 'en',
                    groupValue: settings.selectedLanguage,
                    activeColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      if (val != null) ref.read(settingsProvider.notifier).setLanguage(val);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('हिंदी (Hindi)'),
                    subtitle: const Text('हिंदी भाषा इंटरफ़ेस'),
                    value: 'hi',
                    groupValue: settings.selectedLanguage,
                    activeColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      if (val != null) ref.read(settingsProvider.notifier).setLanguage(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Privacy & Cloud Sync Controls
            _buildSectionHeader('Privacy & Data Governance', isDark),
            Container(
              decoration: _cardDecoration(isDark),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Cloud Sync & Backup'),
                    subtitle: const Text('When disabled, data NEVER leaves your phone.'),
                    value: settings.cloudSyncEnabled,
                    activeColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setCloudSync(val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Quiet Hours (10 PM - 7 AM)'),
                    subtitle: const Text('Suppress gentle intervention prompts during sleep.'),
                    value: settings.quietHoursEnabled,
                    activeColor: AppColors.primaryTeal,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Data Export & Erase
            _buildSectionHeader('Data Portability & Control', isDark),
            Container(
              decoration: _cardDecoration(isDark),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.primaryTeal),
                    title: const Text('Export Biometrics as CSV'),
                    subtitle: const Text('Download raw time-series data for personal records.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _exportData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.statusHigh),
                    title: const Text(
                      'Delete All My Data',
                      style: TextStyle(color: AppColors.statusHigh, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Purges all local SQLite records and baseline weights.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _confirmDeleteAllData(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1.2,
      ),
    );
  }
}
