import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'calendar_nutrition_screen.dart';

/// Pantalla de bienvenida (Splash Screen) para FitTrack AI.
/// Cumple con la estética Flat Dark y transiciona a la pantalla de Calendario.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1800),
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    if (widget.duration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToNext());
    } else {
      _navigationTimer = Timer(widget.duration, _navigateToNext);
    }
  }

  void _navigateToNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? const CalendarNutritionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo con rayo cinético
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentEnergy,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(
                            color: AppColors.accentEnergy,
                            width: AppSpacing.borderWidthAccent,
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 48,
                          color: AppColors.surfaceBase,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceLg),
                      // Título de la aplicación
                      Text(
                        'FITTRACK AI',
                        style: AppTypography.headlineXl.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceXs),
                      // Subtítulo técnico
                      Text(
                        'AI-POWERED ATHLETE PERFORMANCE',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2Xl),
                      // Indicador de progreso flat y minimalista
                      SizedBox(
                        width: 140,
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentEnergy,
                          ),
                          minHeight: 2,
                          borderRadius: AppSpacing.roundedFull,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer técnico con arquitectura Local-First
            Positioned(
              bottom: AppSpacing.spaceLg,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accentEnergy,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Text(
                      'LOCAL-FIRST ARCHITECTURE · ENCRYPTED',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
