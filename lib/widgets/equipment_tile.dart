import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Elemento de lista para el inventario de equipamiento disponible (RN-06).
class EquipmentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? tagLabel;
  final Color? tagColor;
  final bool isSelected;
  final ValueChanged<bool> onToggle;
  final Widget? subContent;
  final IconData? trailingIcon;

  const EquipmentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onToggle,
    this.tagLabel,
    this.tagColor,
    this.subContent,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.surfaceElevated
        : AppColors.surfaceContainerLow.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isSelected ? AppColors.borderStrong : AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: AppSpacing.roundedMd,
            child: InkWell(
              onTap: () => onToggle(!isSelected),
              borderRadius: AppSpacing.roundedMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                child: Row(
                  children: [
                    // Checkbox cuadrado con estilo Flat Design
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentEnergy
                            : AppColors.surfaceContainerHighest,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.surfaceBase,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.spaceSm + 2),
                    // Título y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headlineSm.copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.bodySm.copyWith(
                              color: isSelected
                                  ? (tagColor != null && tagLabel == null
                                      ? tagColor
                                      : AppColors.textSecondary)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    // Etiqueta o icono complementario
                    if (tagLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spaceSm,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          tagLabel!,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: tagColor ??
                                (isSelected
                                    ? AppColors.accentEnergy
                                    : AppColors.textMuted),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (trailingIcon != null)
                      Icon(
                        trailingIcon,
                        size: 20,
                        color: isSelected
                            ? AppColors.accentEnergy
                            : AppColors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isSelected && subContent != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.spaceMd,
                right: AppSpacing.spaceMd,
                bottom: AppSpacing.spaceSm,
              ),
              child: subContent!,
            ),
          ],
        ],
      ),
    );
  }
}
