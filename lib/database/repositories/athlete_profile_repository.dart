import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/athlete_profile.dart';
import '../database_helper.dart';

/// Repositorio SQLite para persistencia local-first del perfil del atleta (RF-CFG-01).
class AthleteProfileRepository {
  final DatabaseHelper _dbHelper;

  AthleteProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Guarda el perfil del atleta en la tabla athlete_profiles de SQLite
  Future<void> saveProfile(AthleteProfile profile) async {
    final db = await _dbHelper.database;

    await db.insert(
      'athlete_profiles',
      {
        'athlete_id': profile.athleteId,
        'biological_sex': profile.biologicalSex,
        'age': profile.age,
        'mass_unit': profile.massUnit,
        'weight_lb': profile.weightInLb,
        'height_cm': profile.heightInCm,
        'session_time_minutes': profile.sessionTimeMinutes,
        'active_days_json': json.encode(profile.activeDays),
        'equipment_inventory_json': json.encode(profile.equipmentInventory),
        'dumbbell_max_weight_kg': profile.dumbbellMaxWeightKg,
        'primary_goal': profile.primaryGoal,
        'secondary_priorities_json': json.encode(profile.secondaryPriorities),
        'bmi': profile.bmi,
        'bmr': profile.bmr,
        'tdee': profile.tdee,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Recupera el perfil del atleta desde SQLite. Retorna null si la base de datos está limpia.
  Future<AthleteProfile?> getProfile({String? athleteId}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'athlete_profiles',
      where: athleteId != null ? 'athlete_id = ?' : null,
      whereArgs: athleteId != null ? [athleteId] : null,
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final row = results.first;
    final activeDays = (json.decode(row['active_days_json'] as String) as List<dynamic>)
        .map((e) => e as bool)
        .toList();

    final equipmentInventory = (json.decode(row['equipment_inventory_json'] as String) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as bool));

    final secondaryPriorities = (json.decode(row['secondary_priorities_json'] as String) as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    return AthleteProfile(
      athleteId: row['athlete_id'] as String,
      biologicalSex: row['biological_sex'] as String,
      age: (row['age'] as num).toInt(),
      massUnit: row['mass_unit'] as String,
      weightInLb: (row['weight_lb'] as num).toDouble(),
      heightInCm: (row['height_cm'] as num).toDouble(),
      sessionTimeMinutes: (row['session_time_minutes'] as num).toInt(),
      activeDays: activeDays,
      equipmentInventory: equipmentInventory,
      dumbbellMaxWeightKg: (row['dumbbell_max_weight_kg'] as num).toDouble(),
      primaryGoal: row['primary_goal'] as String,
      secondaryPriorities: secondaryPriorities,
    );
  }
}
