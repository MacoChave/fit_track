import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/byok_config.dart';
import 'package:fit_track/services/secure_key_service.dart';
import 'package:fit_track/services/ai_connection_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BYOK Security & API Key Management (RF-CFG-02 / RN-03 / RNF-01)', () {
    test('SecureKeyService almacena, recupera y enmascara credencial localmente', () async {
      final secureStorage = SecureKeyService.instance;

      const testKey = 'AIzaSyA8B7C6D5E4F3G2H1I0J9K8L7M6N5O4P3Q';
      await secureStorage.saveApiKey(testKey, provider: 'gemini');

      final retrieved = await secureStorage.getApiKey(provider: 'gemini');
      expect(retrieved, testKey);

      final hasKey = await secureStorage.hasApiKey(provider: 'gemini');
      expect(hasKey, isTrue);

      final masked = await secureStorage.getMaskedApiKey(provider: 'gemini');
      expect(masked.startsWith('AIza'), isTrue);
      expect(masked.endsWith('4P3Q'), isTrue);
      expect(masked.contains('••••'), isTrue);

      // Verificación de borrado
      await secureStorage.deleteApiKey(provider: 'gemini');
      final afterDelete = await secureStorage.getApiKey(provider: 'gemini');
      expect(afterDelete, isNull);
    });

    test('AiConnectionTester maneja clave vacía con error HTTP 400', () async {
      final tester = AiConnectionTester.instance;
      final result = await tester.testConnection(
        provider: AiProvider.gemini,
        apiKey: '   ',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 400);
      expect(result.errorMessage, contains('no puede estar vacía'));
    });

    test('AiConnectionTester detecta credenciales inválidas (HTTP 401) según Criterio de Aceptación RF-CFG-02', () async {
      final tester = AiConnectionTester.instance;
      final result = await tester.testConnection(
        provider: AiProvider.gemini,
        apiKey: 'INVALID_AI_KEY_TEST',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 401);
      expect(result.statusText, contains('401'));
      expect(result.errorMessage, contains('API_KEY_INVALID'));
    });

    test('AiConnectionTester realiza ping exitoso (HTTP 200 OK) para claves verosímiles', () async {
      final tester = AiConnectionTester.instance;
      final result = await tester.testConnection(
        provider: AiProvider.gemini,
        apiKey: 'AIzaSy_MOCK_TEST_KEY_4P3Q',
      );

      expect(result.isSuccess, isTrue);
      expect(result.statusCode, 200);
      expect(result.testCode, 'TC-01');
      expect(result.statusText, contains('HTTP 200 OK'));
      expect(result.quotaInfo, contains('Tier Gratuito'));
      expect(result.verifiedModel, contains('gemini-1.5'));
    });
  });
}
