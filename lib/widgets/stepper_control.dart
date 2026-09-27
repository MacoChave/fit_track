import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Control numérico de incremento/decremento con objetivos táctiles amplios (56dp) y fuente monoespaciada sin jitter.
class StepperControl extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final String? suffix;

  const StepperControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 999,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(
            icon: Icons.remove,
            enabled: value > minValue,
            onPressed: () {
              if (value > minValue) onChanged(value - 1);
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: AppTypography.labelMonoLg.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: AppSpacing.spaceXs),
                Text(
                  suffix!,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                  ),
                ),
              ],
            ],
          ),
          _buildButton(
            icon: Icons.add,
            enabled: value < maxValue,
            onPressed: () {
              if (value < maxValue) onChanged(value + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: enabled ? AppColors.surfaceElevated : AppColors.surfaceContainer,
      borderRadius: AppSpacing.roundedSm,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppSpacing.roundedSm,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
