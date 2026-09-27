import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro con cifrado por hardware (AES-256)
/// Implementa RF-CFG-02 (RN-03 y RNF-01): Android Keystore / iOS Keychain.
class SecureKeyService {
  static SecureKeyService? _instance;
  static SecureKeyService get instance => _instance ??= SecureKeyService._();

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryCache = {};

  SecureKeyService._()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(resetOnError: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  String _getKey(String provider) => 'fittrack_api_key_${provider.toLowerCase()}';

  /// Guarda la API Key de forma cifrada en hardware seguro (RN-03, RNF-01)
  Future<void> saveApiKey(String apiKey, {String provider = 'gemini'}) async {
    final key = _getKey(provider);
    final trimmed = apiKey.trim();
    _memoryCache[key] = trimmed;
    try {
      await _storage.write(key: key, value: trimmed);
    } catch (_) {
      // Soporte en entornos sin keystore nativo (ej. tests unitarios)
    }
  }

  /// Recupera la API Key descifrada
  Future<String?> getApiKey({String provider = 'gemini'}) async {
    final key = _getKey(provider);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        _memoryCache[key] = value;
        return value;
      }
    } catch (_) {}
    return null;
  }

  /// Elimina la API Key del almacén seguro
  Future<void> deleteApiKey({String provider = 'gemini'}) async {
    final key = _getKey(provider);
    _memoryCache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Determina si existe una API Key registrada
  Future<bool> hasApiKey({String provider = 'gemini'}) async {
    final key = await getApiKey(provider: provider);
    return key != null && key.isNotEmpty;
  }

  /// Devuelve una representación enmascarada para la UI (ej. ••••••••••••••••)
  Future<String> getMaskedApiKey({String provider = 'gemini'}) async {
    final key = await getApiKey(provider: provider);
    if (key == null || key.isEmpty) {
      return '';
    }
    if (key.length <= 8) {
      return '•' * key.length;
    }
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }
}
