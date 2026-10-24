import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'presentation/providers/sensor_providers.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge to edge calm status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: EmotiGuardApp(),
    ),
  );
}

class EmotiGuardApp extends ConsumerWidget {
  const EmotiGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userSession = ref.watch(currentUserSessionProvider);

    return MaterialApp(
      title: 'EmotiGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respects device dark/light setting
      locale: Locale(settings.selectedLanguage),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: userSession != null ? const DashboardScreen() : const AuthScreen(),
    );
  }
}
