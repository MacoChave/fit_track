import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_track/database/database_helper.dart';
import 'package:fit_track/database/repositories/ai_routine_repository.dart';
import 'package:fit_track/models/athlete_profile.dart';
import 'package:fit_track/screens/api_key_config_screen.dart';
import 'package:fit_track/screens/biometrics_equipment_screen.dart';
import 'package:fit_track/services/manual_routine_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Inicializar SQLite FFI para pruebas
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late DatabaseHelper dbHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.instance;
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
        },
      ),
    );

    dbHelper.setDatabaseForTesting(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  const sampleJsonFromWeb = '''
```json
{
  "plan_id": "plan-manual-web-99",
  "semanas": 4,
  "objetivo_primario": "Definicion y Fuerza",
  "dias": [
    {
      "dia_semana": "Lunes",
      "enfoque": "Empuje con Mancuernas",
      "duracion_estimada_min": 40,
      "calentamiento": [
        { "nombre": "Movilidad articular", "duracion_seg": 60 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "press_mancuernas",
              "nombre": "Press de banca con mancuernas",
              "series": 4,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 60,
              "equipo_requerido": "mancuernas",
              "notas_tecnicas": "Cadencia controlada 2-0-1-0"
            }
          ]
        }
      ],
      "finisher_core": {
        "nombre": "Plancha abdominal",
        "duracion_seg": 180
      },
      "guia_nutricional": {
        "calorias_objetivo": 2000,
        "proteina_gramos": 150,
        "agua_litros": 3.2
      }
    }
  ]
}
```
''';

  group('Manual Routine Importer Service Tests', () {
    test('Importa JSON con bloques markdown y guarda fecha, series, reps y equipo en SQLite', () async {
      const athlete = AthleteProfile(
        primaryGoal: 'Definicion y Fuerza',
      );

      final result = await ManualRoutineImporter.instance.importJsonString(
        sampleJsonFromWeb,
        profile: athlete,
      );

      expect(result.isSuccess, isTrue);
      expect(result.daysCount, 1);
      expect(result.exercisesCount, 1);
      expect(result.planId, 'plan-manual-web-99');

      // Verificar en SQLite
      final repo = AiRoutineRepository(dbHelper: dbHelper);
      final exercises = await repo.getRoutineExercises(diaSemana: 'Lunes');

      expect(exercises.length, 1);
      final ex = exercises.first;
      expect(ex.exerciseName, 'Press de banca con mancuernas');
      expect(ex.series, 4); // SERIES
      expect(ex.repeticionesObjetivo, 10); // REPETICIONES
      expect(ex.equipoRequerido, 'mancuernas'); // EQUIPO
      expect(ex.descansoSegundos, 60);
      expect(ex.scheduledDate, isNotEmpty); // FECHA

      // Verificar que se guardó en ai_generations
      final history = await repo.getAiGenerationHistory();
      expect(history.length, 1);
      expect(history.first.provider, contains('Manual / Web LLM'));
      expect(history.first.planId, 'plan-manual-web-99');
    });

    test('Rechaza JSON vacío o inválido', () async {
      final resEmpty = await ManualRoutineImporter.instance.importJsonString('');
      expect(resEmpty.isSuccess, isFalse);
      expect(resEmpty.message, contains('vacío'));

      final resMalformed = await ManualRoutineImporter.instance.importJsonString('{ json_invalido: ');
      expect(resMalformed.isSuccess, isFalse);
      expect(resMalformed.message, contains('Error de sintaxis'));
    });
  });

  group('UI Integration Tests: Manual Mode without API Key', () {
    testWidgets('ApiKeyConfigScreen renders manual AI mode card and buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ApiKeyConfigScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a pestaña Modo Manual
      final manualTab = find.text('MODO MANUAL');
      expect(manualTab, findsOneWidget);
      await tester.tap(manualTab);
      await tester.pumpAndSettle();

      // Verificar tarjeta de modo manual sin API Key
      expect(find.text('MODO MANUAL (SIN API KEY)'), findsOneWidget);
      expect(find.text('100% GRATUITO'), findsOneWidget);
      expect(find.text('COPIAR PROMPT PARA MI IA'), findsOneWidget);
      expect(find.text('CARGAR ARCHIVO JSON (.JSON / .TXT)'), findsOneWidget);
    });

    testWidgets('BiometricsEquipmentScreen renders manual prompt and JSON buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: BiometricsEquipmentScreen(initialProfile: AthleteProfile()),
        ),
      );
      await tester.pump();

      expect(find.text('COPIAR PROMPT'), findsOneWidget);
      expect(find.text('CARGAR JSON'), findsOneWidget);
    });
  });
}
