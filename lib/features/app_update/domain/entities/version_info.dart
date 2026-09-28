class VersionInfo {
  final String version;
  final int buildNumber;
  final String url;
  final List<String> releaseNotes;
  final String? appName;

  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.releaseNotes,
    this.appName,
  });

  /// Compara la versión actual de la aplicación con la versión representada por esta instancia.
  /// Devuelve true si la versión de esta instancia es más reciente que la versión actual proporcionada.
  /// @param currentVersion La versión actual de la aplicación. Formato: "x.y.z" o "x.y.z-tag"
  /// @param currentBuild El número de compilación actual de la aplicación. Formato: entero.
  /// @return true si la versión de esta instancia es más reciente que la versión actual proporcionada.
  /// Nota: Esta comparación tiene en cuenta tanto la semántica de la versión (x.y.z) como el número de compilación.
  bool isNewerThan(String currentVersion, int currentBuild) {
    final currentParts = _parseVersionParts(currentVersion);
    final thisParts = _parseVersionParts(version);

    for (int i = 0; i < 3; i++) {
      if (thisParts[i] > currentParts[i]) return true;
      if (thisParts[i] < currentParts[i]) return false;
    }
    return buildNumber > currentBuild;
  }

  static List<int> _parseVersionParts(String ver) {
    if (ver.isEmpty) return [0, 0, 0];
    // Remueve etiquetas pre-release como -dev, -beta.1, etc.
    final clean = ver.split('-').first.trim();
    final parts = clean.split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }
}
