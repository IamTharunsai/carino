import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// While [enabled], Android blocks screenshots and screen recording of the
/// app (FLAG_SECURE) — used for Vanish chats and view-once media.
/// iOS cannot block captures; there the app only DETECTS them and says so
/// (blueprint rule: never promise prevention). Nested screens are counted
/// so leaving one secure screen never unprotects another.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child, this.enabled = true, this.onScreenshot});

  final Widget child;
  final bool enabled;

  /// iOS reports screenshots (it can't block them); Android blocks instead.
  final VoidCallback? onScreenshot;

  static final List<VoidCallback> _listeners = [];
  static bool _listening = false;
  static void _listen() {
    if (_listening) return;
    _listening = true;
    const MethodChannel('carino/screenshots').setMethodCallHandler((call) async {
      if (call.method == 'taken') {
        for (final l in List.of(_listeners)) {
          l();
        }
      }
    });
  }

  /// Test seam: behave as if the OS reported a screenshot.
  @visibleForTesting
  static void debugScreenshot() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  static const MethodChannel _channel = MethodChannel('carino/secure');
  static int _depth = 0;

  @visibleForTesting
  static int get depth => _depth;

  static Future<void> _apply() async {
    try {
      await _channel.invokeMethod<void>('setSecure', _depth > 0);
    } catch (e) {
      // iOS / tests / web: no FLAG_SECURE — detection-only by design.
      debugPrint('[SecureScreen] not applied: $e');
    }
  }

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  bool _counted = false;

  void _sync() {
    if (widget.enabled && !_counted) {
      SecureScreen._depth++;
      _counted = true;
      SecureScreen._apply();
    } else if (!widget.enabled && _counted) {
      SecureScreen._depth--;
      _counted = false;
      SecureScreen._apply();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
    SecureScreen._listen();
    SecureScreen._listeners.add(_onShot);
  }

  void _onShot() {
    if (widget.enabled) widget.onScreenshot?.call();
  }

  @override
  void didUpdateWidget(SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    SecureScreen._listeners.remove(_onShot);
    if (_counted) {
      SecureScreen._depth--;
      SecureScreen._apply();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
