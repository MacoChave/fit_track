import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fit_track/database/database_helper.dart';
import 'package:fit_track/database/repositories/ai_routine_repository.dart';
import 'package:fit_track/database/repositories/athlete_profile_repository.dart';
import 'package:fit_track/database/repositories/nutrition_repository.dart';
import 'package:fit_track/database/repositories/workout_repository.dart';
import 'package:fit_track/models/athlete_profile.dart';
import 'package:fit_track/models/nutrition_models.dart';
import 'package:fit_track/models/workout_execution_models.dart';
import 'package:fit_track/models/workout_summary_models.dart';
import 'package:fit_track/services/ai_prompt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Inicializar FFI para pruebas SQLite en memoria
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late DatabaseHelper dbHelper;
  late AiRoutineRepository aiRoutineRepo;
  late AthleteProfileRepository athleteRepo;
  late WorkoutRepository workoutRepo;
  late NutritionRepository nutritionRepo;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Ejecutar las mismas sentencias que en DatabaseHelper
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

          await db.execute('''
            CREATE TABLE routine_plans (
              id TEXT PRIMARY KEY,
              ai_generation_id TEXT,
              weeks INTEGER NOT NULL,
              primary_goal TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL
            )
          ''');

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
              status TEXT NOT NULL DEFAULT 'pending'
            )
          ''');

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
              is_bodyweight INTEGER NOT NULL DEFAULT 0
            )
          ''');

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
              created_at TEXT NOT NULL
            )
          ''');

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
        },
      ),
    );

    dbHelper.setDatabaseForTesting(testDb);
    aiRoutineRepo = AiRoutineRepository(dbHelper: dbHelper);
    athleteRepo = AthleteProfileRepository(dbHelper: dbHelper);
    workoutRepo = WorkoutRepository(dbHelper: dbHelper);
    nutritionRepo = NutritionRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SQLite Database & Athlete Profile Tests (RF-CFG-01)', () {
    test('Guarda y recupera el perfil antropométrico y equipamiento', () async {
      const profile = AthleteProfile(
        athleteId: 'ATLETA-36A',
        biologicalSex: 'M',
        age: 36,
        massUnit: 'lb',
        weightInLb: 182.0,
        heightInCm: 170.0,
        sessionTimeMinutes: 45,
        dumbbellMaxWeightKg: 24.0,
        primaryGoal: 'FAT_LOSS',
      );

      await athleteRepo.saveProfile(profile);

      final loaded = await athleteRepo.getProfile(athleteId: 'ATLETA-36A');
      expect(loaded, isNotNull);
      expect(loaded!.athleteId, 'ATLETA-36A');
      expect(loaded.age, 36);
      expect(loaded.weightInLb, 182.0);
      expect(loaded.heightInCm, 170.0);
      expect(loaded.bmi, greaterThan(28.0));
      expect(loaded.bmi, lessThan(29.0));
      expect(loaded.bmiCategory, 'Sobrepeso / Masa Muscular');
      expect(loaded.sessionTimeMinutes, 45);
      expect(loaded.equipmentInventory['adjustable_dumbbells'], isTrue);
    });
  });

  group('AI Prompt Builder Tests (RF-IA-01, RN-05, RN-06)', () {
    test('Construye prompt con restricciones de tiempo, equipamiento y contrato JSON 5.2', () {
      const profile = AthleteProfile(
        age: 36,
        weightInLb: 182.0,
        sessionTimeMinutes: 40,
        equipmentInventory: {
          'adjustable_dumbbells': true,
          'bodyweight': true,
          'ab_wheel': true,
          'barbell': false,
        },
      );

      final prompt = AiPromptBuilder.buildPrompt(profile);

      expect(prompt, contains('36 años'));
      expect(prompt, contains('40 minutos'));
      expect(prompt, contains('adjustable_dumbbells'));
      expect(prompt, contains('ab_wheel'));
      expect(prompt, isNot(contains('barbell: true')));
      expect(prompt, contains('RN-05'));
      expect(prompt, contains('RN-06'));
      expect(prompt, contains('"plan_id": "uuid-v4"'));
      expect(prompt, contains('"calorias_objetivo"'));
    });
  });

  group('AI Prompt & JSON Persistence and Extraction Tests (RF-IA-01, DERCAS 5.2)', () {
    const sampleAiJson = '''
{
  "plan_id": "plan-uuid-7788",
  "semanas": 4,
  "objetivo_primario": "Perdida de Grasa y Definicion",
  "dias": [
    {
      "dia_semana": "Lunes",
      "enfoque": "Empuje y Densidad Metabolica",
      "duracion_estimada_min": 40,
      "calentamiento": [
        { "nombre": "Rotaciones articulares", "duracion_seg": 60 },
        { "nombre": "Sentadilla libre", "repeticiones": 15 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "press_mancuernas_plano",
              "nombre": "Press de pecho con mancuernas",
              "series": 3,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 60,
              "equipo_requerido": "mancuernas",
              "notas_tecnicas": "Mantener retraccion escapular y 2s en la bajada"
            },
            {
              "id": "flexiones_declinadas",
              "nombre": "Flexiones declinadas",
              "series": 3,
              "repeticiones_objetivo": 12,
              "descanso_segundos": 45,
              "equipo_requerido": "peso_corporal",
              "notas_tecnicas": "Énfasis en haz clavicular"
            }
          ]
        },
        {
          "tipo": "Finisher & Core",
          "ejercicios": [
            {
              "id": "tabata_mountain_climbers",
              "nombre": "Tabata Mountain Climbers",
              "series": 8,
              "repeticiones_objetivo": 20,
              "descanso_segundos": 10,
              "equipo_requerido": "peso_corporal",
              "notas_tecnicas": "20s max esfuerzo, 10s pausa"
            }
          ]
        }
      ],
      "finisher_core": {
        "nombre": "Tabata Mountain Climbers",
        "duracion_seg": 240
      },
      "guia_nutricional": {
        "calorias_objetivo": 1900,
        "proteina_gramos": 145,
        "agua_litros": 3.0
      }
    }
  ]
}''';

    test('Guarda el prompt y respuesta JSON íntegros en ai_generations', () async {
      const promptText = 'Generar rutina para atleta 36 años, 182 lb, mancuernas.';
      final record = await aiRoutineRepo.saveAiPromptAndResponse(
        prompt: promptText,
        rawJson: sampleAiJson,
        provider: 'Google Gemini',
        model: 'gemini-1.5-flash',
      );

      expect(record.id, isNotEmpty);
      expect(record.planId, 'plan-uuid-7788');
      expect(record.weeksCount, 4);
      expect(record.primaryGoal, 'Perdida de Grasa y Definicion');
      expect(record.promptText, promptText);
      expect(record.rawResponseJson, sampleAiJson);

      final history = await aiRoutineRepo.getAiGenerationHistory();
      expect(history.length, 1);
      expect(history.first.provider, 'Google Gemini');
      expect(history.first.promptText, promptText);
    });

    test('Parsea el JSON y guarda fecha, series, repeticiones y equipo en routine_exercises', () async {
      final mondayDate = DateTime(2026, 9, 21); // Lunes 21 Sep 2026
      await aiRoutineRepo.importRoutineFromJson(
        sampleAiJson,
        aiGenerationId: 'gen_123',
        weekStartDate: mondayDate,
      );

      // Consultar ejercicios guardados para el Lunes
      final exercises = await aiRoutineRepo.getRoutineExercises(
        scheduledDate: '2026-09-21',
      );

      expect(exercises.length, 3);

      // Ejercicio 1: Press con mancuernas
      final ex1 = exercises[0];
      expect(ex1.scheduledDate, '2026-09-21'); // FECHA
      expect(ex1.diaSemana, 'Lunes');
      expect(ex1.exerciseName, 'Press de pecho con mancuernas');
      expect(ex1.series, 3); // SERIES
      expect(ex1.repeticionesObjetivo, 10); // REPETICIONES
      expect(ex1.equipoRequerido, 'mancuernas'); // EQUIPO
      expect(ex1.descansoSegundos, 60);
      expect(ex1.notasTecnicas, contains('retraccion escapular'));
      expect(ex1.isBodyweight, isFalse);

      // Ejercicio 2: Flexiones declinadas (peso corporal)
      final ex2 = exercises[1];
      expect(ex2.scheduledDate, '2026-09-21'); // FECHA
      expect(ex2.series, 3); // SERIES
      expect(ex2.repeticionesObjetivo, 12); // REPETICIONES
      expect(ex2.equipoRequerido, 'peso_corporal'); // EQUIPO
      expect(ex2.isBodyweight, isTrue);

      // Ejercicio 3: Tabata Mountain Climbers
      final ex3 = exercises[2];
      expect(ex3.scheduledDate, '2026-09-21'); // FECHA
      expect(ex3.series, 8); // SERIES
      expect(ex3.repeticionesObjetivo, 20); // REPETICIONES
      expect(ex3.equipoRequerido, 'peso_corporal'); // EQUIPO
    });

    test('Consulta el calendario semanal estructurado para la pantalla de Calendario', () async {
      final mondayDate = DateTime(2026, 9, 21);
      await aiRoutineRepo.importRoutineFromJson(
        sampleAiJson,
        weekStartDate: mondayDate,
      );

      final week = await aiRoutineRepo.getWeekSchedule(referenceDate: mondayDate);
      expect(week.isNotEmpty, isTrue);

      final lunes = week.firstWhere((d) => d.dayLetter == 'L');
      expect(lunes.sessionTitle, 'Empuje y Densidad Metabolica');
      expect(lunes.targetCalories, 1900);
      expect(lunes.targetProteinGrams, 145);
      expect(lunes.targetWaterLiters, 3.0);
      expect(lunes.blocks.length, 3);
      final strengthBlock = lunes.blocks.firstWhere((b) => b.blockNumber == 1);
      expect(strengthBlock.exercises.length, 2);
      expect(strengthBlock.exercises[0].name, 'Press de pecho con mancuernas');
      expect(strengthBlock.exercises[0].seriesAndReps, '3 Series × 10 Reps');
    });
  });

  group('Workout Logging & Set History Tests (RF-EXE-01, RF-EXE-02)', () {
    test('Guarda serie individual y recupera última carga para pre-poblado (placeholder)', () async {
      final set = WorkoutSet(
        setNumber: 1,
        targetReps: 10,
        targetWeightKg: 22.0,
        actualReps: 10,
        actualWeightKg: 22.0,
        targetRpe: 8.0,
        actualRpe: 8.0,
        status: WorkoutSetStatus.completed,
        notes: 'Cadencia 2-0-1-0 limpia',
      );

      await workoutRepo.saveSetLog(
        set: set,
        exerciseName: 'Press de pecho con mancuernas',
        date: DateTime(2026, 9, 21),
      );

      // Verificar que getLastLoggedWeightAndReps recupera los 22kg y 10 reps
      final last = await workoutRepo.getLastLoggedWeightAndReps('Press de pecho con mancuernas');
      expect(last, isNotNull);
      expect(last!['actualWeightKg'], 22.0);
      expect(last['actualReps'], 10);
      expect(last['actualRpe'], 8.0);
      expect(last['notes'], 'Cadencia 2-0-1-0 limpia');
    });

    test('Guarda resumen completo de sesión y consulta historial en SQLite', () async {
      final summary = WorkoutSummaryData.getSampleSummary();
      await workoutRepo.saveWorkoutSummary(summary, mood: 'Energizado 💪');

      final logs = await workoutRepo.getWorkoutLogsHistory();
      expect(logs.length, 1);
      final log = logs.first;
      expect(log['session_title'], 'Empuje y Densidad Metabólica');
      expect(log['total_volume_kg'], 4180);
      expect(log['adherence_percent'], 100);
      expect(log['mood'], 'Energizado 💪');

      final sets = await workoutRepo.getSetsForSession(log['id'] as String);
      expect(sets.isNotEmpty, isTrue);
    });
  });

  group('Daily Nutrition Persistence Tests (RF-NUT-01)', () {
    test('Guarda y recupera datos nutricionales y lista de comidas en SQLite', () async {
      final sampleDay = NutritionDayData.getSampleDay();
      await nutritionRepo.saveDailyNutrition(sampleDay);

      final retrieved = await nutritionRepo.getDailyNutrition('MARTES 22');
      expect(retrieved, isNotNull);
      expect(retrieved!.dateLabel, 'MARTES 22');
      expect(retrieved.currentCalories, 1420);
      expect(retrieved.targetCalories, 1900);
      expect(retrieved.currentProtein, 115);
      expect(retrieved.waterLiters, 2.25);
      expect(retrieved.meals.length, 4);
      expect(retrieved.meals[0].name, 'Desayuno');
      expect(retrieved.meals[0].items.length, 2);
    });
  });
}
