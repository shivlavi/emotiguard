import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'EmotiGuard',
      'dashboardTitle': 'Biometric Monitor',
      'distressScore': 'Distress Score',
      'calmAndCentered': 'Calm & Centered',
      'gentleTension': 'Gentle Tension',
      'elevatedArousal': 'Elevated Arousal',
      'highDistress': 'High Distress',
      'heartRate': 'Heart Rate',
      'hrv': 'HRV (RMSSD)',
      'skinConductance': 'Skin Conductance',
      'movement': 'Movement Accel',
      'mockSimulator': 'Mock Data Simulator',
      'breathe': '4-7-8 Breathe',
      'reflect': 'Reflect',
      'checkIn': 'Check-in',
      'support': 'Support',
      'deleteData': 'Delete All My Data',
      'exportCsv': 'Export Biometrics as CSV',
    },
    'hi': {
      'appTitle': 'इमोटीगार्ड',
      'dashboardTitle': 'बायोमेट्रिक मॉनिटर',
      'distressScore': 'तनाव स्कोर',
      'calmAndCentered': 'शांत और संतुलित',
      'gentleTension': 'हल्का तनाव',
      'elevatedArousal': 'बढ़ा हुआ तनाव',
      'highDistress': 'गंभीर तनाव',
      'heartRate': 'हृदय गति (HR)',
      'hrv': 'हृदय गति परिवर्तनशीलता (HRV)',
      'skinConductance': 'त्वचा चालकता (EDA)',
      'movement': 'गतिविधि / चाल',
      'mockSimulator': 'सिमुलेटर मोड',
      'breathe': '4-7-8 श्वास अभ्यास',
      'reflect': 'विचार डायरी',
      'checkIn': 'मूड जांचें',
      'support': 'मदद लें',
      'deleteData': 'मेरा सारा डेटा हटाएं',
      'exportCsv': 'डेटा CSV में डाउनलोड करें',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
