import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum FlatButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
}

/// Botón ergonómico para entrenamientos con altura mínima de 56dp (RNF-04) y cero sombras.
class FlatButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final FlatButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;

  const FlatButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = FlatButtonVariant.primary,
    this.isLoading = false,
    this.height = AppSpacing.primaryButtonHeight,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    Border? border;

    switch (variant) {
      case FlatButtonVariant.primary:
        bgColor = AppColors.accentEnergy;
        fgColor = AppColors.surfaceBase;
        border = null;
        break;
      case FlatButtonVariant.secondary:
        bgColor = AppColors.surfaceElevated;
        fgColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.borderSubtle, width: 1.0);
        break;
      case FlatButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.borderStrong, width: 2.0);
        break;
      case FlatButtonVariant.destructive:
        bgColor = AppColors.accentRest;
        fgColor = AppColors.textPrimary;
        border = null;
        break;
    }

    final isInteractive = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: AppSpacing.roundedLg,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: AppSpacing.roundedLg,
          splashColor: Colors.black26,
          highlightColor: Colors.black12,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              border: border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fgColor, size: 22),
                        const SizedBox(width: AppSpacing.spaceSm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: AppTypography.headlineSm.copyWith(
                            color: fgColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
