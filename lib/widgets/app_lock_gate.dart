import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/services.dart';
import '../theme/app_colors.dart';
import 'spark_button.dart';

/// App lock, installed in MaterialApp.builder so it sits ABOVE the
/// Navigator and covers every route, sheet and dialog.
///
/// - Locks on open and as soon as the app stops being active (inactive /
///   hidden / paused), so the OS app-switcher snapshot shows the lock, not
///   a chat.
/// - While locked, content behind is neither tappable nor read by screen
///   readers.
/// - Unlock = Face / fingerprint / device PIN. If the phone no longer has
///   any screen lock, the member can sign out (removing the lock) instead of
///   being stuck forever.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = Services.prefs.appLock;
  bool _busy = false;
  bool _deviceHasNoLock = false;

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
    if (!Services.prefs.appLock) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (!_locked) setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    var ok = false;
    try {
      ok = await Services.biometric.unlock('Unlock ${AppConfig.appName}');
    } finally {
      // Always re-enable the button — never leave a member on "Waiting…".
      if (mounted) {
        setState(() {
          _busy = false;
          if (ok) _locked = false;
        });
      }
    }
    if (ok || !mounted) return;
    // Failed: is it because the phone has no screen lock at all?
    final available = await Services.biometric.available();
    if (mounted) setState(() => _deviceHasNoLock = !available);
  }

  Future<void> _signOutToRemoveLock() async {
    Services.prefs.appLock = false;
    await Services.auth.signOut();
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        ExcludeSemantics(
          excluding: _locked,
          child: AbsorbPointer(absorbing: _locked, child: widget.child),
        ),
        if (_locked)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: ColoredBox(
                color: AppColors.midnight.withValues(alpha: 0.82),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 48, color: AppColors.sparkCoral),
                        const SizedBox(height: 16),
                        Text('${AppConfig.appName} is locked',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppColors.warmIvory)),
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
                        if (_deviceHasNoLock) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'This phone has no screen lock any more, so it can\'t '
                            'unlock the app. Sign out to remove app lock, then '
                            'sign back in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.softRose),
                          ),
                          const SizedBox(height: 8),
                          SparkButton(
                            label: 'Sign out',
                            icon: Icons.logout,
                            secondary: true,
                            onPressed: _signOutToRemoveLock,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
