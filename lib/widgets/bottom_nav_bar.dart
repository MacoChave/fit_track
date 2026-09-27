import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Barra de navegación inferior móvil para FitTrack AI (Flat Design).
class FitTrackBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const FitTrackBottomNavBar({
    super.key,
    this.currentIndex = 2, // Ajustes seleccionado por defecto
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(icon: Icons.calendar_today, label: 'Calendario'),
      _NavItem(icon: Icons.restaurant, label: 'Nutrición'),
      _NavItem(icon: Icons.tune, label: 'Ajustes'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceBase,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: AppSpacing.borderWidthSubtle,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == currentIndex;
              final color = isSelected
                  ? AppColors.accentEnergy
                  : AppColors.textSecondary;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onIndexChanged(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 22, color: color),
                        const SizedBox(height: 3),
                        Text(
                          item.label.toUpperCase(),
                          style: AppTypography.labelMonoSm.copyWith(
                            color: color,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 0.6,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
