import 'package:flutter/painting.dart';
import 'tokens.dart';

/// Figma text styles. Manrope for everyday UI, DM Serif Display "a little
/// romance, used sparingly" (hero lines and names on photos).
abstract final class CarinoText {
  static const _ui = 'Manrope';
  static const _serif = 'DM Serif Display';

  static const hero = TextStyle(fontFamily: _serif, fontSize: 38, height: 1.16, color: CarinoColors.ink);
  static const display = TextStyle(fontFamily: _serif, fontSize: 36, height: 1.16, color: CarinoColors.ink);
  static const name = TextStyle(fontFamily: _serif, fontSize: 32, height: 1.16, color: CarinoColors.white);
  static const screenTitle = TextStyle(fontFamily: _ui, fontSize: 28, fontWeight: FontWeight.w700, height: 1.16, color: CarinoColors.ink);
  static const topBar = TextStyle(fontFamily: _ui, fontSize: 24, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const button = TextStyle(fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2);
  static const barTitle = TextStyle(fontFamily: _ui, fontSize: 17, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const cardTitle = TextStyle(fontFamily: _ui, fontSize: 16, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const lead = TextStyle(fontFamily: _ui, fontSize: 15, height: 1.45, color: CarinoColors.secondary);
  static const input = TextStyle(fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.ink);
  static const link = TextStyle(fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.primary);
  static const digit = TextStyle(fontFamily: _ui, fontSize: 24, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const body = TextStyle(fontFamily: _ui, fontSize: 14, height: 1.45, color: CarinoColors.secondary);
  static const bodyStrong = TextStyle(fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w500, height: 1.45);
  static const small = TextStyle(fontFamily: _ui, fontSize: 13, height: 1.45, color: CarinoColors.secondary);
  static const label = TextStyle(fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w600, height: 1.45, color: CarinoColors.secondary);
  static const status = TextStyle(fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const helper = TextStyle(fontFamily: _ui, fontSize: 12, height: 1.45, color: CarinoColors.secondary);
  static const step = TextStyle(fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const chip = TextStyle(fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w600, height: 1.45);
  static const badge = TextStyle(fontFamily: _ui, fontSize: 11, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const caption = TextStyle(fontFamily: _ui, fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const fine = TextStyle(fontFamily: _ui, fontSize: 11, height: 1.45, color: CarinoColors.secondary);
  static const tab = TextStyle(fontFamily: _ui, fontSize: 10, fontWeight: FontWeight.w700, height: 1.45);
  static const legal = TextStyle(fontFamily: _ui, fontSize: 10, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
}
