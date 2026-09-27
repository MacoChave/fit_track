enum MacroNutrientType {
  protein,
  carbs,
  fats,
}

enum MealStatus {
  completed,
  pending,
  planned,
}

class FoodItem {
  final String name;
  final int macroAmountGrams;
  final MacroNutrientType type;
  final String macroLabel;

  const FoodItem({
    required this.name,
    required this.macroAmountGrams,
    required this.type,
    required this.macroLabel,
  });
}

class QuickAddOption {
  final String id;
  final String name;
  final String macroLabel;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final MacroNutrientType type;

  const QuickAddOption({
    required this.id,
    required this.name,
    required this.macroLabel,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.type,
  });
}

class MealLog {
  final String id;
  final String name;
  final String tag;
  String timeOrBadge;
  MealStatus status;
  int calories;
  int proteinGrams;
  int carbsGrams;
  int fatGrams;
  String macroSummaryText;
  List<FoodItem> items;
  List<QuickAddOption> quickAdds;
  String? suggestedItem;

  MealLog({
    required this.id,
    required this.name,
    required this.tag,
    required this.timeOrBadge,
    required this.status,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.macroSummaryText,
    required this.items,
    this.quickAdds = const [],
    this.suggestedItem,
  });
}

class NutritionDayData {
  final String dateLabel;
  final String phaseLabel;
  int currentCalories;
  final int targetCalories;
  int currentProtein;
  final int targetProtein;
  int currentCarbs;
  final int targetCarbs;
  int currentFat;
  final int targetFat;
  double waterLiters;
  final double targetWaterLiters;
  int waterGlasses;
  final int totalWaterGlasses;
  final List<MealLog> meals;
  final String aiAdviceTitle;
  final String aiAdviceText;

  NutritionDayData({
    required this.dateLabel,
    required this.phaseLabel,
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentCarbs,
    required this.targetCarbs,
    required this.currentFat,
    required this.targetFat,
    required this.waterLiters,
    required this.targetWaterLiters,
    required this.waterGlasses,
    required this.totalWaterGlasses,
    required this.meals,
    required this.aiAdviceTitle,
    required this.aiAdviceText,
  });

  int get remainingCalories => (targetCalories - currentCalories).clamp(0, 5000);

  double get calorieProgressPercent =>
      (currentCalories / targetCalories).clamp(0.0, 1.0);

  double get proteinProgressPercent =>
      (currentProtein / targetProtein).clamp(0.0, 1.0);

  double get carbsProgressPercent =>
      (currentCarbs / targetCarbs).clamp(0.0, 1.0);

  double get fatProgressPercent =>
      (currentFat / targetFat).clamp(0.0, 1.0);

  void addWater(double liters) {
    waterLiters = (waterLiters + liters).clamp(0.0, 10.0);
    waterGlasses = (waterLiters / 0.75).round().clamp(0, totalWaterGlasses);
  }

  void addQuickOptionToMeal(String mealId, QuickAddOption option) {
    final meal = meals.firstWhere((m) => m.id == mealId);
    meal.items.add(
      FoodItem(
        name: option.name,
        macroAmountGrams: option.proteinGrams > 0
            ? option.proteinGrams
            : (option.carbsGrams > 0 ? option.carbsGrams : option.fatGrams),
        type: option.type,
        macroLabel: option.macroLabel.replaceAll('(', '').replaceAll(')', ''),
      ),
    );

    meal.calories += option.calories;
    meal.proteinGrams += option.proteinGrams;
    meal.carbsGrams += option.carbsGrams;
    meal.fatGrams += option.fatGrams;
    meal.macroSummaryText =
        '${meal.calories} kcal · ${meal.proteinGrams}g P · ${meal.carbsGrams}g C · ${meal.fatGrams}g G';

    currentCalories += option.calories;
    currentProtein += option.proteinGrams;
    currentCarbs += option.carbsGrams;
    currentFat += option.fatGrams;
  }

  factory NutritionDayData.empty({required String dateLabel}) {
    return NutritionDayData(
      dateLabel: dateLabel,
      phaseLabel: 'PLAN PERSONALIZADO',
      currentCalories: 0,
      targetCalories: 2000,
      currentProtein: 0,
      targetProtein: 150,
      currentCarbs: 0,
      targetCarbs: 200,
      currentFat: 0,
      targetFat: 60,
      waterLiters: 0.0,
      targetWaterLiters: 3.0,
      waterGlasses: 0,
      totalWaterGlasses: 4,
      aiAdviceTitle: 'Base de datos limpia',
      aiAdviceText:
          'No se encontraron registros de nutrición en SQLite para este día. Registra tus comidas y agua para persistir.',
      meals: [
        MealLog(
          id: 'breakfast',
          name: 'Desayuno',
          tag: 'HABITUAL',
          timeOrBadge: 'PENDIENTE',
          status: MealStatus.pending,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: '0 kcal · 0g P · 0g C · 0g G',
          items: [],
        ),
        MealLog(
          id: 'lunch',
          name: 'Almuerzo',
          tag: 'POST-ENTRENO',
          timeOrBadge: 'PENDIENTE',
          status: MealStatus.pending,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: '0 kcal · 0g P · 0g C · 0g G',
          items: [],
        ),
        MealLog(
          id: 'snack',
          name: 'Snack de la Tarde',
          tag: 'ENERGÍA',
          timeOrBadge: 'PENDIENTE',
          status: MealStatus.pending,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: '0 kcal · 0g P · 0g C · 0g G',
          items: [],
        ),
        MealLog(
          id: 'dinner',
          name: 'Cena',
          tag: 'RECUPERACIÓN',
          timeOrBadge: 'PLANIFICADA',
          status: MealStatus.planned,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: '0 kcal · 0g P · 0g C · 0g G',
          items: [],
        ),
      ],
    );
  }

