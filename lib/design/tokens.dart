import 'package:flutter/painting.dart';

/// Figma "Rose Studio" variables — names match the Figma file 1:1.
/// Change a value here, never in a screen.
abstract final class CarinoColors {
  static const canvas = Color(0xFFFFFDFC);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF7F3F2);
  static const blush = Color(0xFFFCE9EC);
  static const primary = Color(0xFFB83255);
  static const pressed = Color(0xFF902640);
  static const ink = Color(0xFF262126);
  static const secondary = Color(0xFF746870);
  static const line = Color(0xFFE9E1E3);
  static const gold = Color(0xFF976B17);
  static const success = Color(0xFF27664F);
  static const danger = Color(0xFFB42338);
  static const white = Color(0xFFFFFFFF);

  /// Bottom of photo cards: transparent → rgba(26,13,20,0.88) (Figma "Photo contrast").
  static const photoContrast = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.5, 1],
    colors: [Color(0x00000000), Color(0x0D000000), Color(0xE01A0D14)],
  );
}

/// 4 pt spacing scale, 20 pt screen margins (Figma visual system).
abstract final class CarinoSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 20.0, xxl = 24.0, xxxl = 28.0;
  static const margin = 20.0;
  static const minTarget = 44.0;
}

abstract final class CarinoRadius {
  static const photoCard = 28.0; // photo cards, hero blocks
  static const card = 24.0; // bottom nav, cards
  static const photo = 20.0; // small photos
  static const chip = 18.0; // chips, tabs
  static const button = 16.0; // buttons, inputs
  static const badge = 15.0;
}
