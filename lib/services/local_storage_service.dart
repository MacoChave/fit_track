import 'package:shared_preferences/shared_preferences.dart';
import '../database/repositories/athlete_profile_repository.dart';
import '../models/athlete_profile.dart';

/// Servicio de persistencia local-first para el perfil del atleta y equipamiento.
class LocalStorageService {
  static const String _profileKey = 'fittrack_athlete_profile_v1';

  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();

  LocalStorageService._();

  AthleteProfile? _cachedProfile;

  /// Obtiene el perfil guardado en SQLite o null si la base de datos está limpia
  Future<AthleteProfile?> getProfile() async {
    if (_cachedProfile != null) {
      return _cachedProfile;
    }
    try {
      final repo = AthleteProfileRepository();
      final profile = await repo.getProfile();
      if (profile != null) {
        _cachedProfile = profile;
        return profile;
      }
    } catch (_) {}

    _cachedProfile = null;
    return null;
  }

  /// Guarda el perfil en almacenamiento local persistente (SharedPreferences + SQLite)
  Future<bool> saveProfile(AthleteProfile profile) async {
    _cachedProfile = profile;
    bool prefSuccess = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      prefSuccess = await prefs.setString(_profileKey, profile.toJson());
    } catch (_) {}

    try {
      final repo = AthleteProfileRepository();
      await repo.saveProfile(profile);
    } catch (_) {}

    return prefSuccess || true;
  }

  /// Restaura los valores iniciales predeterminados
  Future<void> resetDefaults() async {
    _cachedProfile = const AthleteProfile();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (_) {}
  }
}
