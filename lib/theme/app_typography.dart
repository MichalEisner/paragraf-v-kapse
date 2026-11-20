import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration matching DESIGN.md with Plus Jakarta Sans & Space Grotesk
class AppTypography {
  AppTypography._();

  static TextStyle displayLg({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 40 / 32,
        letterSpacing: -0.03 * 32,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle displayMd({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 34 / 26,
        letterSpacing: -0.02 * 26,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle headlineLg({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        letterSpacing: -0.01 * 22,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle headlineSm({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle bodyLg({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle bodyMd({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle bodySm({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: color ?? AppColors.onSurfaceVariant,
      );

  static TextStyle labelButton({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 20 / 15,
        color: color ?? Colors.white,
      );

  static TextStyle labelBadge({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.02 * 11,
        color: color ?? AppColors.onSurfaceVariant,
      );

  /// Statutory citation marker (§ 34 ZP) with Space Grotesk and tabular figures
  static TextStyle labelLaw({Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.04 * 12,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? AppColors.primary,
      );
}
