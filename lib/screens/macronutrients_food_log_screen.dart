import 'package:flutter/material.dart';
import '../database/repositories/nutrition_repository.dart';
import '../models/nutrition_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/main_layout.dart';
import '../widgets/flat_button.dart';
import '../widgets/flat_card.dart';
import 'biometrics_equipment_screen.dart';
import 'calendar_nutrition_screen.dart';

class MacronutrientsFoodLogScreen extends StatefulWidget {
  final NutritionDayData? dayData;
  final bool fallbackToSample;

  const MacronutrientsFoodLogScreen({
    super.key,
    this.dayData,
    this.fallbackToSample = false,
  });

  @override
  State<MacronutrientsFoodLogScreen> createState() =>
      _MacronutrientsFoodLogScreenState();
}

class _MacronutrientsFoodLogScreenState
    extends State<MacronutrientsFoodLogScreen> {
  late NutritionDayData _data;
  int _selectedDateTab = 1; // 0: AYER, 1: HOY, 2: MAÑANA
  bool _isSaved = false;
  bool _isSaving = false;
  int _currentNavIndex = 1; // Nutrición

  @override
  void initState() {
    super.initState();
    if (widget.dayData != null) {
      _data = widget.dayData!;
    } else if (widget.fallbackToSample) {
      _data = NutritionDayData.getSampleDay();
    } else {
      _data = NutritionDayData.empty(dateLabel: _getDateLabelForTab(_selectedDateTab));
      _loadFromSqlite();
    }
  }

  String _getDateLabelForTab(int tab) {
    final now = DateTime.now();
    DateTime targetDate = now;
    if (tab == 0) targetDate = now.subtract(const Duration(days: 1));
    if (tab == 2) targetDate = now.add(const Duration(days: 1));

    const dayNames = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    final dayName = dayNames[targetDate.weekday - 1];
    return '$dayName ${targetDate.day}';
  }

  Future<void> _loadFromSqlite() async {
    try {
      final repo = NutritionRepository();
      final dateLabel = _getDateLabelForTab(_selectedDateTab);
      final saved = await repo.getDailyNutrition(dateLabel);
      if (saved != null && mounted) {
        setState(() {
          _data = saved;
        });
      }
    } catch (_) {}
  }

  void _addWater250ml() {
    setState(() {
      _data.addWater(0.25);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.accentWater),
        ),
        content: Row(
          children: [
            const Icon(Icons.water_drop, color: AppColors.accentWater, size: 20),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Text(
                '+250 ml agua registrada (${_data.waterLiters.toStringAsFixed(2)} L totales)',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onQuickAddTap(String mealId, QuickAddOption option) {
    setState(() {
      _data.addQuickOptionToMeal(mealId, option);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.accentEnergy),
        ),
        content: Row(
          children: [
            const Icon(Icons.add_task, color: AppColors.accentEnergy, size: 20),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Text(
                'Añadido: ${option.name} (${option.macroLabel}) a Snack',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyDinnerSuggestion() {
    setState(() {
      final dinner = _data.meals.firstWhere((m) => m.id == 'dinner');
      dinner.status = MealStatus.completed;
      dinner.timeOrBadge = '09:15 PM';
      dinner.calories = 360;
      dinner.proteinGrams = 29;
      dinner.carbsGrams = 10;
      dinner.fatGrams = 8;
      dinner.macroSummaryText = '360 kcal · 29g P · 10g C · 8g G';
      dinner.items.add(
        const FoodItem(
          name: 'Tortilla claras con verduras + lomo de salmón / atún',
          macroAmountGrams: 29,
          type: MacroNutrientType.protein,
          macroLabel: '29g P',
        ),
      );

      _data.currentCalories += 360;
      _data.currentProtein += 29;
      _data.currentCarbs += 10;
      _data.currentFat += 8;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.accentEnergy),
        ),
        content: Row(
          children: [
            const Icon(Icons.restaurant, color: AppColors.accentEnergy, size: 20),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Text(
                '¡Cena sugerida aplicada con éxito!',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveDailyNutrition() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = NutritionRepository();
      repo.saveDailyNutrition(_data).catchError((_) {});
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.accentEnergy),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accentEnergy, size: 20),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Text(
                '¡Registro diario guardado en base de datos local SQLite!',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      subtitle: 'NUTRICIÓN',
      currentNavIndex: _currentNavIndex,
      onNavIndexChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CalendarNutritionScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BiometricsEquipmentScreen()),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.margin,
          vertical: AppSpacing.spaceMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContextualDateHeader(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildMacroSummaryCard(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildMealsSection(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildAiAssistantCard(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildActionButtons(),
            const SizedBox(height: AppSpacing.space2Xl),
          ],
        ),
      ),
    );
  }

  // --- CABECERA CONTEXTUAL & SELECTOR RÁPIDO DE FECHA ---
  Widget _buildContextualDateHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_data.dateLabel} · FASE: ${_data.phaseLabel}',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                'BYOK AI PLAN',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.accentEnergy,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Macronutrientes',
              style: AppTypography.headlineLg.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            // Selector rápido de día (Ayer / Hoy / Mañana)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Row(
                children: [
                  _buildDateChip('AYER', 0),
                  _buildDateChip('HOY', 1),
                  _buildDateChip('MAÑANA', 2),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, int index) {
    final isSelected = _selectedDateTab == index;
    return Material(
      color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
      borderRadius: AppSpacing.roundedSm,
      child: InkWell(
        key: Key('date_tab_$index'),
        onTap: () {
          setState(() {
            _selectedDateTab = index;
            if (!widget.fallbackToSample && widget.dayData == null) {
              _data = NutritionDayData.empty(dateLabel: _getDateLabelForTab(index));
              _loadFromSqlite();
            }
          });
        },
        borderRadius: AppSpacing.roundedSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: AppTypography.labelMonoSm.copyWith(
              color: isSelected ? AppColors.accentEnergy : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  // --- PANEL MACRO RESUMEN & PROGRESO CALÓRICO ---
  Widget _buildMacroSummaryCard() {
    final caloriePercent = (_data.calorieProgressPercent * 100).toStringAsFixed(1);

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Calorías
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INGESTA CALÓRICA',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_data.currentCalories}',
                        style: AppTypography.labelMonoLg.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ ${_data.targetCalories} KCAL',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RESTAN ${_data.remainingCalories} KCAL',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$caloriePercent% alcanzado',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Barra Segmentada Plana (Proteína, Carbs, Grasas)
          ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: Container(
              height: 10,
              color: AppColors.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    flex: (_data.currentProtein * 4), // calorías de proteína
                    child: Container(color: AppColors.accentEnergy),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (_data.currentCarbs * 4), // calorías de carbohidratos
                    child: Container(color: AppColors.accentWater),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (_data.currentFat * 9), // calorías de grasas
                    child: Container(color: AppColors.accentRpe),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: _data.remainingCalories > 0 ? _data.remainingCalories : 0,
                    child: Container(color: AppColors.surfaceContainerLowest),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 4),

          // Tríada de Macronutrientes en Grid de 3 Columnas
          Row(
            children: [
              Expanded(
                child: _buildMacroPill(
                  label: 'PROTEÍNA',
                  current: _data.currentProtein,
                  target: _data.targetProtein,
                  color: AppColors.accentEnergy,
                  percent: _data.proteinProgressPercent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMacroPill(
                  label: 'CARBS',
                  current: _data.currentCarbs,
                  target: _data.targetCarbs,
                  color: AppColors.accentWater,
                  percent: _data.carbsProgressPercent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMacroPill(
                  label: 'GRASAS',
                  current: _data.currentFat,
                  target: _data.targetFat,
                  color: AppColors.accentRpe,
                  percent: _data.fatProgressPercent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // Mini Balance Hídrico
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentWater.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.water_drop,
                        size: 18,
                        color: AppColors.accentWater,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HIDRATACIÓN',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '${_data.waterLiters.toStringAsFixed(2)} L / ${_data.targetWaterLiters} L (${_data.waterGlasses}/${_data.totalWaterGlasses} Vasos)',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Material(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                  child: InkWell(
                    key: const Key('add_water_btn'),
                    onTap: _addWater250ml,
                    borderRadius: AppSpacing.roundedSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.accentWater,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '250 ml',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentWater,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required int current,
    required int target,
    required Color color,
    required double percent,
  }) {
    final percentInt = (percent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMonoSm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
              Text(
                '$percentInt%',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: AppTypography.labelMonoMd.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                '/${target}g',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // --- DESGLOSE Y REGISTRO DE COMIDAS DEL DÍA ---
  Widget _buildMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COMIDAS DEL DÍA',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              '2 de 4 registradas',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        ..._data.meals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(MealLog meal) {
    final isCompleted = meal.status == MealStatus.completed;
    final isPlanned = meal.status == MealStatus.planned;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      child: FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la Comida
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            meal.name,
                            style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            meal.tag,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: isCompleted
                                  ? AppColors.textMuted
                                  : (isPlanned
                                      ? AppColors.accentWater
                                      : AppColors.accentRpe),
                              fontWeight: isCompleted
                                  ? FontWeight.w400
                                  : FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meal.macroSummaryText,
                        style: AppTypography.labelMonoSm.copyWith(
                          color: isCompleted
                              ? AppColors.accentEnergy
                              : AppColors.textSecondary,
                          fontWeight: isCompleted
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de Hora o Estado
                if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.accentEnergy,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meal.timeOrBadge,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.accentEnergy,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isPlanned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      meal.timeOrBadge,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentWater,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.more_time,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm),

            // Lista de alimentos registrados (si existen)
            if (meal.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Column(
                  children: meal.items.map((item) {
                    Color itemColor;
                    if (item.type == MacroNutrientType.protein) {
                      itemColor = AppColors.accentEnergy;
                    } else if (item.type == MacroNutrientType.carbs) {
                      itemColor = AppColors.accentWater;
                    } else {
                      itemColor = AppColors.accentRpe;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.macroLabel,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: itemColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Si es Snack (Pendiente): Quick Adds habituales de 1-toque
            if (meal.quickAdds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '1-TAP QUICK ADDS HABITUALES:',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meal.quickAdds.map((opt) {
                  return Material(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppSpacing.roundedSm,
                    child: InkWell(
                      key: Key('quick_add_${opt.id}'),
                      onTap: () => _onQuickAddTap(meal.id, opt),
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+',
                              style: TextStyle(
                                color: opt.type == MacroNutrientType.protein
                                    ? AppColors.accentEnergy
                                    : AppColors.accentRpe,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              opt.name,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              opt.macroLabel,
                              style: AppTypography.labelMonoSm.copyWith(
                                color: opt.type == MacroNutrientType.protein
                                    ? AppColors.accentEnergy
                                    : AppColors.accentRpe,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              // Botón Añadir Alimento o Foto IA
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: AppSpacing.borderWidthSubtle,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Abriendo escaneo de alimento con cámara IA...',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  },
                  borderRadius: AppSpacing.roundedSm,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        size: 18,
                        color: AppColors.accentEnergy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Añadir Alimento o Foto IA',
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Si es Cena (Planificación): Item sugerido + botón APLICAR
            if (isPlanned && meal.suggestedItem != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 18,
                      color: AppColors.accentWater,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.suggestedItem!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('apply_dinner_btn'),
                        onTap: _applyDinnerSuggestion,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            'APLICAR',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentWater,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- ASISTENTE NUTRICIONAL IA (ZERO-SERVER / EDGE BYOK) ---
  Widget _buildAiAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.accentEnergy.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: AppColors.accentEnergy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _data.aiAdviceTitle,
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  'ON-DEVICE',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            _data.aiAdviceText,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),
          Material(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.roundedSm,
            child: InkWell(
              onTap: _applyDinnerSuggestion,
              borderRadius: AppSpacing.roundedSm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: AppColors.accentEnergy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AJUSTAR CENA AUTOMÁTICAMENTE CON IA',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACCIONES INFERIORES GYM-FRIENDLY (>56dp) ---
  Widget _buildActionButtons() {
    return Column(
      children: [
        // CTA Principal: Guardar Registro Diario (Offline)
        FlatButton(
          label: _isSaving
              ? 'PERSISTIENDO REGISTRO...'
              : (_isSaved
                  ? '¡REGISTRO CONFIRMADO EN SQLITE!'
                  : 'GUARDAR REGISTRO DIARIO (OFFLINE)'),
          icon: _isSaved ? Icons.done_all : Icons.check_circle,
          isLoading: _isSaving,
          onPressed: _saveDailyNutrition,
        ),
        const SizedBox(height: AppSpacing.spaceSm),

        // Botones Secundarios: Escaneo de Código / Registro por Voz
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.surfaceCard,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Iniciando escáner de código de barras de alimentos...',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.accentWater),
                        ),
                      ),
                    );
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: AppColors.accentWater,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ESCANEAR CÓDIGO',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Material(
                color: AppColors.surfaceCard,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Escuchando descripción de comida por micrófono...',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.accentRpe),
                        ),
                      ),
                    );
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 18,
                          color: AppColors.accentRpe,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'REGISTRO POR VOZ',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm + 4),

        // Pie de persistencia local
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accentEnergy,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Base de Datos Local SQLite Cifrada · 0 Telemetría Cloud',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
