import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../services/services.dart';
import '../../ui/button.dart';
import '../../ui/page.dart';

/// Figma 01.04 Enter code: six digit boxes and a real resend countdown.
class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key, required this.contact, required this.onVerified, required this.onChangeContact});
  final String contact;
  final VoidCallback onVerified;
  final VoidCallback onChangeContact;

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 30;
  bool _busy = false;
  String? _error;

  bool get _isEmail => widget.contact.contains('@');

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (--_seconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    await Services.auth.sendOtp(widget.contact);
    if (mounted) setState(_startTimer);
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await Services.auth.verifyOtp(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) widget.onVerified();
  }

  /// The real input sits under the boxes and owns focus, paste and
  /// one-time-code autofill; the boxes just draw what it holds.
  Widget _digits() {
    final text = _code.text;
    return Stack(children: [
      Positioned.fill(
        child: Opacity(
          opacity: 0,
          child: TextField(
            key: const Key('auth-code'),
            controller: _code,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            showCursor: false,
          ),
        ),
      ),
      GestureDetector(
        onTap: _focus.requestFocus,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 6; i++)
            Container(
              width: 52,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CarinoColors.soft,
                borderRadius: BorderRadius.circular(CarinoRadius.digit),
                border: _focus.hasFocus && i == text.length ? Border.all(color: CarinoColors.primary) : null,
              ),
              child: Text(i < text.length ? text[i] : '', style: CarinoText.digit),
            ),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => CarinoPage(
        title: _isEmail ? 'Check your email' : 'Check your texts',
        step: '2 / 5',
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: CarinoColors.blush, shape: BoxShape.circle),
              child: const CarinoIcon(CarinoIcons.shieldPrimary),
            ),
          ),
          const Text('A little security.\nA lot of care.', style: CarinoText.display),
          Text('Enter the 6-digit code sent to\n${widget.contact}.', style: CarinoText.lead),
          _digits(),
          if (_error != null) Text(_error!, style: CarinoText.small.copyWith(color: CarinoColors.danger)),
          CarinoButton(_busy ? 'Checking…' : 'Verify and continue',
              onPressed: _code.text.length == 6 && !_busy ? _verify : null),
          if (_seconds > 0)
            Text('Send a new code in 00:${_seconds.toString().padLeft(2, '0')}', style: CarinoText.status)
          else
            GestureDetector(onTap: _resend, child: const Text('Send a new code', style: CarinoText.link)),
          CarinoButton(_isEmail ? 'Use a different email' : 'Use a different number',
              secondary: true, onPressed: widget.onChangeContact),
        ],
      );
}
