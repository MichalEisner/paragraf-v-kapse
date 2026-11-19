import 'package:flutter/material.dart';

/// Exact color palette defined in DESIGN.md for 'Paragraf v Kapse'
class AppColors {
  AppColors._();

  // Primary slate blues
  static const Color primary = Color(0xFF00236F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color onPrimaryContainer = Color(0xFF90A8FF);
  static const Color primaryFixed = Color(0xFFDCE1FF);
  static const Color primaryFixedDim = Color(0xFFB6C4FF);
  static const Color onPrimaryFixed = Color(0xFF00164E);

  // Secondary teals (legal compliance & positive indicators)
  static const Color secondary = Color(0xFF006A61);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF86F2E4);
  static const Color onSecondaryContainer = Color(0xFF006F66);
  static const Color secondaryFixed = Color(0xFF89F5E7);
  static const Color secondaryFixedDim = Color(0xFF6BD8CB);

  // Tertiary crimsons (video badges & critical warnings)
  static const Color tertiary = Color(0xFF5C0016);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF850024);
  static const Color onTertiaryContainer = Color(0xFFFF8991);
  static const Color tertiaryFixed = Color(0xFFFFDADA);
  static const Color tertiaryFixedDim = Color(0xFFFFB3B6);

  // Surface & Canvas
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF444651);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Inverses & outlines
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color outline = Color(0xFF757682);
  static const Color outlineVariant = Color(0xFFC5C5D3);
  static const Color hairlineBorder = Color(0xFFE2E8F0);

  // Error & Danger
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color warning = Color(0xFFD97706);
}
