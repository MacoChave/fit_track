import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Tarjeta pura de Flat Design sin sombras, delimitada por color y bordes sólidos de 1px.
class FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const FlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.spaceMd),
    this.backgroundColor = AppColors.surfaceCard,
    this.borderColor = AppColors.borderSubtle,
    this.borderWidth = AppSpacing.borderWidthSubtle,
    this.borderRadius = AppSpacing.roundedLg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.accentEnergy.withValues(alpha: 0.1),
        highlightColor: AppColors.surfaceElevated,
        child: container,
      );
    }

    return container;
  }
}
