import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.initialize(
    const AppConfig(
      environment: EnvironmentType.dev,
      appTitle: 'FitTrack (Dev)',
      apiBaseUrl: 'https://dev-api.fittrack.local',
      updateUrl: 'https://raw.githubusercontent.com/fittrack/releases/dev/version.json',
      showDebugBanner: true,
    ),
  );
  app.main();
}
