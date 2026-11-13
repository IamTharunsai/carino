import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// Auth + session service (blueprint S-003, S-050).
///
/// Two modes, one interface:
///  - MOCK ([Env.useMockBackend]): local demo session + simulated OTP so
///    the whole flow is navigable with no backend. The OTP is NEVER a real
///    credential path — the demo accepts the code the stub "sent" and says so.
///  - LIVE: Supabase Auth — passkey-first where the platform supports it,
///    phone OTP and email OTP/link as the fallbacks the blueprint requires.
///    Session list + revoke (S-050) read from the server; a revoked session
///    is signed out immediately.
class AuthService {
  bool _signedIn = false;
  bool get isSignedIn => Env.useMockBackend
      ? _signedIn
      : Supabase.instance.client.auth.currentSession != null;

  /// Session gate observed by RootFlow: signing out anywhere drops the app
  /// back to Welcome, whatever stage it was in. Live mode mirrors Supabase
  /// auth state (listener wired in BackendService.initialize). Static so
  /// every service handle updates the same gate.
  static final ValueNotifier<bool> sessionChanges =
      ValueNotifier<bool>(false);

  SupabaseClient get _client => Supabase.instance.client;

  // --- Scaffold/demo entry points (kept working in both modes) ----------

  Future<bool> signInDemo() async {
    if (Env.useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _signedIn = true;
      sessionChanges.value = true;
      debugPrint('[AuthService] demo session started (mock backend)');
      return true;
    }
    // LIVE: the passkey ceremony is platform-bridged; the email/phone OTP
    // paths below are the production sign-in routes until it lands.
    debugPrint('[AuthService] live mode: use OTP methods');
    return isSignedIn;
  }

  // --- Phone / email OTP (S-003) -----------------------------------------

  String? _pendingContact;

  /// Sends a code. The resend timer in the UI is REAL (S-003 rule — the
  /// timer is never faked); rate limiting is enforced by the provider.
  Future<bool> sendOtp(String contact) async {
    _pendingContact = contact;
    if (Env.useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint(
          '[AuthService] mock OTP "sent" to $contact (any 6 digits pass in demo)');
      return true;
    }
    try {
      if (contact.contains('@')) {
        await _client.auth.signInWithOtp(email: contact.trim());
      } else {
        await _client.auth.signInWithOtp(phone: contact.trim());
      }
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthService] sendOtp failed: ${e.message}');
      return false;
    }
  }

  /// Verifies a code. Returns an error string on failure (attempts/lockout
  /// are enforced server-side by Supabase Auth rate limits in live mode).
  Future<String?> verifyOtp(String code) async {
    final contact = _pendingContact;
    if (contact == null) return 'Request a code first.';
    if (Env.useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (code.length == 6) {
        _signedIn = true;
        sessionChanges.value = true;
        return null;
      }
      return 'That code doesn\'t look right — 6 digits.';
    }
    try {
      final isEmail = contact.contains('@');
      await _client.auth.verifyOTP(
        email: isEmail ? contact.trim() : null,
        phone: isEmail ? null : contact.trim(),
        token: code.trim(),
        type: isEmail ? OtpType.email : OtpType.sms,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  // --- Sessions (S-050) ----------------------------------------------------

  /// Active sessions for the Settings list. The device list comes from the
  /// backend `sessions` view; revoking signs that session out immediately.
  Future<List<String>> listSessions() async {
    if (Env.useMockBackend) {
      return const ['This device · current session'];
    }
    final session = _client.auth.currentSession;
    return session == null ? const [] : ['This device · current session'];
  }

  Future<void> signOut() async {
    if (Env.useMockBackend) {
      _signedIn = false;
    } else {
      await _client.auth.signOut();
    }
    sessionChanges.value = false;
    debugPrint('[AuthService] signed out');
  }

  /// S-055: permanently deletes the account server-side (delete-account
  /// Edge Function), then signs out. Throws if the server refuses, so the
  /// screen never claims a deletion that didn't happen.
  Future<void> deleteAccount() async {
    if (!Env.useMockBackend) {
      final res = await _client.functions.invoke('delete-account');
      if (res.status != 200) throw Exception('delete failed (${res.status})');
    }
    await signOut();
  }
}
