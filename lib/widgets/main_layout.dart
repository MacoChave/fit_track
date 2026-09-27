import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_header.dart';
import 'bottom_nav_bar.dart';

/// Layout principal para FitTrack AI (Opción 1: Layout Wrapper por pantalla).
/// Provee una estructura unificada sin Drawer, integrando Toolbar (AppHeader),
/// el contenido de la pantalla (child) y la barra de navegación inferior (FitTrackBottomNavBar).
class MainLayout extends StatelessWidget {
  final Widget child;

  // --- Toolbar / Header ---
  final String title;
  final String? subtitle;
  final PreferredSizeWidget? customAppBar;
  final bool showAppBar;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;
  final bool showSyncBadge;
  final String syncLabel;
  final VoidCallback? onSyncPressed;
  final bool showProfileAvatar;
  final VoidCallback? onProfilePressed;
  final Widget? leading;
  final List<Widget>? actions;

  // --- Barra de Navegación Inferior ---
  final int? currentNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final Widget? customBottomNavBar;
  final bool showBottomNavBar;

  // --- Propiedades del Scaffold ---
  final Color backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;

  const MainLayout({
    super.key,
    required this.child,
    this.title = 'FITTRACK AI',
    this.subtitle,
    this.customAppBar,
    this.showAppBar = true,
    this.showBackButton,
    this.onBackPressed,
    this.showSyncBadge = true,
    this.syncLabel = 'SYNC',
    this.onSyncPressed,
    this.showProfileAvatar = true,
    this.onProfilePressed,
    this.leading,
    this.actions,
    this.currentNavIndex,
    this.onNavIndexChanged,
    this.customBottomNavBar,
    this.showBottomNavBar = true,
    this.backgroundColor = AppColors.surfaceBase,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? appBarWidget;
    if (showAppBar) {
      appBarWidget = customAppBar ??
          AppHeader(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed,
            showSyncBadge: showSyncBadge,
            syncLabel: syncLabel,
            onSyncPressed: onSyncPressed,
            showProfileAvatar: showProfileAvatar,
            onProfilePressed: onProfilePressed,
            leading: leading,
            actions: actions,
          );
    }

    Widget? bottomNavWidget;
    if (showBottomNavBar) {
      if (customBottomNavBar != null) {
        bottomNavWidget = customBottomNavBar;
      } else if (currentNavIndex != null && onNavIndexChanged != null) {
        bottomNavWidget = FitTrackBottomNavBar(
          currentIndex: currentNavIndex!,
          onIndexChanged: onNavIndexChanged!,
        );
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBarWidget,
      body: child,
      bottomNavigationBar: bottomNavWidget,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
