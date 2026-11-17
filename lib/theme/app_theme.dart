import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme definitions for the Midnight (dark, default) and Porcelain (light)
/// themes. Type scale follows the blueprint: Display 28–34 / Title 22 /
/// Headline 17 semibold / Body 16 / Caption 12–13, on the platform font
/// (SF Pro on iOS, Roboto on Android) for a native feel.
class AppTheme {
  AppTheme._();

  static const double radiusCard = 20;
  static const double radiusButton = 16;
  static const double minTouchTarget = 44;
  static const double screenPadding = 16;

  /// Brand fonts (bundled, OFL). Body/UI = Poppins, headlines = DM Serif.
  static const String bodyFont = 'Poppins';
  static const String displayFont = 'DM Serif Display';

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      // Display + headline: DM Serif Display — the "feeling" voice.
      displaySmall: TextStyle(fontFamily: displayFont, fontSize: 34, fontWeight: FontWeight.w400, color: primary, height: 1.12),
      headlineMedium: TextStyle(fontFamily: displayFont, fontSize: 30, fontWeight: FontWeight.w400, color: primary, height: 1.15),
      headlineSmall: TextStyle(fontFamily: displayFont, fontSize: 24, fontWeight: FontWeight.w400, color: primary, height: 1.2),
      titleLarge: TextStyle(fontFamily: displayFont, fontSize: 25, fontWeight: FontWeight.w400, color: primary, height: 1.15),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 16, color: primary, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: primary, height: 1.4),
      bodySmall: TextStyle(fontSize: 13, color: secondary, height: 1.35),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      labelSmall: TextStyle(fontSize: 12, color: secondary),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.emberCrimson,
      secondary: AppColors.sparkCoral,
      surface: AppColors.plumCharcoal,
      onSurface: AppColors.warmIvory,
      onPrimary: AppColors.warmIvory,
    );
    return ThemeData(
      fontFamily: bodyFont,
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.midnight,
      textTheme: _textTheme(AppColors.warmIvory, AppColors.softRose),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.warmIvory,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emberCrimson, // SOLID primary, never glass
          foregroundColor: AppColors.warmIvory,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.emberCrimson,
      secondary: AppColors.sparkCoral,
      surface: Colors.white,
      onSurface: AppColors.midnight,
      onPrimary: Colors.white,
    );
    return ThemeData(
      fontFamily: bodyFont,
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.porcelain,
      textTheme: _textTheme(AppColors.midnight, const Color(0xFF6E6670)),
      iconTheme: const IconThemeData(size: 22, color: AppColors.midnight),
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
        iconTheme: IconThemeData(size: 22),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.blush,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(fontFamily: bodyFont, fontSize: 13, color: AppColors.midnight),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.porcelainDeep,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.emberCrimson)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.emberCrimson : null),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.midnight, behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emberCrimson,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
