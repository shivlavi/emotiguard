import '../../domain/entities/user_settings.dart';
import '../../domain/entities/trusted_contact.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings();
  Future<void> saveSettings(UserSettings settings);
  Future<void> addTrustedContact(TrustedContact contact);
  Future<void> removeTrustedContact(String contactId);
  Future<void> setMockMode(bool enabled);
  Future<void> setLanguage(String languageCode);
  Future<void> setSensitivity(SensitivityLevel level);
}
