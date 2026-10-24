import 'trusted_contact.dart';

enum SensitivityLevel { low, medium, high }

class UserSettings {
  final SensitivityLevel sensitivity;
  final bool mockDataMode;
  final bool cloudSyncEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd;   // "07:00"
  final List<TrustedContact> trustedContacts;
  final bool consentGiven;
  final String selectedLanguage; // 'en' or 'hi'
  final bool biometricLockEnabled;
  final String? pairedBleDeviceId;
  final String? pairedBleDeviceName;

  const UserSettings({
    this.sensitivity = SensitivityLevel.medium,
    this.mockDataMode = true, // Default to true so app is immediately testable!
    this.cloudSyncEnabled = false, // Privacy-first default: no cloud upload unless opted in
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.trustedContacts = const [],
    this.consentGiven = true,
    this.selectedLanguage = 'en',
    this.biometricLockEnabled = false,
    this.pairedBleDeviceId,
    this.pairedBleDeviceName,
  });

  UserSettings copyWith({
    SensitivityLevel? sensitivity,
    bool? mockDataMode,
    bool? cloudSyncEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    List<TrustedContact>? trustedContacts,
    bool? consentGiven,
    String? selectedLanguage,
    bool? biometricLockEnabled,
    String? pairedBleDeviceId,
    String? pairedBleDeviceName,
  }) {
    return UserSettings(
      sensitivity: sensitivity ?? this.sensitivity,
      mockDataMode: mockDataMode ?? this.mockDataMode,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      trustedContacts: trustedContacts ?? this.trustedContacts,
      consentGiven: consentGiven ?? this.consentGiven,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      pairedBleDeviceId: pairedBleDeviceId ?? this.pairedBleDeviceId,
      pairedBleDeviceName: pairedBleDeviceName ?? this.pairedBleDeviceName,
    );
  }

  Map<String, dynamic> toJson() => {
        'sensitivity': sensitivity.name,
        'mockDataMode': mockDataMode,
        'cloudSyncEnabled': cloudSyncEnabled,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'trustedContacts': trustedContacts.map((c) => c.toJson()).toList(),
        'consentGiven': consentGiven,
        'selectedLanguage': selectedLanguage,
        'biometricLockEnabled': biometricLockEnabled,
        'pairedBleDeviceId': pairedBleDeviceId,
        'pairedBleDeviceName': pairedBleDeviceName,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      sensitivity: SensitivityLevel.values.firstWhere(
        (e) => e.name == json['sensitivity'],
        orElse: () => SensitivityLevel.medium,
      ),
      mockDataMode: json['mockDataMode'] as bool? ?? true,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? false,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
      trustedContacts: (json['trustedContacts'] as List<dynamic>?)
              ?.map((c) => TrustedContact.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      consentGiven: json['consentGiven'] as bool? ?? true,
      selectedLanguage: json['selectedLanguage'] as String? ?? 'en',
      biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? false,
      pairedBleDeviceId: json['pairedBleDeviceId'] as String?,
      pairedBleDeviceName: json['pairedBleDeviceName'] as String?,
    );
  }
}
