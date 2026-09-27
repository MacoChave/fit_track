import 'package:flutter/material.dart';

import '../database/repositories/ai_routine_repository.dart';
import '../database/repositories/nutrition_repository.dart';
import '../models/calendar_models.dart';
import '../models/nutrition_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/main_layout.dart';
import '../widgets/flat_button.dart';
import '../widgets/flat_card.dart';
import '../services/manual_routine_importer.dart';
import 'biometrics_equipment_screen.dart';
import 'macronutrients_food_log_screen.dart';
import 'workout_logging_screen.dart';

class CalendarNutritionScreen extends StatefulWidget {
  final List<DaySchedule>? initialSchedule;

  const CalendarNutritionScreen({super.key, this.initialSchedule});

  @override
  State<CalendarNutritionScreen> createState() =>
      _CalendarNutritionScreenState();
}

class _CalendarNutritionScreenState extends State<CalendarNutritionScreen> {
  List<DaySchedule> _weekDays = [];
  bool _isLoading = true;
  Map<String, dynamic>? _activePlan;
  int _selectedDayIndex = 0;
  int _currentNavIndex = 0; // Calendario activo

  // Estado reactivo de nutrición para el día actual
  int _extraProtein = 0;
  bool _extraWaterAdded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSchedule != null) {
      _weekDays = widget.initialSchedule!;
      _isLoading = false;
      if (_weekDays.isNotEmpty) {
        final todayIdx = _weekDays.indexWhere(
          (d) => d.statusType == DayStatusType.today,
        );
        _selectedDayIndex = todayIdx != -1 ? todayIdx : 0;
      } else {
        _selectedDayIndex = 0;
      }
    } else {
      _loadRoutineFromSqlite();
    }
  }

  Future<void> _loadRoutineFromSqlite() async {
    try {
      final repo = AiRoutineRepository();
      final schedules = await repo.getWeekSchedule();
      final activePlan = await repo.getActivePlan();
      if (mounted) {
        setState(() {
          _weekDays = schedules;
          _activePlan = activePlan;
          _isLoading = false;
          if (_weekDays.isNotEmpty) {
            final todayIdx = _weekDays.indexWhere(
              (d) => d.statusType == DayStatusType.today,
            );
            _selectedDayIndex = todayIdx != -1 ? todayIdx : 0;
          } else {
            _selectedDayIndex = 0;
          }
        });
        if (_weekDays.isNotEmpty) {
          await _loadNutritionForCurrentDay();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNutritionForCurrentDay() async {
    if (_currentDay == null) return;
    try {
      final repo = NutritionRepository();
      final dateLabel =
          '${_getDayName(_currentDay!.dayLetter)} ${_currentDay!.dayNumber}'
              .toUpperCase();
      final data = await repo.getDailyNutrition(dateLabel);
      if (data != null && mounted) {
        setState(() {
          _currentDay!.loggedCalories = data.currentCalories;
          _currentDay!.loggedProteinGrams = data.currentProtein;
          _currentDay!.loggedWaterLiters = data.waterLiters;
          _extraWaterAdded = data.waterLiters >= 3.0;

          // Sincronizar estado de las comidas
          for (final savedMeal in data.meals) {
            for (final dayMeal in _currentDay!.meals) {
              if (dayMeal.id == savedMeal.id ||
                  dayMeal.name == savedMeal.name) {
                dayMeal.isCompleted =
                    (savedMeal.status == MealStatus.completed);
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _persistNutritionToSqlite() async {
    if (_currentDay == null) return;
    try {
      final repo = NutritionRepository();
      final dateLabel =
          '${_getDayName(_currentDay!.dayLetter)} ${_currentDay!.dayNumber}'
              .toUpperCase();

      final mealLogs = _currentDay!.meals.map((m) {
        return MealLog(
          id: m.id,
          name: m.name,
          tag: 'DIARIO',
          timeOrBadge: m.isCompleted ? 'COMPLETADA' : 'PENDIENTE',
          status: m.isCompleted ? MealStatus.completed : MealStatus.pending,
          calories: m.calories,
          proteinGrams: m.proteinGrams,
          carbsGrams: (m.calories * 0.45 / 4).round(),
          fatGrams: (m.calories * 0.25 / 9).round(),
          macroSummaryText: '${m.calories} kcal · ${m.proteinGrams}g P',
          items: [
            FoodItem(
              name: m.description,
              macroAmountGrams: m.proteinGrams,
              type: MacroNutrientType.protein,
              macroLabel: '${m.proteinGrams}g P',
            ),
          ],
        );
      }).toList();

      final data = NutritionDayData(
        dateLabel: dateLabel,
        phaseLabel: 'DÉFICIT MODERADO',
        currentCalories: _currentDay!.loggedCalories,
        targetCalories: _currentDay!.targetCalories,
        currentProtein: _currentDay!.loggedProteinGrams,
        targetProtein: _currentDay!.targetProteinGrams,
        currentCarbs: (_currentDay!.loggedCalories * 0.45 / 4).round(),
        targetCarbs: (_currentDay!.targetCalories * 0.45 / 4).round(),
        currentFat: (_currentDay!.loggedCalories * 0.25 / 9).round(),
        targetFat: (_currentDay!.targetCalories * 0.25 / 9).round(),
        waterLiters: _currentDay!.loggedWaterLiters,
        targetWaterLiters: _currentDay!.targetWaterLiters,
        waterGlasses: (_currentDay!.loggedWaterLiters / 0.75).round(),
        totalWaterGlasses: 4,
        meals: mealLogs,
        aiAdviceTitle: 'Ajuste Dinámico',
        aiAdviceText:
            'Nutrición sincronizada con el plan activo de entrenamiento.',
      );

      await repo.saveDailyNutrition(data);
    } catch (_) {}
  }

  DaySchedule? get _currentDay =>
      (_weekDays.isNotEmpty && _selectedDayIndex < _weekDays.length)
      ? _weekDays[_selectedDayIndex]
      : null;

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
      _extraProtein = 0;
    });
    _loadNutritionForCurrentDay();
  }

  void _toggleMeal(int mealIndex) {
    if (_currentDay == null) return;
    setState(() {
      final meal = _currentDay!.meals[mealIndex];
      meal.isCompleted = !meal.isCompleted;
      if (meal.isCompleted) {
        _currentDay!.loggedCalories += meal.calories;
      } else {
        _currentDay!.loggedCalories =
            (_currentDay!.loggedCalories - meal.calories).clamp(0, 5000);
      }
    });
    _persistNutritionToSqlite();
  }

  void _toggleExtraProtein() {
    if (_currentDay == null) return;
    setState(() {
      if (_extraProtein == 0) {
        _extraProtein = 25;
        _currentDay!.loggedProteinGrams += 25;
        _currentDay!.loggedCalories += 100;
      } else {
        _currentDay!.loggedProteinGrams =
            (_currentDay!.loggedProteinGrams - _extraProtein).clamp(0, 300);
        _currentDay!.loggedCalories = (_currentDay!.loggedCalories - 100).clamp(
          0,
          5000,
        );
        _extraProtein = 0;
      }
    });
    _persistNutritionToSqlite();
  }

  void _toggleExtraWater() {
    if (_currentDay == null) return;
    setState(() {
      _extraWaterAdded = !_extraWaterAdded;
      if (_extraWaterAdded) {
        _currentDay!.loggedWaterLiters = 3.0;
      } else {
        _currentDay!.loggedWaterLiters = 2.25;
      }
    });
    _persistNutritionToSqlite();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      subtitle: 'CALENDARIO',
      currentNavIndex: _currentNavIndex,
      onNavIndexChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 1) {
          // Navegar a Nutrición / Macronutrientes y Registro de Comidas
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MacronutrientsFoodLogScreen(),
            ),
          );
        } else if (index == 2) {
          // Navegar a Ajustes / Perfil Biométrico
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BiometricsEquipmentScreen(),
            ),
          );
        }
      },
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.space2Xl),
                child: CircularProgressIndicator(color: AppColors.accentEnergy),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2Xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWeekHeaderAndSelector(),
                  const SizedBox(height: AppSpacing.spaceMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.margin,
                    ),
                    child: _weekDays.isEmpty
                        ? _buildCleanDatabaseEmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeroSessionCard(),
                              const SizedBox(height: AppSpacing.spaceLg),
                              _buildRoutineStructureSection(),
                              const SizedBox(height: AppSpacing.spaceLg),
                              _buildDailyNutritionSection(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCleanDatabaseEmptyState() {
    return FlatCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.spaceLg,
          horizontal: AppSpacing.spaceMd,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 52,
              color: AppColors.accentEnergy,
            ),
            const SizedBox(height: AppSpacing.spaceMd),
            Text(
              'BASE DE DATOS LIMPIA',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            Text(
              'No se encontraron rutinas ni días de entrenamiento en SQLite.\n\nGenera una rutina personalizada con IA o importa tu archivo JSON para activar tu calendario semanal.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            FlatButton(
              label: 'Generar / Importar Rutina con IA',
              icon: Icons.auto_awesome,
              onPressed: () {
                ManualRoutineImporter.instance.showImportDialog(
                  context,
                  onImportSuccess: () => _loadRoutineFromSqlite(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.spaceSm),
            TextButton.icon(
              icon: const Icon(
                Icons.settings,
                size: 16,
                color: AppColors.textSecondary,
              ),
              label: Text(
                'Ir a Ajustes / Perfil Biométrico',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BiometricsEquipmentScreen(),
                  ),
                ).then((_) => _loadRoutineFromSqlite());
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CABECERA DE ESTADO Y SELECTOR SEMANAL ---
  Widget _buildWeekHeaderAndSelector() {
    final String planTitle;
    final String planBadge;
    final String localStatusBadge;
    if (_activePlan != null && _activePlan!['primary_goal'] != null) {
      planBadge = 'Plan Activo · BYOK AI';
      planTitle =
          'SEMANA 1 · ${(_activePlan!['primary_goal'] as String).toUpperCase()}';
      localStatusBadge = 'Local-First';
    } else if (_weekDays.isNotEmpty) {
      planBadge = 'Plan Activo · BYOK AI';
      planTitle = 'SEMANA 1 · FASE DÉFICIT Y FUERZA';
      localStatusBadge = 'Local-First';
    } else {
      planBadge = 'Base de Datos SQLite';
      planTitle = 'SIN PLAN DE ENTRENAMIENTO';
      localStatusBadge = 'Base Limpia';
    }

    return Container(
      color: AppColors.surfaceDim,
      padding: const EdgeInsets.only(
        left: AppSpacing.margin,
        right: AppSpacing.margin,
        top: AppSpacing.spaceMd,
        bottom: AppSpacing.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planBadge,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      planTitle,
                      style: AppTypography.headlineLg.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _weekDays.isNotEmpty
                            ? AppColors.accentEnergy
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      localStatusBadge,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_weekDays.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spaceSm + 2),
            Row(
              children: List.generate(_weekDays.length, (index) {
                final day = _weekDays[index];
                final isSelected = index == _selectedDayIndex;

                Color bgColor;

                if (isSelected) {
                  bgColor = AppColors.accentEnergy;
                } else {
                  bgColor = AppColors.surfaceCard;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Material(
                      color: bgColor,
                      borderRadius: AppSpacing.roundedSm,
                      child: InkWell(
                        onTap: () {
                          _onDaySelected(index);
                        },
                        borderRadius: AppSpacing.roundedSm,
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day.dayLetter,
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelected
                                      ? AppColors.surfaceBase
                                      : (day.statusType ==
                                                DayStatusType.activeRest
                                            ? AppColors.accentWater
                                            : (day.statusType ==
                                                      DayStatusType.recovery
                                                  ? AppColors.textMuted
                                                  : AppColors.textSecondary)),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              // Text(
                              //   '${day.dayNumber}',
                              //   style: AppTypography.headlineSm.copyWith(
                              //     color: fgColor,
                              //     fontWeight: isSelected
                              //         ? FontWeight.w900
                              //         : FontWeight.w700,
                              //     fontSize: 15,
                              //   ),
                              // ),
                              _buildDayStatusIndicator(day, isSelected),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayStatusIndicator(DaySchedule day, bool isSelected) {
    if (day.statusType == DayStatusType.today) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceBase : AppColors.accentEnergy,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          'HOY',
          style: AppTypography.labelMonoSm.copyWith(
            color: isSelected ? AppColors.accentEnergy : AppColors.surfaceBase,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      );
    } else if (day.statusType == DayStatusType.completed) {
      return const Icon(
        Icons.check_circle,
        size: 14,
        color: AppColors.accentEnergy,
      );
    } else if (day.statusType == DayStatusType.activeRest) {
      return const Icon(
        Icons.directions_walk,
        size: 14,
        color: AppColors.accentWater,
      );
    } else if (day.statusType == DayStatusType.recovery) {
      return const Icon(Icons.hotel, size: 14, color: AppColors.textMuted);
    } else {
      return Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: AppColors.borderStrong,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  // --- TARJETA HERO DEL DÍA (MARTES / SESIÓN SELECCIONADA) ---
  Widget _buildHeroSessionCard() {
    final day = _currentDay;
    if (day == null) return const SizedBox.shrink();

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            day.sessionNumberLabel.toUpperCase(),
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentEnergy,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spaceSm),
                        Text(
                          '${_getDayName(day.dayLetter)} ${day.dayNumber}'
                              .toUpperCase(),
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (day.statusType == DayStatusType.completed) ...[
                          const SizedBox(width: AppSpacing.spaceSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentEnergy.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: AppSpacing.roundedSm,
                              border: Border.all(
                                color: AppColors.accentEnergy,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: AppColors.accentEnergy,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'COMPLETADA',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.accentEnergy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.sessionTitle,
                      style: AppTypography.headlineLg.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: const Icon(
                  Icons.sports_gymnastics,
                  size: 26,
                  color: AppColors.accentEnergy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Métricas Rápidas en Cuadrícula 2x2
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildMetricTile(
                        icon: Icons.timer,
                        iconColor: AppColors.accentEnergy,
                        label: 'DURACIÓN',
                        value: '${day.durationMinutes} min',
                      ),
                      const SizedBox(height: 6),
                      _buildMetricTile(
                        icon: Icons.fitness_center,
                        iconColor: AppColors.accentWater,
                        label: 'EQUIPO',
                        value: day.equipmentSummary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      _buildMetricTile(
                        icon: Icons.layers,
                        iconColor: AppColors.accentEnergy,
                        label: 'ESTRUCTURA',
                        value: '${day.blockCount} Bloques',
                      ),
                      const SizedBox(height: 6),
                      _buildMetricTile(
                        icon: Icons.speed,
                        iconColor: AppColors.accentRpe,
                        label: 'ESFUERZO',
                        value: 'RPE ${day.rpe}/10',
                        valueColor: AppColors.accentRpe,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Botón Iniciar Sesión (RNF-04: >56dp)
          FlatButton(
            label: day.statusType == DayStatusType.completed
                ? 'Sesión Completada · Repetir (${day.durationMinutes}m)'
                : 'Iniciar Sesión (${day.durationMinutes}m)',
            icon: day.statusType == DayStatusType.completed
                ? Icons.check_circle
                : Icons.play_arrow,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WorkoutLoggingScreen(daySchedule: _currentDay),
                ),
              );
              _loadRoutineFromSqlite();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.labelMonoMd.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ESTRUCTURA DE LA RUTINA (DERCAS RF-CAL-01) ---
  Widget _buildRoutineStructureSection() {
    final day = _currentDay;
    if (day == null) return const SizedBox.shrink();
    final blocks = day.blocks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ESTRUCTURA DE LA RUTINA',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm + 2),

        if (blocks.isEmpty)
          FlatCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                child: Text(
                  'Día de descanso activo o sin bloques programados.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ...blocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
              child: _buildBlockCard(block),
            ),
          ),
      ],
    );
  }

  Widget _buildBlockCard(ExerciseBlock block) {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del Bloque
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: block.indicatorColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    block.title.toUpperCase(),
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '${block.durationMinutes} MIN',
                style: AppTypography.labelMonoSm.copyWith(
                  color: block.indicatorColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // Lista de ejercicios del bloque
          ...block.exercises.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Material(
                color: AppColors.surfaceDim,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutLoggingScreen(
                          daySchedule: _currentDay,
                          initialExercise: exercise,
                        ),
                      ),
                    );
                    _loadRoutineFromSqlite();
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (exercise.order.isNotEmpty) ...[
                              Text(
                                exercise.order,
                                style: AppTypography.labelMonoMd.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.spaceSm),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.name,
                                          style: AppTypography.headlineSm
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.5,
                                              ),
                                        ),
                                      ),
                                      if (exercise.isCompleted) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentEnergy
                                                .withValues(alpha: 0.18),
                                            borderRadius: AppSpacing.roundedSm,
                                            border: Border.all(
                                              color: AppColors.accentEnergy,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check,
                                                size: 10,
                                                color: AppColors.accentEnergy,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'COMPLETADO',
                                                style: AppTypography.labelMonoSm
                                                    .copyWith(
                                                      color: AppColors
                                                          .accentEnergy,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    exercise.description,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  if (exercise.seriesAndReps != null) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildBadge(
                                          exercise.seriesAndReps!,
                                          AppColors.textPrimary,
                                          AppColors.surfaceElevated,
                                        ),
                                        if (exercise.restSeconds != null)
                                          _buildBadge(
                                            '${exercise.restSeconds}s Descanso',
                                            AppColors.accentRest,
                                            AppColors.surfaceElevated,
                                          ),
                                        if (exercise.weightKg != null)
                                          _buildBadge(
                                            '${exercise.weightKg!.toStringAsFixed(0)} kg',
                                            AppColors.accentEnergy,
                                            AppColors.surfaceElevated,
                                          ),
                                        if (exercise.isBodyweight)
                                          _buildBadge(
                                            'Peso Corporal',
                                            AppColors.textSecondary,
                                            AppColors.surfaceElevated,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (exercise.durationOrReps != null) ...[
                              const SizedBox(width: AppSpacing.spaceSm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  exercise.durationOrReps!,
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: block.indicatorColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (exercise.technicalNote != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info,
                                  size: 16,
                                  color: AppColors.accentRpe,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    exercise.technicalNote!,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurface,
                                      fontSize: 11,
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
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color fgColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        label,
        style: AppTypography.labelMonoSm.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  // --- GUÍA NUTRICIONAL DIARIA (RF-NUT-01) ---
  Widget _buildDailyNutritionSection() {
    final day = _currentDay;
    if (day == null) return const SizedBox.shrink();
    final calorieRatio = (day.loggedCalories / day.targetCalories).clamp(
      0.0,
      1.0,
    );
    final remainingCalories = (day.targetCalories - day.loggedCalories).clamp(
      0,
      5000,
    );
    final proteinRatio =
        ((day.loggedProteinGrams / day.targetProteinGrams) * 100)
            .clamp(0, 100)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'GUÍA NUTRICIONAL DIARIA',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    'DÉFICIT MODERADO',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm + 2),

        FlatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Energético
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BALANCE ENERGÉTICO',
                    style: AppTypography.labelMonoMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_formatNumber(day.loggedCalories)} / ${_formatNumber(day.targetCalories)} kcal',
                    style: AppTypography.labelMonoMd.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Barra de Progreso Plana
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: calorieRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentEnergy,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(calorieRatio * 100).round()}% completado',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Restante: $remainingCalories kcal',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              // Fila Proteína e Hidratación
              Row(
                children: [
                  // Tarjeta Proteína
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceSm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PROTEÍNA',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: AppColors.accentEnergy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  '$proteinRatio%',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.accentEnergy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${day.loggedProteinGrams}g',
                            style: AppTypography.headlineLg.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'Meta: ${day.targetProteinGrams}g',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: _extraProtein > 0
                                  ? AppColors.accentEnergy
                                  : AppColors.surfaceElevated,
                              borderRadius: AppSpacing.roundedSm,
                              child: InkWell(
                                onTap: _toggleExtraProtein,
                                borderRadius: AppSpacing.roundedSm,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    _extraProtein > 0
                                        ? '${day.loggedProteinGrams}g / ${day.targetProteinGrams}g'
                                        : '+25g Proteína',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelMonoSm.copyWith(
                                      color: _extraProtein > 0
                                          ? AppColors.surfaceBase
                                          : AppColors.accentEnergy,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),

                  // Tarjeta Hidratación
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceSm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HIDRATACIÓN',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: AppColors.accentWater,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  '${day.loggedWaterLiters.toStringAsFixed(2)}L',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.accentWater,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 4 bloques de agua
                          Row(
                            children: List.generate(4, (i) {
                              final isFilled = _extraWaterAdded
                                  ? true
                                  : (i < 3);
                              return Expanded(
                                child: Container(
                                  height: 18,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFilled
                                        ? AppColors.accentWater
                                        : AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Meta: ${day.targetWaterLiters.toStringAsFixed(1)}L',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: _extraWaterAdded
                                  ? AppColors.accentWater
                                  : AppColors.surfaceElevated,
                              borderRadius: AppSpacing.roundedSm,
                              child: InkWell(
                                onTap: _toggleExtraWater,
                                borderRadius: AppSpacing.roundedSm,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    _extraWaterAdded
                                        ? '3.0 L COMPLETADO'
                                        : '+0.75 L Agua',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelMonoSm.copyWith(
                                      color: _extraWaterAdded
                                          ? AppColors.surfaceBase
                                          : AppColors.accentWater,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceMd),

              // Plan de Comidas Sugerido (Checkboxes Instantáneos)
              Text(
                'PLAN DE COMIDAS SUGERIDO',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),

              ...List.generate(day.meals.length, (mIdx) {
                final meal = day.meals[mIdx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Material(
                    color: AppColors.surfaceDim,
                    borderRadius: AppSpacing.roundedMd,
                    child: InkWell(
                      onTap: () => _toggleMeal(mIdx),
                      borderRadius: AppSpacing.roundedMd,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: meal.isCompleted
                                    ? AppColors.accentEnergy
                                    : AppColors.surfaceElevated,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: meal.isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppColors.surfaceBase,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        meal.name,
                                        style: AppTypography.headlineSm
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                      ),
                                      Text(
                                        '${meal.calories} kcal · ${meal.proteinGrams}g P',
                                        style: AppTypography.labelMonoSm
                                            .copyWith(
                                              color: meal.isCompleted
                                                  ? AppColors.accentEnergy
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    meal.description,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayName(String letter) {
    switch (letter) {
      case 'L':
        return 'Lunes';
      case 'M':
        return 'Martes';
      case 'X':
        return 'Miércoles';
      case 'J':
        return 'Jueves';
      case 'V':
        return 'Viernes';
      case 'S':
        return 'Sábado';
      case 'D':
        return 'Domingo';
      default:
        return '';
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
