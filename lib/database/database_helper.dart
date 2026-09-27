import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gestor centralizado de la base de datos SQLite local (Local-First DERCAS).
class DatabaseHelper {
  static const String _databaseName = 'fittrack_local.db';
  static const int _databaseVersion = 1;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _database;

  /// Permite inyectar una instancia de Database (útil para pruebas unitarias con in-memory SQLite)
  @visibleForTesting
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  /// Permite inicializar esquemas en bases de datos de prueba en memoria
  @visibleForTesting
  Future<void> createTablesForTesting(Database db) async {
    await _onCreate(db, 1);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Si estamos en entorno de pruebas o escritorio (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, _databaseName);
    } catch (_) {
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = p.join(defaultDatabasesPath, _databaseName);
    }

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Perfiles de Atleta (Datos de pantalla de Biometría y Equipamiento RF-CFG-01)
    await db.execute('''
      CREATE TABLE athlete_profiles (
        athlete_id TEXT PRIMARY KEY,
        biological_sex TEXT NOT NULL,
        age INTEGER NOT NULL,
        mass_unit TEXT NOT NULL,
        weight_lb REAL NOT NULL,
        height_cm REAL NOT NULL,
        session_time_minutes INTEGER NOT NULL,
        active_days_json TEXT NOT NULL,
        equipment_inventory_json TEXT NOT NULL,
        dumbbell_max_weight_kg REAL NOT NULL,
        primary_goal TEXT NOT NULL,
        secondary_priorities_json TEXT NOT NULL,
        bmi REAL NOT NULL,
        bmr INTEGER NOT NULL,
        tdee INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Tabla de Generaciones de IA (Prompt enviado y JSON retornado RF-IA-01)
    await db.execute('''
      CREATE TABLE ai_generations (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        provider TEXT NOT NULL,
        model TEXT NOT NULL,
        prompt_text TEXT NOT NULL,
        raw_response_json TEXT NOT NULL,
        weeks_count INTEGER NOT NULL,
        primary_goal TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // 3. Tabla de Planes de Rutina (derivados del JSON de la IA)
    await db.execute('''
      CREATE TABLE routine_plans (
        id TEXT PRIMARY KEY,
        ai_generation_id TEXT,
        weeks INTEGER NOT NULL,
        primary_goal TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ai_generation_id) REFERENCES ai_generations (id) ON DELETE SET NULL
      )
    ''');

    // 4. Tabla de Días de la Rutina y Calendario (RF-CAL-01)
    await db.execute('''
      CREATE TABLE routine_days (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        day_letter TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        dia_semana TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        session_title TEXT NOT NULL,
        session_number_label TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        equipment_summary TEXT,
        rpe INTEGER NOT NULL DEFAULT 8,
        warmup_json TEXT,
        finisher_json TEXT,
        target_calories INTEGER NOT NULL,
        target_protein_grams INTEGER NOT NULL,
        target_water_liters REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (plan_id) REFERENCES routine_plans (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabla de Ejercicios de la Rutina: guarda fecha, series, repeticiones y equipo
    await db.execute('''
      CREATE TABLE routine_exercises (
        id TEXT PRIMARY KEY,
        routine_day_id TEXT NOT NULL,
        plan_id TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        dia_semana TEXT NOT NULL,
        block_number INTEGER NOT NULL,
        block_type TEXT NOT NULL,
        exercise_order TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        series INTEGER NOT NULL,
        repeticiones_objetivo INTEGER NOT NULL,
        equipo_requerido TEXT NOT NULL,
        descanso_segundos INTEGER NOT NULL,
        peso_sugerido_kg REAL,
        notas_tecnicas TEXT,
        is_bodyweight INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (routine_day_id) REFERENCES routine_days (id) ON DELETE CASCADE
      )
    ''');

    // 6. Tabla de Sesiones de Entrenamiento Ejecutadas (RF-EXE-01 / RF-EXE-02 / Resumen)
    await db.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        scheduled_date TEXT NOT NULL,
        day_date TEXT NOT NULL,
        session_title TEXT NOT NULL,
        adherence_percent INTEGER NOT NULL,
        record_headline TEXT,
        record_description TEXT,
        total_volume_kg INTEGER NOT NULL,
        volume_trend_percent REAL,
        duration_formatted TEXT NOT NULL,
        target_duration_minutes INTEGER,
        rest_efficiency_percent INTEGER,
        average_rpe REAL NOT NULL,
        completed_sets INTEGER NOT NULL,
        total_sets INTEGER NOT NULL,
        executed_blocks INTEGER,
        motor_score TEXT,
        motor_feedback TEXT,
        mood TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 7. Tabla de Series Ejecutadas (Cargas y RPE por serie RF-EXE-02)
    await db.execute('''
      CREATE TABLE workout_set_logs (
        id TEXT PRIMARY KEY,
        workout_log_id TEXT,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        scheduled_date TEXT NOT NULL,
        target_reps INTEGER NOT NULL,
        actual_reps INTEGER NOT NULL,
        target_weight_kg REAL NOT NULL,
        actual_weight_kg REAL NOT NULL,
        target_rpe REAL NOT NULL,
        actual_rpe REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        is_pr INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (workout_log_id) REFERENCES workout_logs (id) ON DELETE CASCADE
      )
    ''');

    // 8. Tabla de Nutrición Diaria Registrada (RF-NUT-01 / Pantalla de Macronutrientes)
    await db.execute('''
      CREATE TABLE daily_nutrition_logs (
        id TEXT PRIMARY KEY,
        date_label TEXT NOT NULL UNIQUE,
        phase_label TEXT NOT NULL,
        current_calories INTEGER NOT NULL,
        target_calories INTEGER NOT NULL,
        current_protein INTEGER NOT NULL,
        target_protein INTEGER NOT NULL,
        current_carbs INTEGER NOT NULL,
        target_carbs INTEGER NOT NULL,
        current_fat INTEGER NOT NULL,
        target_fat INTEGER NOT NULL,
        water_liters REAL NOT NULL,
        target_water_liters REAL NOT NULL,
        water_glasses INTEGER NOT NULL,
        total_water_glasses INTEGER NOT NULL,
        ai_advice_title TEXT,
        ai_advice_text TEXT,
        meals_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Índices para consultas de alto rendimiento
    await db.execute('CREATE INDEX idx_routine_exercises_date ON routine_exercises (scheduled_date)');
    await db.execute('CREATE INDEX idx_routine_exercises_day ON routine_exercises (dia_semana)');
    await db.execute('CREATE INDEX idx_routine_days_date ON routine_days (scheduled_date)');
    await db.execute('CREATE INDEX idx_workout_sets_exercise ON workout_set_logs (exercise_name)');
    await db.execute('CREATE INDEX idx_ai_generations_plan ON ai_generations (plan_id)');
  }

  /// Limpia todas las tablas (útil para pruebas o reinicio de datos)
  Future<void> clearAllTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('workout_set_logs');
      await txn.delete('workout_logs');
      await txn.delete('daily_nutrition_logs');
      await txn.delete('routine_exercises');
      await txn.delete('routine_days');
      await txn.delete('routine_plans');
      await txn.delete('ai_generations');
      await txn.delete('athlete_profiles');
    });
  }

  /// Cierra la conexión
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
