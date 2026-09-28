import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.initialize(
    const AppConfig(
      environment: EnvironmentType.dev,
      appTitle: 'FitTrack (Dev)',
      apiBaseUrl: 'https://dev-api.fittrack.local',
      updateUrl:
          'https://www.dropbox.com/scl/fi/uethct3ngdeuguvefvimg/version.json?rlkey=5budh6zohptmaj5wqfhrh4jrs&st=ajoizpqr&dl=0',
      showDebugBanner: true,
    ),
  );
  app.main();
}
