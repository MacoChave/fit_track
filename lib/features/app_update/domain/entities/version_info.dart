class VersionInfo {
  final String version;
  final int buildNumber;
  final String url;
  final List<String> releaseNotes;

  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.releaseNotes,
  });

  /// Compara la versión actual de la aplicación con la versión representada por esta instancia.
  /// Devuelve true si la versión de esta instancia es más reciente que la versión actual proporcionada.
  /// @param currentVersion La versión actual de la aplicación. Formato: "x.y.z"
  /// @param currentBuild El número de compilación actual de la aplicación. Formato: entero.
  /// @return true si la versión de esta instancia es más reciente que la versión actual proporcionada.
  /// Ejemplo de uso:
  /// VersionInfo newVersion = VersionInfo(version: "1.2.0", buildNumber: 40, url: "https://example.com", releaseNotes: ["Mejoras y correcciones"]);
  /// bool isUpdateAvailable = newVersion.isNewerThan("1.1.0", 40);
  /// Resultado esperado: true si la nueva versión es más reciente que la actual, false en caso contrario.
  /// Nota: Esta comparación, debe tener en cuenta tanto la semántica de la versión (x.y.z) como el número de compilación.
  bool isNewerThan(String currentVersion, int currentBuild) {
    final currentVersionParts = currentVersion
        .split('.')
        .map(int.parse)
        .toList();
    final thisVersionParts = version.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (thisVersionParts[i] > currentVersionParts[i]) return true;
      if (thisVersionParts[i] < currentVersionParts[i]) return false;
    }
    return buildNumber > currentBuild;
  }
}
