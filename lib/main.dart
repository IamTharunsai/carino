import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'config/app_config.dart';
import 'config/env.dart';
import 'screens/root_flow.dart';
import 'services/links.dart';
import 'services/services.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/motion.dart' show stillBackgrounds;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.releaseMisconfigured(
    isRelease: kReleaseMode,
    configured: Env.isConfigured,
    demoOverride: Env.isDemoOverride,
  )) {
    runApp(const _MisconfiguredApp());
    return;
  }
  try {
    await Services.backend.initialize().timeout(const Duration(seconds: 15));
    // Server-driven UI config — falls back to compiled defaults offline/mock;
    // can never hide safety surfaces (see RemoteConfigService hard limits).
    await Services.remoteConfig.fetch().timeout(const Duration(seconds: 10));
    // Persisted gates (app lock, hidden chats, under-21 block) before UI.
    await Services.prefs.load();
    // Web: still backgrounds (continuous full-screen animation hurts taps/INP).
    if (kIsWeb) stillBackgrounds = true;
    // A shared profile link that opened the app (web URL or app link).
    pendingProfile.value = profileIdFromLink(Uri.base);
    if (!kIsWeb) {
      final links = AppLinks();
      final first = await links.getInitialLink().timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (first != null) pendingProfile.value = profileIdFromLink(first) ?? pendingProfile.value;
      links.uriLinkStream.listen((u) => pendingProfile.value = profileIdFromLink(u) ?? pendingProfile.value);
    }
  } catch (e) {
    debugPrint('[startup] failed: $e');
    runApp(const _StartupFailedApp());
    return;
  }
  runApp(const CarinoApp());
}

/// Start-up couldn't finish (offline, server down). Never shows the home
/// screen or sample people to hide it — just a calm retry.
class _StartupFailedApp extends StatelessWidget {
  const _StartupFailedApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 40),
                  const SizedBox(height: 12),
                  const Text("Cariño couldn't start", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Check your connection and try again. Nothing was lost.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: main, child: const Text('Try again')),
                ],
              ),
            ),
          ),
        ),
      );
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
            // App lock sits above the Navigator: it covers every route.
            child: AppLockGate(child: child!),
          );
        },
      ),
      home: const RootFlow(),
      ),
    );
  }
}

/// Shown instead of the app when a release build was made without the
/// backend settings (see DEPLOYMENT.md -> Release builds).
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                "This build is missing its server settings and can't start. "
                'Rebuild with SUPABASE_URL and SUPABASE_ANON_KEY '
                '(or USE_MOCK_BACKEND=true for a demo build).',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
