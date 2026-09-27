import 'package:flutter/material.dart';

/// Constantes de espaciado, curvaturas y ergonomía táctil (RNF-04).
class AppSpacing {
  const AppSpacing._();

  // Escala de espaciado estricto (8pt rhythm scale)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2Xl = 48.0;

  static const double margin = 16.0;
  static const double gutter = 16.0;

  // Ergonomía táctil para entrenamiento (mínimo 56dp per design system)
  static const double minTouchTarget = 56.0;
  static const double primaryButtonHeight = 58.0;

  // Radios de esquina del Flat Design
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Bordes planos sin sombras
  static const double borderWidthSubtle = 1.0;
  static const double borderWidthAccent = 2.0;
}
