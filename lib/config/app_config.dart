enum EnvironmentType { dev, prod }

/// Configuración global de la aplicación según el entorno (develop vs producción)
class AppConfig {
  final EnvironmentType environment;
  final String appTitle;
  final String apiBaseUrl;
  final bool showDebugBanner;

  const AppConfig({
    required this.environment,
    required this.appTitle,
    required this.apiBaseUrl,
    this.showDebugBanner = false,
  });

  static AppConfig? _current;

  static AppConfig get current =>
      _current ??
      const AppConfig(
        environment: EnvironmentType.dev,
        appTitle: 'FitTrack (Dev)',
        apiBaseUrl: 'https://dev-api.fittrack.local',
        showDebugBanner: true,
      );

  static void initialize(AppConfig config) {
    _current = config;
  }

  bool get isDev => environment == EnvironmentType.dev;
  bool get isProd => environment == EnvironmentType.prod;
}
