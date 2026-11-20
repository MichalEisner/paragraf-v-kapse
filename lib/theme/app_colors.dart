import 'package:flutter/material.dart';

/// Dynamic color palette for 'Paragraf v Kapse', supporting Light and Dark modes.
class AppColors {
  AppColors._();

  static bool isDark = false;

  // Primary slate blues
  static Color get primary => isDark ? const Color(0xFF90A8FF) : const Color(0xFF00236F);
  static Color get onPrimary => isDark ? const Color(0xFF00164E) : const Color(0xFFFFFFFF);
  static Color get primaryContainer => isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1E3A8A);
  static Color get onPrimaryContainer => isDark ? const Color(0xFFDCE1FF) : const Color(0xFF90A8FF);
  static Color get primaryFixed => isDark ? const Color(0xFF283B70) : const Color(0xFFDCE1FF);
  static Color get primaryFixedDim => isDark ? const Color(0xFF1E2D56) : const Color(0xFFB6C4FF);
  static Color get onPrimaryFixed => isDark ? const Color(0xFFDCE1FF) : const Color(0xFF00164E);

  // Secondary teals (legal compliance & positive indicators)
  static Color get secondary => isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61);
  static Color get onSecondary => isDark ? const Color(0xFF003732) : const Color(0xFFFFFFFF);
  static Color get secondaryContainer => isDark ? const Color(0xFF0F766E) : const Color(0xFF86F2E4);
  static Color get onSecondaryContainer => isDark ? const Color(0xFF99F6E4) : const Color(0xFF006F66);
  static Color get secondaryFixed => isDark ? const Color(0xFF134E48) : const Color(0xFF89F5E7);
  static Color get secondaryFixedDim => isDark ? const Color(0xFF115E59) : const Color(0xFF6BD8CB);

  // Tertiary crimsons (video badges & critical warnings)
  static Color get tertiary => isDark ? const Color(0xFFFF8991) : const Color(0xFF5C0016);
  static Color get onTertiary => isDark ? const Color(0xFF450A0A) : const Color(0xFFFFFFFF);
  static Color get tertiaryContainer => isDark ? const Color(0xFF991B1B) : const Color(0xFF850024);
  static Color get onTertiaryContainer => isDark ? const Color(0xFFFECACA) : const Color(0xFFFF8991);
  static Color get tertiaryFixed => isDark ? const Color(0xFF4C0519) : const Color(0xFFFFDADA);
  static Color get tertiaryFixedDim => isDark ? const Color(0xFF881337) : const Color(0xFFFFB3B6);

  // Surface & Canvas
  static Color get surface => isDark ? const Color(0xFF0B132B) : const Color(0xFFF8F9FF);
  static Color get onSurface => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0B1C30);
  static Color get onSurfaceVariant => isDark ? const Color(0xFF94A3B8) : const Color(0xFF444651);
  static Color get surfaceContainerLowest => isDark ? const Color(0xFF111D3E) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerLow => isDark ? const Color(0xFF16234D) : const Color(0xFFEFF4FF);
  static Color get surfaceContainer => isDark ? const Color(0xFF1C2C5E) : const Color(0xFFE5EEFF);
  static Color get surfaceContainerHigh => isDark ? const Color(0xFF23356E) : const Color(0xFFDCE9FF);
  static Color get surfaceContainerHighest => isDark ? const Color(0xFF2B3F7F) : const Color(0xFFD3E4FE);

  // Inverses & outlines
  static Color get inverseSurface => isDark ? const Color(0xFFEAF1FF) : const Color(0xFF213145);
  static Color get inverseOnSurface => isDark ? const Color(0xFF213145) : const Color(0xFFEAF1FF);
  static Color get outline => isDark ? const Color(0xFF94A3B8) : const Color(0xFF757682);
  static Color get outlineVariant => isDark ? const Color(0xFF475569) : const Color(0xFFC5C5D3);
  static Color get hairlineBorder => isDark ? const Color(0xFF24345B) : const Color(0xFFE2E8F0);

  // Error & Danger
  static Color get error => isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A);
  static Color get onError => isDark ? const Color(0xFF450A0A) : const Color(0xFFFFFFFF);
  static Color get errorContainer => isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFDAD6);
  static Color get onErrorContainer => isDark ? const Color(0xFFFECACA) : const Color(0xFF93000A);
  static Color get warning => const Color(0xFFD97706);
}
