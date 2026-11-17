import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// LEGACY names mapped onto lib/design/tokens.dart (Figma "Rose Studio").
/// Screens switch to CarinoColors as they are rebuilt from Figma; this file
/// is deleted when the last one is done. Do not add anything here.
class AppColors {
  AppColors._();

  static const Color emberCrimson = CarinoColors.primary;
  static const Color sparkCoral = CarinoColors.primary;
  static const Color midnight = CarinoColors.ink;
  static const Color softRose = CarinoColors.secondary;
  static const Color porcelain = CarinoColors.canvas;
  static const Color porcelainDeep = CarinoColors.soft;
  static const Color surfaceLight = CarinoColors.surface;
  static const Color blush = CarinoColors.blush;
  static const Color line = CarinoColors.line;
  static const Color verifiedGold = CarinoColors.gold;
  static const Color warmIvory = CarinoColors.white;

  /// Dark-mode surface (Figma has no dark mode yet).
  static const Color plumCharcoal = Color(0xFF2B2429);

  /// Solid primary — Figma uses no gradients.
  static const LinearGradient loveGradient =
      LinearGradient(colors: [CarinoColors.primary, CarinoColors.primary]);
  static const LinearGradient sparkGlowGradient = loveGradient;

  static Color glassFillDark(double opacity) => plumCharcoal.withValues(alpha: opacity.clamp(0.0, 1.0));
  static Color glassFillLight(double opacity) => CarinoColors.surface.withValues(alpha: opacity.clamp(0.0, 1.0));
  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? CarinoColors.white.withValues(alpha: 0.28) : CarinoColors.line;
  static const double glassCardOpacity = 1.0;
  static const double glassSheetOpacity = 1.0;
  static const double glassBlurSigma = 0;
  static const List<BoxShadow> glassShadow = [];
}
