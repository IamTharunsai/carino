import 'package:flutter/material.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../services/services.dart';
import '../../ui/button.dart';
import '../../ui/chip.dart';
import '../../ui/field.dart';
import '../../ui/page.dart';

/// Figma 01.03 Phone or email: contact + password, then a code is sent.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.onCodeSent, required this.onSignIn});
  final ValueChanged<String> onCodeSent;
  final VoidCallback onSignIn;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _email = true;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_contact, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid {
    final v = _contact.text.trim();
    final contactOk = _email
        ? RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
        : v.replaceAll(RegExp(r'\D'), '').length >= 7;
    return contactOk && _password.text.length >= 8;
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await Services.auth.signUp(_contact.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) widget.onCodeSent(_contact.text.trim());
  }

  @override
  Widget build(BuildContext context) => CarinoPage(
        title: 'Your account',
        step: '1 / 5',
        children: [
          const Text('Let’s keep\nin touch.', style: CarinoText.display),
          Text(
            _email
                ? 'Use an email you can access. It won’t appear on your profile.'
                : 'Use a number that gets texts. It won’t appear on your profile.',
            style: CarinoText.lead,
          ),
          Row(children: [
            CarinoChip('Email', selected: _email, onTap: () => setState(() => _email = true)),
            const SizedBox(width: 10),
            CarinoChip('Phone', selected: !_email, onTap: () => setState(() => _email = false)),
          ]),
          CarinoField(
            fieldKey: const Key('auth-contact'),
            label: _email ? 'Email address' : 'Phone number',
            hint: _email ? 'alex@example.com' : '+1 555 010 0199',
            controller: _contact,
            keyboardType: _email ? TextInputType.emailAddress : TextInputType.phone,
            autofillHints: [_email ? AutofillHints.email : AutofillHints.telephoneNumber],
          ),
          CarinoField(
            fieldKey: const Key('auth-password'),
            label: 'Password',
            hint: '••••••••••••',
            controller: _password,
            obscure: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            trailing: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: CarinoIcon(CarinoIcons.eye, color: _obscure ? null : CarinoColors.primary),
            ),
          ),
          Text(_error ?? 'At least 8 characters. Make it something unique.',
              style: CarinoText.helper.copyWith(color: _error == null ? null : CarinoColors.danger)),
          CarinoButton(_busy ? 'Sending…' : 'Send me a code', onPressed: _valid && !_busy ? _send : null),
          Material(
            color: CarinoColors.soft,
            borderRadius: BorderRadius.circular(CarinoRadius.photo),
            child: InkWell(
              onTap: widget.onSignIn,
              borderRadius: BorderRadius.circular(CarinoRadius.photo),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text('Already here? Sign in instead.', style: CarinoText.link),
              ),
            ),
          ),
        ],
      );
}
