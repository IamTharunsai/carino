import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Create account: phone or email + password, then a one-time code to
/// prove the number/email is yours. Or Google / Apple in one tap.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _contact = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    for (final c in [_contact, _password, _code]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _contact.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _contactValid {
    final v = _contact.text.trim();
    if (v.contains('@')) return v.contains('.') && v.length > 5;
    return v.replaceAll(RegExp(r'\D'), '').length >= 7;
  }

  bool get _passwordValid => _password.text.length >= 8;

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (--_resendSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _run(Future<String?> Function() action, void Function() onOk) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) onOk();
  }

  void _signUp() => _run(
        () => Services.auth.signUp(_contact.text, _password.text),
        () => setState(() {
          _codeSent = true;
          _startResendTimer();
        }),
      );

  void _verify() => _run(() => Services.auth.verifyOtp(_code.text), widget.onAuthenticated);

  void _provider(OAuthProvider p) => _run(() => Services.auth.signInWithProvider(p), () {
        if (Services.auth.isSignedIn) {
          widget.onAuthenticated();
        } else {
          setState(() => _error = 'Finish signing in in your browser, then come back.');
        }
      });

  InputDecoration _field(String label, IconData icon, {Widget? suffix, String? helper}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text(_codeSent ? 'Enter your code' : 'Create your account', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            _codeSent
                ? 'We sent a 6-digit code to ${_contact.text.trim()}.'
                : 'Only used to sign in — never shown on your profile.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (_codeSent) ...[
            TextField(
              key: const Key('auth-code'),
              controller: _code,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              decoration: _field('6-digit code', Icons.sms_outlined),
            ),
            SparkButton(
              label: _busy ? 'Checking…' : 'Verify',
              icon: Icons.check_circle_outline,
              onPressed: _code.text.length == 6 && !_busy ? _verify : null,
            ),
            TextButton(
              onPressed: _resendSeconds > 0 || _busy ? null : _signUp,
              child: Text(_resendSeconds > 0 ? 'Resend code in ${_resendSeconds}s' : 'Resend code'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _codeSent = false;
                _code.clear();
                _error = null;
              }),
              child: const Text('Change phone or email'),
            ),
          ] else ...[
            TextField(
              key: const Key('auth-contact'),
              controller: _contact,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              decoration: _field('Phone number or email', Icons.person_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('auth-password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _field(
                'Password',
                Icons.lock_outline,
                helper: 'At least 8 characters',
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SparkButton(
              label: _busy ? 'Sending…' : 'Send me a code',
              icon: Icons.arrow_forward,
              iconAtEnd: true,
              onPressed: _contactValid && _passwordValid && !_busy ? _signUp : null,
            ),
            const SizedBox(height: 16),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            SparkButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata,
              secondary: true,
              onPressed: _busy ? null : () => _provider(OAuthProvider.google),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Continue with Apple',
              icon: Icons.apple,
              secondary: true,
              onPressed: _busy ? null : () => _provider(OAuthProvider.apple),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.sparkCoral)),
            ),
        ],
      ),
    );
  }
}
