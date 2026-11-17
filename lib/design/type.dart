import 'package:flutter/painting.dart';
import 'tokens.dart';

/// Figma text styles. Manrope for everyday UI, DM Serif Display "a little
/// romance, used sparingly" (hero lines and names on photos).
abstract final class CarinoText {
  static const _ui = 'Manrope';
  static const _serif = 'DM Serif Display';
  // Figma/CSS split line-height leading evenly above and below the glyphs.
  static const _even = TextLeadingDistribution.even;

  static const hero = TextStyle(leadingDistribution: _even, fontFamily: _serif, fontSize: 38, height: 1.16, color: CarinoColors.ink);
  static const display = TextStyle(leadingDistribution: _even, fontFamily: _serif, fontSize: 36, height: 1.16, color: CarinoColors.ink);
  static const name = TextStyle(leadingDistribution: _even, fontFamily: _serif, fontSize: 32, height: 1.16, color: CarinoColors.white);
  static const screenTitle = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 28, fontWeight: FontWeight.w700, height: 1.16, color: CarinoColors.ink);
  static const topBar = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 24, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const button = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2);
  static const barTitle = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 17, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const cardTitle = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 16, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const lead = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 15, height: 1.45, color: CarinoColors.secondary);
  static const input = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.ink);
  static const link = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.primary);
  static const digit = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 24, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const wheel = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 20, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const wheelSelected = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 20, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.primary);
  static const body = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 14, height: 1.45, color: CarinoColors.secondary);
  static const bodyStrong = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w500, height: 1.45);
  static const small = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 13, height: 1.45, color: CarinoColors.secondary);
  static const label = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w600, height: 1.45, color: CarinoColors.secondary);
  static const status = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const helper = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 12, height: 1.45, color: CarinoColors.secondary);
  static const step = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const pickerHead = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.secondary);
  static const pill = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const chip = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w600, height: 1.45);
  static const badge = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 11, fontWeight: FontWeight.w700, height: 1.45, color: CarinoColors.ink);
  static const caption = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
  static const fine = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 11, height: 1.45, color: CarinoColors.secondary);
  static const tab = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 10, fontWeight: FontWeight.w700, height: 1.45);
  static const legal = TextStyle(leadingDistribution: _even, fontFamily: _ui, fontSize: 10, fontWeight: FontWeight.w500, height: 1.45, color: CarinoColors.secondary);
}
