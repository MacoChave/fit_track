import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.initialize(
    const AppConfig(
      environment: EnvironmentType.prod,
      appTitle: 'FitTrack AI',
      apiBaseUrl: 'https://api.fittrack.com',
      updateUrl: 'https://raw.githubusercontent.com/fittrack/releases/main/version.json',
      showDebugBanner: false,
    ),
  );
  app.main();
}
