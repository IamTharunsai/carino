import 'package:flutter/material.dart';

/// Locked brand palette (blueprint DESIGN SYSTEM sheet). Do not add new
/// brand colours without updating the blueprint — these six tokens are the
/// whole system.
class AppColors {
  static const Color surfaceLight = Colors.white;
  static const Color porcelainDeep = Color(0xFFF7F0EC);
  AppColors._();

  /// Signature red — primary buttons (SOLID, never glass), selected states.
  static const Color emberCrimson = Color(0xFFB81735);

  /// Celebrations, match glow, decorative highlights. Never body text on dark.
  static const Color sparkCoral = Color(0xFFFF6B6B);

  /// Dark theme background (brand default theme).
  static const Color midnight = Color(0xFF151014);

  /// Elevated surfaces on dark: cards, sheets, navigation.
  static const Color plumCharcoal = Color(0xFF261C24);

  /// Primary text on dark.
  static const Color warmIvory = Color(0xFFFFF8F3);

  /// Secondary text / quiet labels on dark.
  static const Color softRose = Color(0xFFD2BDC5);

  /// Light theme background (fully supported, never an inversion of dark).
  static const Color porcelain = Color(0xFFFFF8F5);

  // --- Glass tints (DESIGN SYSTEM: cards 55–65% tint, sheets 80%) ---
  static Color glassFillDark(double opacity) =>
      plumCharcoal.withValues(alpha: opacity.clamp(0.0, 1.0));
  static Color glassFillLight(double opacity) =>
      Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

  /// Hairline borders: Warm Ivory 28% on dark, Midnight 10% on light.
  static Color glassBorder(Brightness brightness) => brightness == Brightness.dark
      ? warmIvory.withValues(alpha: 0.28)
      : midnight.withValues(alpha: 0.10);

  /// Card tint opacity per blueprint (55–65%).
  static const double glassCardOpacity = 0.60;

  /// Sheet tint opacity per blueprint (80% — readability first).
  static const double glassSheetOpacity = 0.80;

  /// Visual blur approximating the system ultra-thin material (20–30pt).
  static const double glassBlurSigma = 24.0;

  /// Shadow under glass cards: Midnight 25%, y=8, blur 24.
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x40151014),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// Primary CTA gradient is NOT used — primary actions are solid crimson.
  /// This gradient is only for decorative glows (match celebration, sparks).
  static const LinearGradient sparkGlowGradient = LinearGradient(
    colors: [sparkCoral, emberCrimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
