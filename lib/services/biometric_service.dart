import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / Android fingerprint + face unlock, with the device
/// PIN/pattern as fallback (biometricOnly: false) so nobody is locked out
/// of their own app. Nothing biometric ever leaves the device — the OS
/// returns only success/failure.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device has biometrics or a screen lock to fall back on.
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('[Biometric] support check failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false; // tests / unsupported platforms
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
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('[Biometric] auth error: ${e.code} ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
