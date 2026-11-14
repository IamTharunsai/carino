import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / Android fingerprint + face unlock, with the device
/// PIN/pattern as fallback (biometricOnly: false) so nobody is locked out
/// of their own app. Nothing biometric ever leaves the device — the OS
/// returns only success/failure.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Test seam: replaces the OS prompt.
  @visibleForTesting
  Future<bool> Function(String reason)? authenticatorOverride;

  /// True if the device has biometrics or a screen lock to fall back on.
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[Biometric] support check failed: $e');
      return false; // tests / unsupported platforms / plugin errors
    }
  }

  /// Human label for Settings ("Face ID", "Fingerprint", "Screen lock").
  Future<String> label() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return 'Face unlock';
      if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
      if (types.isNotEmpty) return 'Biometrics';
    } catch (_) {}
    return 'Screen lock';
  }

  /// Prompts the OS sheet. Returns true only on a real success.
  Future<bool> unlock(String reason) async {
    // Catch EVERYTHING: local_auth 3.x throws LocalAuthException (not a
    // PlatformException) for lockout / no credentials. An escaped error
    // here once left the app stuck behind the lock screen.
    try {
      final override = authenticatorOverride;
      if (override != null) return await override(reason);
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('[Biometric] auth failed: $e');
      return false;
    }
  }
}
