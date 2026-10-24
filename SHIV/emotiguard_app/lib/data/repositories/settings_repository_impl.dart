import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/trusted_contact.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _keySettings = 'emotiguard_settings';
  final SharedPreferences prefs;

  SettingsRepositoryImpl({required this.prefs});

  @override
  Future<UserSettings> getSettings() async {
    final raw = prefs.getString(_keySettings);
    if (raw == null) {
      // Default initial settings with mock mode ON for immediate zero-config demo
      return const UserSettings(
        mockDataMode: true,
        cloudSyncEnabled: false,
        sensitivity: SensitivityLevel.medium,
        selectedLanguage: 'en',
      );
    }
    try {
      return UserSettings.fromJson(jsonDecode(raw));
    } catch (_) {
      return const UserSettings();
    }
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> addTrustedContact(TrustedContact contact) async {
    final current = await getSettings();
    final updatedContacts = List<TrustedContact>.from(current.trustedContacts)..add(contact);
    await saveSettings(current.copyWith(trustedContacts: updatedContacts));
  }

  @override
  Future<void> removeTrustedContact(String contactId) async {
    final current = await getSettings();
    final updatedContacts = current.trustedContacts.where((c) => c.id != contactId).toList();
    await saveSettings(current.copyWith(trustedContacts: updatedContacts));
  }

  @override
  Future<void> setMockMode(bool enabled) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(mockDataMode: enabled));
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(selectedLanguage: languageCode));
  }

  @override
  Future<void> setSensitivity(SensitivityLevel level) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(sensitivity: level));
  }
}
