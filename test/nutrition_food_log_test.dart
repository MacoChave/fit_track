import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/nutrition_models.dart';
import 'package:fit_track/screens/macronutrients_food_log_screen.dart';

void main() {
  group('Nutrition Models Unit Tests', () {
    test('NutritionDayData generates correct default sample data', () {
      final day = NutritionDayData.getSampleDay();

      expect(day.dateLabel, 'MARTES 22');
      expect(day.phaseLabel, 'DÉFICIT MODERADO');
      expect(day.currentCalories, 1420);
      expect(day.targetCalories, 1900);
      expect(day.remainingCalories, 480);

      expect(day.currentProtein, 115);
      expect(day.targetProtein, 145);

      expect(day.currentCarbs, 140);
      expect(day.targetCarbs, 190);

      expect(day.currentFat, 44);
      expect(day.targetFat, 60);

      expect(day.waterLiters, 2.25);
      expect(day.targetWaterLiters, 3.0);
      expect(day.waterGlasses, 3);
      expect(day.totalWaterGlasses, 4);

      expect(day.meals.length, 4);
      expect(day.meals[0].name, 'Desayuno');
      expect(day.meals[0].status, MealStatus.completed);
      expect(day.meals[1].name, 'Almuerzo');
      expect(day.meals[1].status, MealStatus.completed);
      expect(day.meals[2].name, 'Snack de la Tarde');
      expect(day.meals[2].status, MealStatus.pending);
      expect(day.meals[3].name, 'Cena');
      expect(day.meals[3].status, MealStatus.planned);
    });

    test('addWater increments water volume and glasses', () {
      final day = NutritionDayData.getSampleDay();
      day.addWater(0.25);

      expect(day.waterLiters, 2.5);
      expect(day.waterGlasses, 3);

      day.addWater(0.5);
      expect(day.waterLiters, 3.0);
      expect(day.waterGlasses, 4);
    });

    test('addQuickOptionToMeal updates meal items, calories and macros', () {
      final day = NutritionDayData.getSampleDay();
      const option = QuickAddOption(
        id: 'yogurt',
        name: 'Yogur Griego 0%',
        macroLabel: '(15g P)',
        calories: 90,
        proteinGrams: 15,
        carbsGrams: 4,
        fatGrams: 0,
        type: MacroNutrientType.protein,
      );

      final initialCalories = day.currentCalories;
      final initialProtein = day.currentProtein;

      day.addQuickOptionToMeal('snack', option);

      final snack = day.meals.firstWhere((m) => m.id == 'snack');
      expect(snack.items.length, 1);
      expect(snack.items.first.name, 'Yogur Griego 0%');
      expect(snack.calories, 90);
      expect(snack.proteinGrams, 15);

      expect(day.currentCalories, initialCalories + 90);
      expect(day.currentProtein, initialProtein + 15);
    });
  });

  group('MacronutrientsFoodLogScreen Widget Tests', () {
    testWidgets('Renders all main sections, cards, and UI modules', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MacronutrientsFoodLogScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Top Header
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('NUTRICIÓN'), findsWidgets);
      expect(find.text('SYNC'), findsOneWidget);

      // Contextual Header
      expect(find.text('MARTES 22 · FASE: DÉFICIT MODERADO'), findsOneWidget);
      expect(find.text('BYOK AI PLAN'), findsOneWidget);
      expect(find.text('Macronutrientes'), findsOneWidget);
      expect(find.text('AYER'), findsOneWidget);
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('MAÑANA'), findsOneWidget);

      // Macro Summary Card
      expect(find.text('INGESTA CALÓRICA'), findsOneWidget);
      expect(find.text('1420'), findsOneWidget);
      expect(find.text('/ 1900 KCAL'), findsOneWidget);
      expect(find.text('RESTAN 480 KCAL'), findsOneWidget);
      expect(find.text('PROTEÍNA'), findsOneWidget);
      expect(find.text('CARBS'), findsOneWidget);
      expect(find.text('GRASAS'), findsOneWidget);

      // Hydration
      expect(find.text('HIDRATACIÓN'), findsOneWidget);
      expect(find.text('2.25 L / 3.0 L (3/4 Vasos)'), findsOneWidget);
      expect(find.text('250 ml'), findsOneWidget);

      // Meals Section
      expect(find.text('COMIDAS DEL DÍA'), findsOneWidget);
      expect(find.text('2 de 4 registradas'), findsOneWidget);
      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('Snack de la Tarde'), findsOneWidget);
      expect(find.text('Cena'), findsOneWidget);

      // Quick Adds
      expect(find.text('1-TAP QUICK ADDS HABITUALES:'), findsOneWidget);
      expect(find.text('Yogur Griego 0%'), findsOneWidget);
      expect(find.text('Batido Isolatado'), findsOneWidget);
      expect(find.text('Puñado Almendras'), findsOneWidget);
      expect(find.text('Añadir Alimento o Foto IA'), findsOneWidget);

      // AI Assistant Card
      expect(find.text('Asistente Nutricional (Zero-Server)'), findsOneWidget);
      expect(find.text('ON-DEVICE'), findsOneWidget);
      expect(find.text('AJUSTAR CENA AUTOMÁTICAMENTE CON IA'), findsOneWidget);

      // Actions
      expect(find.text('GUARDAR REGISTRO DIARIO (OFFLINE)'), findsOneWidget);
      expect(find.text('ESCANEAR CÓDIGO'), findsOneWidget);
      expect(find.text('REGISTRO POR VOZ'), findsOneWidget);
    });

    testWidgets('Adds water on button tap and updates volume', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MacronutrientsFoodLogScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      expect(find.text('2.25 L / 3.0 L (3/4 Vasos)'), findsOneWidget);

      // Tap +250 ml
      final addWaterBtn = find.byKey(const Key('add_water_btn'));
      expect(addWaterBtn, findsOneWidget);

      await tester.tap(addWaterBtn);
      await tester.pump();

      // Now 2.50 L
      expect(find.text('2.50 L / 3.0 L (3/4 Vasos)'), findsOneWidget);
      expect(find.text('+250 ml agua registrada (2.50 L totales)'), findsOneWidget);
    });

    testWidgets('Applies 1-tap quick add and updates snack and calories', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MacronutrientsFoodLogScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      expect(find.text('1420'), findsOneWidget);

      // Tap quick add for yogurt (+90 kcal, +15g P)
      final yogurtChip = find.byKey(const Key('quick_add_yogurt'));
      expect(yogurtChip, findsOneWidget);

      await tester.tap(yogurtChip);
      await tester.pump();

      // 1420 + 90 = 1510
      expect(find.text('1510'), findsOneWidget);
      expect(find.text('Añadido: Yogur Griego 0% ((15g P)) a Snack'), findsOneWidget);
    });

    testWidgets('Applies dinner suggestion on APLICAR button tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MacronutrientsFoodLogScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      final applyBtn = find.byKey(const Key('apply_dinner_btn'));
      expect(applyBtn, findsOneWidget);

      await tester.tap(applyBtn);
      await tester.pump();

      expect(find.text('¡Cena sugerida aplicada con éxito!'), findsOneWidget);
      expect(find.text('09:15 PM'), findsOneWidget);
    });

    testWidgets('Persists daily nutrition to SQLite on primary action tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MacronutrientsFoodLogScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      final saveButton = find.text('GUARDAR REGISTRO DIARIO (OFFLINE)');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump();

      // Spinner active
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance timer for simulated async save
      await tester.pump(const Duration(milliseconds: 700));

      // Saved state
      expect(find.text('¡REGISTRO CONFIRMADO EN SQLITE!'), findsOneWidget);
      expect(find.text('¡Registro diario guardado en base de datos local SQLite!'), findsOneWidget);
    });
  });
}
