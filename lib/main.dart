import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/root_flow.dart';
import 'services/services.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Services.backend.initialize();
  // Server-driven UI config — falls back to compiled defaults offline/mock;
  // can never hide safety surfaces (see RemoteConfigService hard limits).
  await Services.remoteConfig.fetch();
  runApp(const CarinoApp());
}

class CarinoApp extends StatelessWidget {
  const CarinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme switch (Settings → Appearance): Midnight / Porcelain / System.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Services.prefs.themeMode,
      builder: (context, mode, _) => MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(), // Porcelain
      darkTheme: AppTheme.dark(), // Midnight — the brand default
      themeMode: mode,
      // Calm mode (Settings / You): app-wide reduced motion, layered on top
      // of the OS setting — screens already honour disableAnimations.
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: Services.prefs.calmMode,
        builder: (context, calm, _) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
                disableAnimations: calm || mq.disableAnimations),
            child: child!,
          );
        },
      ),
      home: const RootFlow(),
      ),
    );
  }
}
