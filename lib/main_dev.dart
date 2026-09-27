import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.initialize(
    const AppConfig(
      environment: EnvironmentType.dev,
      appTitle: 'FitTrack (Dev)',
      apiBaseUrl: 'https://dev-api.fittrack.local',
      showDebugBanner: true,
    ),
  );
  app.main();
}
