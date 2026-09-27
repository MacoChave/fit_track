import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía del Design System FitTrack Pure Flat.
/// Implementa Plus Jakarta Sans para contenido y Space Mono para métricas/datos tabulares.
class AppTypography {
  const AppTypography._();

  // --- Plus Jakarta Sans (Headlines y Body) ---

  static TextStyle get headlineXl => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 40 / 32,
        letterSpacing: -0.64, // -0.02em
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.24, // -0.01em
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSm => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: AppColors.textSecondary,
      );

  // --- Space Mono (Timers, Métricas, Etiquetas tabulares) ---

  static TextStyle get timerDisplay => GoogleFonts.spaceMono(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        height: 72 / 64,
        letterSpacing: -2.56, // -0.04em
        color: AppColors.textPrimary,
      );

  static TextStyle get timerDisplayMobile => GoogleFonts.spaceMono(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 54 / 48,
        letterSpacing: -1.44, // -0.03em
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMonoLg => GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMonoMd => GoogleFonts.spaceMono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMonoSm => GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 14 / 11,
        letterSpacing: 0.55, // 0.05em
        color: AppColors.textSecondary,
      );
}
