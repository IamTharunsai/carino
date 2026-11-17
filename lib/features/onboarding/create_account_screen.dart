import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../services/services.dart';
import '../../ui/button.dart';
import '../../ui/page.dart';

/// Figma 01.02 Create account: Apple, Google, or phone/email.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.onAuthenticated, required this.onUseContact});
  final VoidCallback onAuthenticated;
  final VoidCallback onUseContact;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _provider(OAuthProvider p) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await Services.auth.signInWithProvider(p);
    if (!mounted) return;
    final signedIn = err == null && Services.auth.isSignedIn;
    setState(() {
      _busy = false;
      _error = err ?? (signedIn ? null : 'Finish signing in in your browser, then come back.');
    });
    if (signedIn) widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) => CarinoPage(
        title: 'Create an account',
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: CarinoSpace.minTarget,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: CarinoColors.soft, borderRadius: BorderRadius.circular(CarinoRadius.chip)),
              child: Center(
                widthFactor: 1,
                child: Text('YOUR NEXT CHAPTER', style: CarinoText.chip.copyWith(color: CarinoColors.secondary)),
              ),
            ),
          ),
          const Text('Good things start\nwith hello.', style: CarinoText.display),
          const Text('Join a kinder way to meet. Your private details stay private.', style: CarinoText.lead),
          ClipRRect(
            borderRadius: BorderRadius.circular(CarinoRadius.photo),
            child: Image.asset('assets/images/people/friends.png',
                height: 210, width: double.infinity, fit: BoxFit.cover, semanticLabel: 'Friends laughing together'),
          ),
          CarinoButton('Continue with Apple', onPressed: _busy ? null : () => _provider(OAuthProvider.apple)),
          CarinoButton('Continue with Google',
              secondary: true, onPressed: _busy ? null : () => _provider(OAuthProvider.google)),
          CarinoButton('Use phone or email', secondary: true, onPressed: _busy ? null : widget.onUseContact),
          if (_error != null) Text(_error!, style: CarinoText.small.copyWith(color: CarinoColors.danger)),
          Container(
            padding: const EdgeInsets.all(CarinoSpace.lg),
            decoration: BoxDecoration(color: CarinoColors.soft, borderRadius: BorderRadius.circular(CarinoRadius.photo)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CarinoIcon(CarinoIcons.shieldPrimary),
              SizedBox(height: CarinoSpace.md),
              Text('You’re in control', style: CarinoText.cardTitle),
              SizedBox(height: CarinoSpace.md),
              Text('We never post to your accounts or share your contact details with other members.',
                  style: CarinoText.small),
            ]),
          ),
          const Text('By continuing, you agree to our Terms and Privacy Policy.', style: CarinoText.fine),
        ],
      );
}