  static NutritionDayData getSampleDay() {
    return NutritionDayData(
      dateLabel: 'MARTES 22',
      phaseLabel: 'DÉFICIT MODERADO',
      currentCalories: 1420,
      targetCalories: 1900,
      currentProtein: 115,
      targetProtein: 145,
      currentCarbs: 140,
      targetCarbs: 190,
      currentFat: 44,
      targetFat: 60,
      waterLiters: 2.25,
      targetWaterLiters: 3.0,
      waterGlasses: 3,
      totalWaterGlasses: 4,
      aiAdviceTitle: 'Asistente Nutricional (Zero-Server)',
      aiAdviceText:
          'Para maximizar la síntesis post-sesión de empuje de hoy, te faltan 30g de proteína antes de dormir. Tu ventana de glucógeno está cubierta.',
      meals: [
        MealLog(
          id: 'breakfast',
          name: 'Desayuno',
          tag: '(Pre-Entreno)',
          timeOrBadge: '08:30 AM',
          status: MealStatus.completed,
          calories: 480,
          proteinGrams: 38,
          carbsGrams: 52,
          fatGrams: 12,
          macroSummaryText: '480 kcal · 38g P · 52g C · 12g G',
          items: [
            const FoodItem(
              name: 'Avena proteica c/ leche de almendras y whey',
              macroAmountGrams: 30,
              type: MacroNutrientType.protein,
              macroLabel: '30g P',
            ),
            const FoodItem(
              name: '1 plátano mediano maduro (110g)',
              macroAmountGrams: 26,
              type: MacroNutrientType.carbs,
              macroLabel: '26g C',
            ),
          ],
        ),
        MealLog(
          id: 'lunch',
          name: 'Almuerzo',
          tag: '(Post-Anabólico)',
          timeOrBadge: '01:45 PM',
          status: MealStatus.completed,
          calories: 580,
          proteinGrams: 48,
          carbsGrams: 60,
          fatGrams: 16,
          macroSummaryText: '580 kcal · 48g P · 60g C · 16g G',
          items: [
            const FoodItem(
              name: 'Pechuga de pollo a la plancha (200g)',
              macroAmountGrams: 44,
              type: MacroNutrientType.protein,
              macroLabel: '44g P',
            ),
            const FoodItem(
              name: 'Arroz integral cocido (180g)',
              macroAmountGrams: 45,
              type: MacroNutrientType.carbs,
              macroLabel: '45g C',
            ),
            const FoodItem(
              name: 'Espinacas salteadas c/ aceite de oliva (10g)',
              macroAmountGrams: 10,
              type: MacroNutrientType.fats,
              macroLabel: '10g G',
            ),
          ],
        ),
        MealLog(
          id: 'snack',
          name: 'Snack de la Tarde',
          tag: 'Pendiente',
          timeOrBadge: 'more_time',
          status: MealStatus.pending,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: 'Meta sugerida: 250 kcal · 20g P · 18g C · 8g G',
          items: [],
          quickAdds: [
            const QuickAddOption(
              id: 'yogurt',
              name: 'Yogur Griego 0%',
              macroLabel: '(15g P)',
              calories: 90,
              proteinGrams: 15,
              carbsGrams: 4,
              fatGrams: 0,
              type: MacroNutrientType.protein,
            ),
            const QuickAddOption(
              id: 'shake',
              name: 'Batido Isolatado',
              macroLabel: '(25g P)',
              calories: 120,
              proteinGrams: 25,
              carbsGrams: 2,
              fatGrams: 1,
              type: MacroNutrientType.protein,
            ),
            const QuickAddOption(
              id: 'almonds',
              name: 'Puñado Almendras',
              macroLabel: '(6g G)',
              calories: 80,
              proteinGrams: 3,
              carbsGrams: 3,
              fatGrams: 6,
              type: MacroNutrientType.fats,
            ),
          ],
        ),
        MealLog(
          id: 'dinner',
          name: 'Cena',
          tag: 'Planificación',
          timeOrBadge: 'IA SYNC',
          status: MealStatus.planned,
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          macroSummaryText: 'Cupo restante sugerido: 360 kcal · 29g P · 10g C · 8g G',
          items: [],
          suggestedItem: 'Tortilla claras con verduras + lomo de salmón / atún',
        ),
      ],
    );
  }
}
