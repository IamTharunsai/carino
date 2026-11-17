import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../design/type.dart';

/// Figma "Input": 13pt label above a soft, radius-14 box (44 tall,
/// 16pt padding) with 15pt medium ink text and an optional trailing icon.
class CarinoField extends StatelessWidget {
  const CarinoField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.trailing,
    this.fieldKey,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final Widget? trailing;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: CarinoText.label),
        const SizedBox(height: CarinoSpace.sm),
        Container(
          constraints: const BoxConstraints(minHeight: CarinoSpace.minTarget),
          padding: EdgeInsets.only(left: CarinoSpace.lg, right: trailing == null ? CarinoSpace.lg : 5),
          decoration: BoxDecoration(color: CarinoColors.soft, borderRadius: BorderRadius.circular(CarinoRadius.input)),
          child: Row(children: [
            Expanded(
              child: Semantics(
                label: label,
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  autofillHints: autofillHints,
                  style: CarinoText.input,
                  cursorColor: CarinoColors.primary,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: CarinoText.input.copyWith(color: CarinoColors.secondary),
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ]);
}
