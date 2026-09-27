import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fit_track/database/database_helper.dart';
import 'package:fit_track/models/calendar_models.dart';
import 'package:fit_track/screens/calendar_nutrition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Calendar & Nutrition Models (RF-CAL-01 / RF-NUT-01)', () {
    test('getWeekData genera 7 jornadas alineadas con el plan activo', () {
      final days = DaySchedule.getWeekData();
      expect(days.length, 7);

      final tuesday = days[1];
      expect(tuesday.dayLetter, 'M');
      expect(tuesday.dayNumber, 22);
      expect(tuesday.statusType, DayStatusType.today);
      expect(tuesday.sessionTitle, 'Empuje y Densidad Metabólica');
      expect(tuesday.durationMinutes, 40);
      expect(tuesday.blocks.length, 3);
      expect(tuesday.targetCalories, 1900);
      expect(tuesday.targetProteinGrams, 145);
      expect(tuesday.meals.length, 4);
    });

    test('Estructura de bloques y ejercicios cumple con DERCAS RF-CAL-01', () {
      final tuesday = DaySchedule.getWeekData()[1];

      final warmUp = tuesday.blocks[0];
      expect(warmUp.title, contains('Calentamiento'));
      expect(warmUp.exercises.length, 2);

      final mainBlock = tuesday.blocks[1];
      expect(mainBlock.title, contains('Fuerza Base'));
      expect(mainBlock.exercises.length, 2);
      expect(mainBlock.exercises[0].name, 'Press de pecho con mancuernas');
      expect(mainBlock.exercises[0].technicalNote, isNotNull);

      final finisher = tuesday.blocks[2];
      expect(finisher.title, contains('Finisher & Core'));
      expect(finisher.exercises[0].name, 'Tabata Mountain Climbers');
    });
  });

  group('CalendarNutritionScreen Widget UI & Interactions', () {
    testWidgets('Renderiza correctamente cabecera, selector de 7 días y bloques', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarNutritionScreen(initialSchedule: DaySchedule.getWeekData()),
        ),
      );
      await tester.pumpAndSettle();

      // Validar cabecera y estado
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('CALENDARIO'), findsNWidgets(2)); // En header y bottom nav
      expect(find.text('SEMANA 1 · FASE DÉFICIT Y FUERZA'), findsOneWidget);
      expect(find.text('Local-First'), findsOneWidget);
      expect(find.text('HOY'), findsOneWidget);

      // Validar tarjeta Hero de sesión
      expect(find.text('Empuje y Densidad Metabólica'), findsOneWidget);
      expect(find.text('Iniciar Sesión (40m)'), findsOneWidget);

      // Validar bloques de ejercicio (RF-CAL-01)
      expect(find.text('ESTRUCTURA DE LA RUTINA'), findsOneWidget);
      expect(find.text('BLOQUE 1 · CALENTAMIENTO'), findsOneWidget);
      expect(find.text('BLOQUE 2 · FUERZA BASE'), findsOneWidget);
      expect(find.text('BLOQUE 3 · FINISHER & CORE'), findsOneWidget);
      expect(find.text('Press de pecho con mancuernas'), findsOneWidget);

      // Validar panel de nutrición (RF-NUT-01)
      expect(find.text('GUÍA NUTRICIONAL DIARIA'), findsOneWidget);
      expect(find.text('BALANCE ENERGÉTICO'), findsOneWidget);
      expect(find.text('+25g Proteína'), findsOneWidget);
      expect(find.text('+0.75 L Agua'), findsOneWidget);
      expect(find.text('PLAN DE COMIDAS SUGERIDO'), findsOneWidget);
      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
    });

    testWidgets('Permite alternar registro rápido de proteína y agua', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarNutritionScreen(initialSchedule: DaySchedule.getWeekData()),
        ),
      );
      await tester.pumpAndSettle();

      // Probar toggle de proteína
      expect(find.text('110g'), findsOneWidget);
      final proteinButton = find.text('+25g Proteína');
      await tester.tap(proteinButton);
      await tester.pumpAndSettle();

      expect(find.text('135g'), findsOneWidget);

      // Probar toggle de agua
      final waterButton = find.text('+0.75 L Agua');
      await tester.tap(waterButton);
      await tester.pumpAndSettle();

      expect(find.text('3.0 L COMPLETADO'), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
    });

    testWidgets('Muestra estado limpio sin datos hardcodeados cuando la base de datos está limpia', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: CalendarNutritionScreen(initialSchedule: []),
        ),
      );
      await tester.pump();

      // Debe mostrar cabecera de base limpia y NO mostrar Martes 22 o Empuje
      expect(find.text('SIN PLAN DE ENTRENAMIENTO'), findsOneWidget);
      expect(find.text('Base Limpia'), findsOneWidget);
      expect(find.text('BASE DE DATOS LIMPIA'), findsOneWidget);
      expect(find.text('Generar / Importar Rutina con IA'), findsOneWidget);
      expect(find.text('Empuje y Densidad Metabólica'), findsNothing);
    });
  });
}
