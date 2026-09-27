import 'package:flutter/material.dart';

/// Design tokens de color para FitTrack Pure Flat Design System.
/// Basado fielmente en el proyecto Stitch 11058469531837432389.
class AppColors {
  const AppColors._();

  // Primary & Kinetic Accents
  static const Color primary = Color(0xFF75FF9E);
  static const Color accentEnergy = Color(0xFF00E676); // Kinetic Electric Lime
  static const Color primaryContainer = Color(0xFF00E676);
  static const Color onPrimary = Color(0xFF003918);
  static const Color onPrimaryContainer = Color(0xFF00612E);

  // Secondary Accents (Progression / Success)
  static const Color secondary = Color(0xFF4AE176);
  static const Color secondarySuccess = Color(0xFF22C55E);
  static const Color secondaryContainer = Color(0xFF00B954);
  static const Color onSecondary = Color(0xFF003915);

  // Tertiary & Metric Accents
  static const Color tertiary = Color(0xFFB3EEFF);
  static const Color tertiaryContainer = Color(0xFF4FD9F8);
  static const Color accentWater = Color(0xFF06B6D4); // Cyan Metric

  // Functional Alerts & RPE
  static const Color accentRpe = Color(0xFFF59E0B); // Amber Attention / RPE
  static const Color accentRest = Color(0xFFEF4444); // Rest / Coral Red
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);

  // Pure Flat Surfaces
  static const Color surfaceBase = Color(0xFF121316);
  static const Color background = Color(0xFF121316);
  static const Color surface = Color(0xFF121316);
  static const Color surfaceDim = Color(0xFF121316);
  static const Color surfaceBright = Color(0xFF38393C);

  static const Color surfaceCard = Color(0xFF1A1C20);
  static const Color surfaceElevated = Color(0xFF22252A);

  static const Color surfaceContainerLowest = Color(0xFF0D0E11);
  static const Color surfaceContainerLow = Color(0xFF1B1B1F);
  static const Color surfaceContainer = Color(0xFF1F1F23);
  static const Color surfaceContainerHigh = Color(0xFF292A2D);
  static const Color surfaceContainerHighest = Color(0xFF343538);
  static const Color surfaceVariant = Color(0xFF343538);

  // Borders & Contours (Flat strict 1px / 2px)
  static const Color borderSubtle = Color(0xFF2E3239);
  static const Color borderStrong = Color(0xFF3F444E);
  static const Color outline = Color(0xFF859585);
  static const Color outlineVariant = Color(0xFF3B4A3D);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color onSurface = Color(0xFFE3E2E6);
  static const Color onSurfaceVariant = Color(0xFFBACBB9);
}
