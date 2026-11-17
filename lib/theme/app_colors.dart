import 'package:flutter/material.dart';

/// Cariño palette — "Lavender Dream" (see DESIGN.md): lilac mist, violet,
/// heart pink, ink, and gold for the verified tick.
/// Token NAMES are kept from the first palette so every screen updates.
class AppColors {
  static const Color surfaceLight = Colors.white;
  static const Color porcelainDeep = Color(0xFFEFE8FA);
  AppColors._();

  /// Plum — primary buttons, selected states. 9:1 on white.
  static const Color emberCrimson = Color(0xFF6C3BD1); // violet

  /// Mauve — small highlights, icons, celebrations. 5:1 on white.
  static const Color sparkCoral = Color(0xFFD6266A); // heart (text-safe)

  /// Ink — text on light, and the dark-mode / reel background.
  static const Color midnight = Color(0xFF241B35); // ink

  /// Elevated surfaces on dark: cards, sheets, navigation.
  static const Color plumCharcoal = Color(0xFF211B30);

  /// Primary text on dark.
  static const Color warmIvory = Color(0xFFFFFFFF);

  /// Secondary text / quiet labels on dark.
  static const Color softRose = Color(0xFF8A7FA0);

  /// Light theme background — clean white (the default theme).
  static const Color porcelain = Color(0xFFF6F2FC); // lilac mist

  /// Soft plum tint for selected chips and quiet fills.
  static const Color blush = Color(0xFFEFE8FA);

  /// Hairlines and card borders on white.
  static const Color line = Color(0xFFE4DBF3);

  /// Signature "love" gradient: plum into mauve. Main buttons, the Feed tab, celebrations.
  static const LinearGradient loveGradient = LinearGradient(
    colors: [Color(0xFF6C3BD1), Color(0xFFFF4F8B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// The verified tick.
  static const Color verifiedGold = Color(0xFFB07F17);

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
