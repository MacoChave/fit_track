import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;

    return MaterialApp(
      title: config.appTitle,
      debugShowCheckedModeBanner: config.showDebugBanner,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.surfaceBase,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accentEnergy,
          surface: AppColors.surfaceBase,
          error: AppColors.accentRest,
        ),
        splashColor: AppColors.accentEnergy.withValues(alpha: 0.1),
        highlightColor: AppColors.surfaceElevated,
      ),
      home: const SplashScreen(),
    );
  }
}
