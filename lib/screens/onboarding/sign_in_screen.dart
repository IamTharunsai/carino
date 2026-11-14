import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Returning-member sign in: username + password, both required.
/// - Required fields carry a visible * and the button stays disabled until
///   both are filled (prevents a pointless failed attempt).
/// - Password is masked with an eye toggle on the right.
/// - "Forgot password?" sits right under the password and offers a
///   one-time code instead, so nobody is stuck.
/// - Errors never reveal whether a username exists.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onUseCode,
  });

  final VoidCallback onSignedIn;

  /// Sign in with a one-time code instead (forgot password / no password).
  final VoidCallback onUseCode;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _userTouched = false;
  bool _passTouched = false;
  String? _error;

  bool get _ready =>
      _username.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _username.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _userTouched = _passTouched = true;
    });
    if (!_ready || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await Services.auth.signInWithPassword(_username.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) widget.onSignedIn();
  }

  Future<void> _provider(OAuthProvider p) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await Services.auth.signInWithProvider(p);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err != null) return;
    if (Services.auth.isSignedIn) {
      widget.onSignedIn();
    } else {
      // LIVE: the browser is open; RootFlow routes when the session lands.
      setState(() => _error = 'Finish signing in in your browser, then come back.');
    }
  }

  Future<void> _passkey() async {
    // Passkeys are unlocked by the phone's biometrics; the OS handles it.
    final ok = await Services.biometric.unlock('Sign in to Cariño with your passkey');
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = "Passkey sign-in was cancelled or isn't set up on this phone.");
      return;
    }
    final signedIn = await Services.auth.signInDemo();
    if (!mounted) return;
    if (!signedIn || !Services.auth.isSignedIn) {
      // A local fingerprint is NOT a credential. Until platform passkeys are
      // wired to the server, live mode refuses rather than faking a session.
      setState(() => _error = "Passkeys aren't available yet. Use your password or a one-time code.");
      return;
    }
    widget.onSignedIn();
  }

  Widget _requiredLabel(String text) => Text.rich(
        TextSpan(
          text: text,
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.sparkCoral, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final userMissing = _userTouched && _username.text.trim().isEmpty;
    final passMissing = _passTouched && _password.text.isEmpty;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Welcome back', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text('Sign in to pick up where you left off.', style: text.bodyLarge),
          const SizedBox(height: 24),
          TextField(
            key: const Key('signin-username'),
            controller: _username,
            autofillHints: const [AutofillHints.username],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _userTouched = true,
            decoration: InputDecoration(
              label: _requiredLabel('Username'),
              hintText: 'Email or phone number',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: userMissing ? 'Username is required' : null,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('signin-password'),
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onChanged: (_) => _passTouched = true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              label: _requiredLabel('Password'),
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: passMissing ? 'Password is required' : null,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onUseCode,
              child: const Text('Forgot password?'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.sparkCoral)),
            ),
          const SizedBox(height: 8),
          SparkButton(
            label: _busy ? 'Signing in…' : 'Sign in',
            icon: Icons.arrow_forward,
            iconAtEnd: true,
            onPressed: _ready && !_busy ? _submit : null,
          ),
          const SizedBox(height: 6),
          Text('* Required', style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          // Faster sign-in = less drop-off. Each provider is a real OAuth
          // route in live mode; Apple is required on iOS when Google is offered.
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
          const SizedBox(height: 8),
          SparkButton(
            label: 'Use a passkey (Face / fingerprint)',
            icon: Icons.fingerprint,
            secondary: true,
            onPressed: _busy ? null : _passkey,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onUseCode,
            icon: const Icon(Icons.sms_outlined, size: 18),
            label: const Text('Sign in with a one-time code instead'),
          ),
        ],
      ),
    );
  }
}
