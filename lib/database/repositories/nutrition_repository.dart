import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/nutrition_models.dart';
import '../database_helper.dart';

/// Repositorio de SQLite para persistir el balance de macronutrientes, hidratación y comidas (RF-NUT-01).
class NutritionRepository {
  final DatabaseHelper _dbHelper;

  NutritionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Guarda o actualiza el registro diario de nutrición
  Future<void> saveDailyNutrition(NutritionDayData data) async {
    final db = await _dbHelper.database;
    final id = 'nutrition_${data.dateLabel.replaceAll(' ', '_')}';

    final mealsJson = json.encode(
      data.meals.map((m) {
        return {
          'id': m.id,
          'name': m.name,
          'tag': m.tag,
          'timeOrBadge': m.timeOrBadge,
          'status': m.status.name,
          'calories': m.calories,
          'proteinGrams': m.proteinGrams,
          'carbsGrams': m.carbsGrams,
          'fatGrams': m.fatGrams,
          'macroSummaryText': m.macroSummaryText,
          'suggestedItem': m.suggestedItem,
          'items': m.items.map((it) {
            return {
              'name': it.name,
              'macroAmountGrams': it.macroAmountGrams,
              'type': it.type.name,
              'macroLabel': it.macroLabel,
            };
          }).toList(),
        };
      }).toList(),
    );

    await db.insert(
      'daily_nutrition_logs',
      {
        'id': id,
        'date_label': data.dateLabel,
        'phase_label': data.phaseLabel,
        'current_calories': data.currentCalories,
        'target_calories': data.targetCalories,
        'current_protein': data.currentProtein,
        'target_protein': data.targetProtein,
        'current_carbs': data.currentCarbs,
        'target_carbs': data.targetCarbs,
        'current_fat': data.currentFat,
        'target_fat': data.targetFat,
        'water_liters': data.waterLiters,
        'target_water_liters': data.targetWaterLiters,
        'water_glasses': data.waterGlasses,
        'total_water_glasses': data.totalWaterGlasses,
        'ai_advice_title': data.aiAdviceTitle,
        'ai_advice_text': data.aiAdviceText,
        'meals_json': mealsJson,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Recupera el registro nutricional guardado para una etiqueta de fecha (ej. 'MARTES 22')
  Future<NutritionDayData?> getDailyNutrition(String dateLabel) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'daily_nutrition_logs',
      where: 'date_label = ?',
      whereArgs: [dateLabel],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final row = results.first;
    final mealsList = <MealLog>[];

    try {
      final decodedMeals = json.decode(row['meals_json'] as String) as List<dynamic>;
      for (final m in decodedMeals) {
        final mMap = m as Map<String, dynamic>;
        final items = <FoodItem>[];
        if (mMap['items'] != null) {
          for (final it in mMap['items'] as List<dynamic>) {
            final itMap = it as Map<String, dynamic>;
            items.add(
              FoodItem(
                name: itMap['name'] as String,
                macroAmountGrams: (itMap['macroAmountGrams'] as num).toInt(),
                type: MacroNutrientType.values.firstWhere(
                  (t) => t.name == itMap['type'],
                  orElse: () => MacroNutrientType.protein,
                ),
                macroLabel: itMap['macroLabel'] as String,
              ),
            );
          }
        }

        mealsList.add(
          MealLog(
            id: mMap['id'] as String,
            name: mMap['name'] as String,
            tag: mMap['tag'] as String,
            timeOrBadge: mMap['timeOrBadge'] as String,
            status: MealStatus.values.firstWhere(
              (s) => s.name == mMap['status'],
              orElse: () => MealStatus.pending,
            ),
            calories: (mMap['calories'] as num).toInt(),
            proteinGrams: (mMap['proteinGrams'] as num).toInt(),
            carbsGrams: (mMap['carbsGrams'] as num).toInt(),
            fatGrams: (mMap['fatGrams'] as num).toInt(),
            macroSummaryText: mMap['macroSummaryText'] as String,
            suggestedItem: mMap['suggestedItem'] as String?,
            items: items,
          ),
        );
      }
    } catch (_) {}

    return NutritionDayData(
      dateLabel: row['date_label'] as String,
      phaseLabel: row['phase_label'] as String,
      currentCalories: (row['current_calories'] as num).toInt(),
      targetCalories: (row['target_calories'] as num).toInt(),
      currentProtein: (row['current_protein'] as num).toInt(),
      targetProtein: (row['target_protein'] as num).toInt(),
      currentCarbs: (row['current_carbs'] as num).toInt(),
      targetCarbs: (row['target_carbs'] as num).toInt(),
      currentFat: (row['current_fat'] as num).toInt(),
      targetFat: (row['target_fat'] as num).toInt(),
      waterLiters: (row['water_liters'] as num).toDouble(),
      targetWaterLiters: (row['target_water_liters'] as num).toDouble(),
      waterGlasses: (row['water_glasses'] as num).toInt(),
      totalWaterGlasses: (row['total_water_glasses'] as num).toInt(),
      aiAdviceTitle: row['ai_advice_title'] as String? ?? 'Asistente Nutricional',
      aiAdviceText: row['ai_advice_text'] as String? ?? '',
      meals: mealsList,
    );
  }
}
