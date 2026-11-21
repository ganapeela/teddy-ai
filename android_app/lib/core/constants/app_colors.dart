import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF151922);
  static const Color surfaceElevated = Color(0xFF1C2230);
  static const Color surfaceLight = Color(0xFF252D3D);
  static const Color border = Color(0xFF232B3B);

  // Accents
  static const Color cyan = Color(0xFF00E5FF);
  static const Color primary = Color(0xFF00E5FF);
  static const Color green = Color(0xFF00E676); // Bullish / CE
  static const Color red = Color(0xFFFF3D71);   // Bearish / PE
  static const Color amber = Color(0xFFFFB300); // Warnings / Traps / Midday
  static const Color purple = Color(0xFFB388FF); // SMC / Order blocks

  // Text
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Chart Overlays
  static const Color vwapColor = Color(0xFFFF9100);
  static const Color ema9Color = Color(0xFF00E5FF);
  static const Color ema20Color = Color(0xFFE040FB);
  static const Color callWallColor = Color(0xFFFF5252);
  static const Color putWallColor = Color(0xFF69F0AE);

  // Trade Box Overlays
  static const Color entryZone = Color(0x3300E5FF);
  static const Color stopLossLine = Color(0xFFFF3D71);
  static const Color targetLine = Color(0xFF00E676);
}
