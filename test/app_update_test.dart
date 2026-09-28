import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fit_track/config/app_config.dart';
import 'package:fit_track/features/app_update/data/models/version_info_model.dart';
import 'package:fit_track/features/app_update/data/services/update_service.dart';
import 'package:fit_track/features/app_update/domain/entities/version_info.dart';
import 'package:fit_track/features/app_update/presentation/widgets/update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    AppConfig.initialize(
      const AppConfig(
        environment: EnvironmentType.dev,
        appTitle: 'FitTrack Test',
        apiBaseUrl: 'https://test.local',
        updateUrl: 'https://test.local/version.json',
      ),
    );
  });

  group('VersionInfo Domain Entity', () {
    test('isNewerThan returns true when buildNumber is higher and version is different', () {
      const info = VersionInfo(
        version: '1.2.0',
        buildNumber: 5,
        url: 'https://example.com/app.apk',
        releaseNotes: ['Note 1'],
      );

      expect(info.isNewerThan('1.1.0', 4), isTrue);
      expect(info.isNewerThan('1.0.0', 1), isTrue);
    });

    test('isNewerThan returns false when buildNumber is equal or lower', () {
      const info = VersionInfo(
        version: '1.2.0',
        buildNumber: 5,
        url: 'https://example.com/app.apk',
        releaseNotes: ['Note 1'],
      );

      expect(info.isNewerThan('1.1.0', 5), isFalse);
      expect(info.isNewerThan('1.1.0', 6), isFalse);
    });

    test('isNewerThan returns false when version is the same', () {
      const info = VersionInfo(
        version: '1.2.0',
        buildNumber: 5,
        url: 'https://example.com/app.apk',
        releaseNotes: ['Note 1'],
      );

      expect(info.isNewerThan('1.2.0', 4), isFalse);
    });
  });

  group('VersionInfoModel Data Model', () {
    const validJson = '''
    {
      "prod": {
        "version": "1.2.0",
        "buildNumber": 4,
        "url": "https://example.com/prod.apk",
        "release_notes": [
          "Estabilidad mejorada",
          "Nuevos gráficos"
        ]
      },
      "dev": {
        "version": "1.3.0-dev",
        "buildNumber": 6,
        "url": "https://example.com/dev.apk",
        "release_notes": [
          "Feature experimental"
        ]
      }
    }
    ''';

    test('parses dev flavor correctly', () {
      final model = VersionInfoModel.fromJson('dev', validJson);
      expect(model.version, '1.3.0-dev');
      expect(model.buildNumber, 6);
      expect(model.url, 'https://example.com/dev.apk');
      expect(model.releaseNotes, ['Feature experimental']);
    });

    test('parses prod flavor correctly', () {
      final model = VersionInfoModel.fromJson('prod', validJson);
      expect(model.version, '1.2.0');
      expect(model.buildNumber, 4);
      expect(model.releaseNotes.length, 2);
    });

    test('falls back to prod when requested flavor is not present', () {
      final model = VersionInfoModel.fromJson('staging', validJson);
      expect(model.version, '1.2.0');
    });

    test('throws FormatException on invalid json structure', () {
      expect(
        () => VersionInfoModel.fromJson('dev', '[]'),
        throwsFormatException,
      );
    });
  });

  group('UpdateService', () {
    test('formatUrl changes dropbox dl=0 to dl=1', () {
      const dropboxUrl = 'https://www.dropbox.com/scl/fi/xyz/app.apk?dl=0';
      expect(
        UpdateService.formatUrl(dropboxUrl),
        'https://www.dropbox.com/scl/fi/xyz/app.apk?dl=1',
      );

      const otherUrl = 'https://storage.googleapis.com/app.apk';
      expect(UpdateService.formatUrl(otherUrl), otherUrl);
    });

    test('checkForUpdates returns VersionInfo when newer version is found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'dev': {
              'version': '2.0.0',
              'buildNumber': 10,
              'url': 'https://example.com/fittrack-2.0.0.apk',
              'release_notes': ['Rediseño completo'],
            }
          }),
          200,
        );
      });

      final result = await UpdateService.checkForUpdates(
        client: mockClient,
        currentVersion: '1.0.0',
        currentBuild: 1,
      );

      expect(result, isNotNull);
      expect(result!.version, '2.0.0');
      expect(result.buildNumber, 10);
    });

    test('checkForUpdates returns null when remote is not newer', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'dev': {
              'version': '1.0.0',
              'buildNumber': 1,
              'url': 'https://example.com/fittrack.apk',
              'release_notes': [],
            }
          }),
          200,
        );
      });

      final result = await UpdateService.checkForUpdates(
        client: mockClient,
        currentVersion: '1.0.0',
        currentBuild: 1,
      );

      expect(result, isNull);
    });

    test('checkForUpdates returns null on HTTP 404/500 or network error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final result = await UpdateService.checkForUpdates(
        client: mockClient,
        currentVersion: '1.0.0',
        currentBuild: 1,
      );

      expect(result, isNull);
    });

    test('downloadAndInstall downloads chunks and writes to file', () async {
      final tempDir = Directory.systemTemp.createTempSync('fittrack_update_test_');

      final apkBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3, 4]);

      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          apkBytes,
          200,
          headers: {'content-type': 'application/vnd.android.package-archive'},
        );
      });

      const info = VersionInfo(
        version: '2.0.0',
        buildNumber: 10,
        url: 'https://example.com/app.apk',
        releaseNotes: ['Test note'],
      );

      final progressValues = <double>[];
      final success = await UpdateService.downloadAndInstall(
        info,
        client: mockClient,
        storageDir: tempDir,
        openInstaller: false,
        onProgress: (p) => progressValues.add(p),
      );

      expect(success, isTrue);
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);

      final downloadedFile = File('${tempDir.path}/update.apk');
      expect(downloadedFile.existsSync(), isTrue);
      expect(downloadedFile.readAsBytesSync(), apkBytes);

      tempDir.deleteSync(recursive: true);
    });

    test('downloadAndInstall fails when content-type is text/html', () async {
      final tempDir = Directory.systemTemp.createTempSync('fittrack_update_test_html_');

      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>Preview Page</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      const info = VersionInfo(
        version: '2.0.0',
        buildNumber: 10,
        url: 'https://drive.google.com/file/xyz',
        releaseNotes: [],
      );

      final success = await UpdateService.downloadAndInstall(
        info,
        client: mockClient,
        storageDir: tempDir,
        openInstaller: false,
        onProgress: (_) {},
      );

      expect(success, isFalse);
      tempDir.deleteSync(recursive: true);
    });
  });

  group('UpdateDialog Widget', () {
    testWidgets('renders version info, release notes, and buttons', (tester) async {
      const info = VersionInfo(
        version: '2.5.0',
        buildNumber: 15,
        url: 'https://example.com/update.apk',
        releaseNotes: [
          'Soporte completo para ejercicios con bandas',
          'Sincronización mejorada con IA',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateDialog(info: info),
          ),
        ),
      );

      expect(find.text('Nueva versión disponible'), findsOneWidget);
      expect(find.text('v2.5.0 (Build 15)'), findsOneWidget);
      expect(find.text('Novedades:'), findsOneWidget);
      expect(
        find.text('Soporte completo para ejercicios con bandas'),
        findsOneWidget,
      );
      expect(
        find.text('Sincronización mejorada con IA'),
        findsOneWidget,
      );
      expect(find.text('AHORA NO'), findsOneWidget);
      expect(find.text('ACTUALIZAR'), findsOneWidget);
    });

    testWidgets('clicking ACTUALIZAR invokes onDownload and updates progress', (tester) async {
      const info = VersionInfo(
        version: '2.5.0',
        buildNumber: 15,
        url: 'https://example.com/update.apk',
        releaseNotes: ['Correcciones menores'],
      );

      bool downloadTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              info: info,
              onDownload: (info, onProgress) async {
                downloadTriggered = true;
                onProgress(0.5);
                await Future.delayed(const Duration(milliseconds: 50));
                onProgress(1.0);
                return true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('ACTUALIZAR'));
      await tester.pump();

      expect(downloadTriggered, isTrue);
      // Cuando está descargando, FlatButton muestra CircularProgressIndicator y el diálogo muestra el texto con porcentaje
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.textContaining('Descargando...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
