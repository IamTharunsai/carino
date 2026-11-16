import 'package:flutter/material.dart';

/// Cariño palette — clean white, near-black ink, romantic plum (not red),
/// a soft mauve for small highlights and gold for the verified tick.
/// Token NAMES are kept from the first palette so every screen updates.
class AppColors {
  static const Color surfaceLight = Colors.white;
  static const Color porcelainDeep = Color(0xFFF7F3F5);
  AppColors._();

  /// Plum — primary buttons, selected states. 9:1 on white.
  static const Color emberCrimson = Color(0xFF6B2D5C);

  /// Mauve — small highlights, icons, celebrations. 5:1 on white.
  static const Color sparkCoral = Color(0xFFB0507A);

  /// Ink — text on light, and the dark-mode / reel background.
  static const Color midnight = Color(0xFF1C1A1F);

  /// Elevated surfaces on dark: cards, sheets, navigation.
  static const Color plumCharcoal = Color(0xFF2A2730);

  /// Primary text on dark.
  static const Color warmIvory = Color(0xFFFFFFFF);

  /// Secondary text / quiet labels on dark.
  static const Color softRose = Color(0xFF9A919B);

  /// Light theme background — clean white (the default theme).
  static const Color porcelain = Color(0xFFFFFFFF);

  /// Soft plum tint for selected chips and quiet fills.
  static const Color blush = Color(0xFFF5EAF0);

  /// Hairlines and card borders on white.
  static const Color line = Color(0xFFECE6EA);

  /// The verified tick.
  static const Color verifiedGold = Color(0xFFC9A13B);

  // --- Glass tints (DESIGN SYSTEM: cards 55–65% tint, sheets 80%) ---
  static Color glassFillDark(double opacity) =>
      plumCharcoal.withValues(alpha: opacity.clamp(0.0, 1.0));
  static Color glassFillLight(double opacity) =>
      Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

  /// Hairline borders: Warm Ivory 28% on dark, Midnight 10% on light.
  static Color glassBorder(Brightness brightness) => brightness == Brightness.dark
      ? warmIvory.withValues(alpha: 0.28)
      : line;

  /// Card tint opacity per blueprint (55–65%).
  static const double glassCardOpacity = 0.60;

  /// Sheet tint opacity per blueprint (80% — readability first).
  static const double glassSheetOpacity = 0.80;

  /// Visual blur approximating the system ultra-thin material (20–30pt).
  static const double glassBlurSigma = 24.0;

  /// Shadow under glass cards: Midnight 25%, y=8, blur 24.
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0F1C1A1F),
      offset: Offset(0, 4),
      blurRadius: 16,
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
