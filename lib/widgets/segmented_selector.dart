import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const SegmentOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

/// Selector segmentado plano para conmutación de opciones (Sexo, Unidades LB/KG, Duración).
class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final double height;
  final bool isFilledHighContrast;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.height = 48.0,
    this.isFilledHighContrast = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.spaceXs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selectedValue;
          final activeBg = isFilledHighContrast
              ? AppColors.accentEnergy
              : AppColors.surfaceElevated;
          final activeFg = isFilledHighContrast
              ? AppColors.surfaceBase
              : AppColors.accentEnergy;

          final idleFg = AppColors.textSecondary;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Material(
                color: isSelected ? activeBg : Colors.transparent,
                borderRadius: AppSpacing.roundedSm,
                child: InkWell(
                  onTap: () => onSelected(option.value),
                  borderRadius: AppSpacing.roundedSm,
                  child: Container(
                    alignment: Alignment.center,
                    child: option.subtitle == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (option.icon != null) ...[
                                Icon(
                                  option.icon,
                                  size: 18,
                                  color: isSelected ? activeFg : idleFg,
                                ),
                                const SizedBox(width: AppSpacing.spaceXs),
                              ],
                              Text(
                                option.label,
                                style: AppTypography.labelMonoMd.copyWith(
                                  color: isSelected ? activeFg : idleFg,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.label,
                                style: AppTypography.headlineSm.copyWith(
                                  color: isSelected ? activeFg : idleFg,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                option.subtitle!,
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelected ? activeFg : AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
