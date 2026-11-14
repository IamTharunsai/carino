import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/services.dart';
import '../theme/app_colors.dart';
import 'spark_button.dart';

/// App lock: when enabled (Settings → Security), the app is covered by a
/// blurred lock on open and every time it returns from the background.
/// Unlock with Face / fingerprint, falling back to the device PIN.
/// The blur also hides chats from the OS app-switcher snapshot.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = Services.prefs.appLock;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && Services.prefs.appLock) {
      setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await Services.biometric.unlock('Unlock ${AppConfig.appName}');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: AppColors.midnight.withValues(alpha: 0.75),
                padding: const EdgeInsets.all(32),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 48, color: AppColors.sparkCoral),
                      const SizedBox(height: 16),
                      Text('${AppConfig.appName} is locked',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.warmIvory)),
                      const SizedBox(height: 8),
                      const Text('Your chats stay private until you unlock.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.softRose)),
                      const SizedBox(height: 24),
                      SparkButton(
                        label: _busy ? 'Waiting…' : 'Unlock',
                        icon: Icons.fingerprint,
                        onPressed: _busy ? null : _unlock,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
