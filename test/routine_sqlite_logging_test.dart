import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fit_track/database/database_helper.dart';
import 'package:fit_track/database/repositories/ai_routine_repository.dart';
import 'package:fit_track/database/repositories/workout_repository.dart';
import 'package:fit_track/models/calendar_models.dart';
import 'package:fit_track/screens/calendar_nutrition_screen.dart';
import 'package:fit_track/screens/workout_logging_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Database testDb;
  late DatabaseHelper dbHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbHelper = DatabaseHelper.instance;
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => dbHelper.createTablesForTesting(db),
      ),
    );
    dbHelper.setDatabaseForTesting(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  const sampleAiJson = '''
  {
    "plan_id": "plan_test_001",
    "semanas": 4,
    "objetivo_primario": "Fuerza e Hipertrofia",
    "dias": [
      {
        "dia_semana": "Lunes",
        "dia_numero": 1,
        "tipo_sesion": "Fuerza Torso Pesado",
        "duracion_minutos": 45,
        "calorias_objetivo": 2100,
        "proteina_objetivo_g": 150,
        "agua_objetivo_l": 2.5,
        "bloques": [
          {
            "bloque_numero": 1,
            "tipo": "Fuerza Base",
            "duracion_minutos": 45,
            "ejercicios": [
              {
                "orden": "A1",
                "ejercicio_id": "bench_press_barbell",
                "nombre": "Press de banca con barra",
                "series": 4,
                "repeticiones_objetivo": 8,
                "rpe_objetivo": 8.0,
                "equipo_requerido": "Barra Olímpica",
                "descanso_segundos": 90,
                "peso_sugerido_kg": 60.0,
                "notas_tecnicas": "Pausa controlada de 1s en el pecho"
              },
              {
                "orden": "A2",
                "ejercicio_id": "bent_over_row",
                "nombre": "Remo con barra",
                "series": 3,
                "repeticiones_objetivo": 10,
                "rpe_objetivo": 8.0,
                "equipo_requerido": "Barra Olímpica",
                "descanso_segundos": 75,
                "peso_sugerido_kg": 50.0,
                "notas_tecnicas": "Espalda neutra a 45 grados"
              }
            ]
          }
        ]
      }
    ]
  }
  ''';

  group('AI Routine SQLite & Screen Consumption Tests', () {
    test('Importing AI Routine stores exercises, series, reps and equipment in SQLite', () async {
      final aiRepo = AiRoutineRepository();
      await aiRepo.importRoutineFromJson(sampleAiJson);

      final schedules = await aiRepo.getWeekSchedule();
      expect(schedules.isNotEmpty, isTrue);

      final exercises = await aiRepo.getRoutineExercises();
      expect(exercises.length, 2);

      final bench = exercises.firstWhere((e) => e.exerciseId == 'bench_press_barbell');
      expect(bench.exerciseName, 'Press de banca con barra');
      expect(bench.series, 4);
      expect(bench.repeticionesObjetivo, 8);
      expect(bench.equipoRequerido, 'Barra Olímpica');
      expect(bench.pesoSugeridoKg, 60.0);
      expect(bench.notasTecnicas, 'Pausa controlada de 1s en el pecho');
    });

    testWidgets('CalendarNutritionScreen consumes routine from SQLite and renders AI routine data', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late List<DaySchedule> schedules;
      await tester.runAsync(() async {
        final aiRepo = AiRoutineRepository();
        await aiRepo.importRoutineFromJson(sampleAiJson);
        schedules = await aiRepo.getWeekSchedule();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarNutritionScreen(initialSchedule: schedules),
        ),
      );
      await tester.pump();

      // Seleccionar el día Lunes en el selector semanal (donde está programada la rutina de la IA)
      final mondayTab = find.text('L').first;
      await tester.tap(mondayTab);
      await tester.pump();

      // Debería mostrar la sesión o ejercicios importados desde SQLite
      expect(find.text('Press de banca con barra'), findsOneWidget);
      expect(find.textContaining('Barra Olímpica'), findsWidgets);
    });

    testWidgets('WorkoutLoggingScreen initializes routine with exercises, sets, reps and equipment from AI', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DaySchedule mondaySchedule;
      await tester.runAsync(() async {
        final aiRepo = AiRoutineRepository();
        await aiRepo.importRoutineFromJson(sampleAiJson);
        final schedules = await aiRepo.getWeekSchedule();
        mondaySchedule = schedules.first;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(
            daySchedule: mondaySchedule,
          ),
        ),
      );
      await tester.pump();

      // Debe mostrar el nombre del ejercicio inyectado
      expect(find.text('Press de banca con barra'), findsWidgets);

      // Debe mostrar el equipo requerido
      expect(find.text('BARRA OLÍMPICA'), findsOneWidget);

      // Debe mostrar el peso inicial sugerido (60.0)
      expect(find.text('60.0'), findsOneWidget);

      // Debe mostrar la serie activa inicial (Serie 1 de 4)
      expect(find.text('EN VIVO · SERIE 1 DE 4'), findsOneWidget);

      // Debe tener botón para confirmar serie 1
      expect(find.text('Confirmar Serie 1 y Descansar'), findsOneWidget);
    });

    testWidgets('WorkoutLoggingScreen persists set log to SQLite upon confirming a set', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DaySchedule mondaySchedule;
      await tester.runAsync(() async {
        final aiRepo = AiRoutineRepository();
        await aiRepo.importRoutineFromJson(sampleAiJson);
        final schedules = await aiRepo.getWeekSchedule();
        mondaySchedule = schedules.first;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(
            daySchedule: mondaySchedule,
          ),
        ),
      );
      await tester.pump();

      // Confirmar serie 1
      final confirmBtn = find.text('Confirmar Serie 1 y Descansar');
      await tester.tap(confirmBtn);
      await tester.pump();

      // Validar que se guardó en SQLite
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        final workoutRepo = WorkoutRepository();
        final lastLog = await workoutRepo.getLastLoggedWeightAndReps('Press de banca con barra');
        expect(lastLog, isNotNull);
        expect(lastLog!['actualWeightKg'], 60.0);
        expect(lastLog['actualReps'], 8);
      });
      await tester.pump();

      // La serie 2 debe pasar a ser la activa
      expect(find.text('EN VIVO · SERIE 2 DE 4'), findsOneWidget);
      expect(find.text('Confirmar Serie 2 y Descansar'), findsOneWidget);
    });

    testWidgets('WorkoutLoggingScreen updating weight and reps persists to SQLite', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = const ExerciseItem(
        order: 'A1',
        name: 'Sentadilla Hack',
        description: 'Máquina Hack · 3 Series × 10 Reps',
        seriesAndReps: '3 Series × 10 Reps',
        weightKg: 80.0,
        restSeconds: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutLoggingScreen(
            initialExercise: exercise,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sentadilla Hack'), findsWidgets);
      expect(find.text('80.0'), findsOneWidget);

      // Subir peso con +
      final plusBtn = find.text('+');
      await tester.tap(plusBtn);
      await tester.pump();
      expect(find.text('81.0'), findsOneWidget);

      // Confirmar serie
      final confirmBtn2 = find.text('Confirmar Serie 1 y Descansar');
      await tester.tap(confirmBtn2);
      await tester.pump();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        final workoutRepo = WorkoutRepository();
        final lastLog = await workoutRepo.getLastLoggedWeightAndReps('Sentadilla Hack');
        expect(lastLog, isNotNull);
        expect(lastLog!['actualWeightKg'], 81.0);
      });
    });

    test('WorkoutLoggingScreen markDayCompleted updates routine_days in SQLite', () async {
      final aiRepo = AiRoutineRepository();
      await aiRepo.importRoutineFromJson(sampleAiJson);
      final schedules = await aiRepo.getWeekSchedule();
      final day = schedules.first;

      await aiRepo.markDayCompleted(dayNumber: day.dayNumber);

      final updatedSchedules = await aiRepo.getWeekSchedule();
      final updatedDay = updatedSchedules.firstWhere((d) => d.dayNumber == day.dayNumber);
      expect(updatedDay.statusType, DayStatusType.completed);
    });
  });
}
