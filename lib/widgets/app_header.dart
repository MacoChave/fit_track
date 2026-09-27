import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Header principal reutilizable para FitTrack AI (Flat Design).
/// Cumple con la especificación de diseño y la interfaz PreferredSizeWidget.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;
  final bool showSyncBadge;
  final String syncLabel;
  final VoidCallback? onSyncPressed;
  final bool showProfileAvatar;
  final VoidCallback? onProfilePressed;
  final Widget? leading;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.title = 'FITTRACK AI',
    this.subtitle,
    this.showBackButton,
    this.onBackPressed,
    this.showSyncBadge = true,
    this.syncLabel = 'SYNC',
    this.onSyncPressed,
    this.showProfileAvatar = true,
    this.onProfilePressed,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBackButton ?? Navigator.canPop(context);

    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBase,
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderSubtle,
              width: AppSpacing.borderWidthSubtle,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sección Izquierda: Botón volver + Ícono/Logo + Título y Subtítulo
                Row(
                  children: [
                    if (canPop) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: onBackPressed ?? () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                    ],
                    leading ??
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.accentEnergy,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: const Icon(
                            Icons.bolt,
                            size: 22,
                            color: AppColors.surfaceBase,
                          ),
                        ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Sección Derecha: Acciones personalizadas o Badges por defecto (SYNC y Avatar)
                if (actions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSyncBadge) ...[
                        GestureDetector(
                          onTap: onSyncPressed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spaceSm + 2,
                              vertical: AppSpacing.spaceXs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentEnergy,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  syncLabel,
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.accentEnergy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spaceSm),
                      ],
                      if (showProfileAvatar)
                        GestureDetector(
                          onTap: onProfilePressed,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceElevated,
                              border: Border.all(
                                color: AppColors.borderStrong,
                                width: AppSpacing.borderWidthSubtle,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 22,
                              color: AppColors.accentEnergy,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
