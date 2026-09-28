import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.initialize(
    const AppConfig(
      environment: EnvironmentType.prod,
      appTitle: 'FitTrack AI',
      apiBaseUrl: 'https://api.fittrack.com',
      updateUrl:
          'https://www.dropbox.com/scl/fi/uethct3ngdeuguvefvimg/version.json?rlkey=5budh6zohptmaj5wqfhrh4jrs&st=ajoizpqr&dl=0',
      showDebugBanner: false,
    ),
  );
  app.main();
}
