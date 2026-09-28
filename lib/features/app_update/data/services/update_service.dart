import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fit_track/config/app_config.dart';
import 'package:fit_track/features/app_update/domain/entities/version_info.dart';
import 'package:fit_track/features/app_update/data/models/version_info_model.dart';

class UpdateService {
  /// Asegura que los enlaces de Dropbox se descarguen en lugar de mostrar la página web
  static String formatUrl(String url) {
    if (url.contains('dropbox.com')) {
      return url.replaceAll('dl=0', 'dl=1');
    }
    return url;
  }

  /// Descarga el manifiesto de versiones del entorno actual y compara con la versión instalada
  static Future<VersionInfo?> checkForUpdates({
    String? updateUrl,
    http.Client? client,
    String? currentVersion,
    int? currentBuild,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final targetUrl = updateUrl ?? AppConfig.current.updateUrl;
      if (targetUrl.isEmpty) return null;

      final uri = Uri.parse(formatUrl(targetUrl));
      final response = await httpClient.get(uri);

      if (response.statusCode != 200) return null;

      String localVersion = currentVersion ?? '';
      int localBuild = currentBuild ?? 0;

      if (currentVersion == null || currentBuild == null) {
        try {
          final info = await PackageInfo.fromPlatform();
          localVersion = info.version;
          localBuild = int.tryParse(info.buildNumber) ?? 0;
        } catch (_) {
          // Fallback if PackageInfo fails or is running in headless unit tests
        }
      }

      final flavorString = AppConfig.current.environment.name;
      final remote = VersionInfoModel.fromJson(flavorString, response.body);

      return remote.isNewerThan(localVersion, localBuild) ? remote : null;
    } catch (error) {
      if (kDebugMode) {
        print('Error durante checkForUpdates: $error');
      }
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Descarga el archivo APK y lanza el instalador de paquetes
  static Future<bool> downloadAndInstall(
    VersionInfo info, {
    required ValueChanged<double> onProgress,
    http.Client? client,
    Directory? storageDir,
    bool openInstaller = true,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      Directory? dir = storageDir;
      if (dir == null) {
        try {
          dir = await getExternalStorageDirectory();
        } catch (_) {
          // getExternalStorageDirectory may fail or be unsupported
        }
        dir ??= await getTemporaryDirectory();
      }

      final path = '${dir.path}/update.apk';
      final finalApkUrl = formatUrl(info.url);
      final request =
          await httpClient.send(http.Request('GET', Uri.parse(finalApkUrl)));

      if (request.statusCode != 200) {
        throw Exception('Falló la descarga con código: ${request.statusCode}');
      }

      if (request.headers['content-type']?.contains('text/html') == true) {
        throw Exception(
          'El enlace de descarga devolvió una página HTML en lugar del APK. '
          'Verifica el enlace (por ej. advertencia de Google Drive o Dropbox).',
        );
      }

      final total = request.contentLength ?? 0;
      final file = File(path);
      final sink = file.openWrite();
      int received = 0;

      await for (final chunk in request.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        } else {
          // Si no hay Content-Length, enviar un valor proporcional simbólico
          onProgress(0.5);
        }
      }

      await sink.flush();
      await sink.close();

      if (openInstaller) {
        await OpenFilex.open(
          path,
          type: 'application/vnd.android.package-archive',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error durante la descarga o instalación: $e');
      }
      return false;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
