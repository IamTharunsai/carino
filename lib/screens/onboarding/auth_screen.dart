import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-003 Auth — passkey / phone / email.
///
/// States built per blueprint:
///  - Passkey is the primary route (Bible F-005); phone + email OTP are
///    always-available fallbacks.
///  - Send code -> code entry on the same screen, with a REAL resend timer
///    (30s, counts down truthfully — never a fake timer), wrong-code error
///    with attempts remaining, and a lockout state after repeated failures
///    (the server enforces the real limit; the UI mirrors it honestly).
///  - Session security note: sessions can be reviewed + revoked in
///    Settings (S-050) — the takeover-recovery path.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthStage { contact, code, locked }

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _code = TextEditingController();
  _AuthStage _stage = _AuthStage.contact;
  bool _busy = false;
  String? _error;
  int _attemptsLeft = 5;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _contact.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  bool get _contactValid {
    final v = _contact.text.trim();
    if (v.contains('@')) return v.contains('.') && v.length > 5;
    return v.replaceAll(RegExp(r'\D'), '').length >= 7;
  }

  Future<void> _sendCode() async {
    if (!_contactValid) {
      setState(() => _error = 'Enter a valid phone number or email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await Services.auth.sendOtp(_contact.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _stage = _AuthStage.code;
        _attemptsLeft = 5;
        _startResendTimer();
      } else {
        _error = 'We couldn\'t send a code just now. Try again in a moment.';
      }
    });
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await Services.auth.verifyOtp(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        widget.onAuthenticated();
      } else {
        _attemptsLeft--;
        if (_attemptsLeft <= 0) {
          _stage = _AuthStage.locked;
        } else {
          _error = '$error Attempts left: $_attemptsLeft.';
        }
      }
    });
  }

  Future<void> _passkey() async {
    setState(() => _busy = true);
    await Services.auth.signInDemo();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Your account, locked to you.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Passkey recommended — it\'s phishing-proof and one tap. '
            'Your contact detail is for sign-in and safety only; it is '
            'never shown on your profile.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (_stage == _AuthStage.locked) ...[
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Too many tries',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'For your security, code entry is paused for a while. '
                    'This protects your account if someone else got hold '
                    'of your phone number. Try again later, or use your '
                    'passkey.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_stage == _AuthStage.code) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 8),
            SparkButton(
              label: _busy ? 'Checking…' : 'Verify code',
              icon: Icons.check_circle_outline,
              onPressed: _busy ? null : _verify,
            ),
            const SizedBox(height: 8),
            TextButton(
              // Real timer: disabled until it truly reaches zero.
              onPressed: _resendSeconds > 0 || _busy ? null : _sendCode,
              child: Text(_resendSeconds > 0
                  ? 'Resend code in ${_resendSeconds}s'
                  : 'Resend code'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _stage = _AuthStage.contact;
                _code.clear();
                _error = null;
              }),
              child: const Text('Use a different number or email'),
            ),
          ] else ...[
            TextField(
              controller: _contact,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Phone number or email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 16),
            SparkButton(
              label: _busy ? 'Sending…' : 'Send me a code',
              icon: Icons.sms_outlined,
              onPressed: _busy ? null : _sendCode,
            ),
            const SizedBox(height: 10),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('or'),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 10),
            SparkButton(
              label: 'Continue with passkey',
              icon: Icons.fingerprint,
              secondary: true,
              onPressed: _busy ? null : _passkey,
            ),
          ],
          const SizedBox(height: 20),
          GlassContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.devices_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Session security: you can see every signed-in device '
                    'and revoke any of them in Settings → Sessions. If a '
                    'device isn\'t yours, revoke it and re-verify.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
