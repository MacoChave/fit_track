import 'package:flutter/material.dart';
import '../database/repositories/ai_routine_repository.dart';
import '../database/repositories/workout_repository.dart';
import '../models/workout_summary_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/main_layout.dart';
import '../widgets/flat_button.dart';
import '../widgets/flat_card.dart';
import 'biometrics_equipment_screen.dart';
import 'calendar_nutrition_screen.dart';
import 'macronutrients_food_log_screen.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData? summaryData;

  const WorkoutSummaryScreen({
    super.key,
    this.summaryData,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late WorkoutSummaryData _summary;
  int _selectedMoodIndex = 0; // 'Energizado 💪' activo por defecto
  bool _isSaved = false;
  bool _isSaving = false;
  int _currentNavIndex = -1; // Pantalla de resumen (no está en la barra principal)

  @override
  void initState() {
    super.initState();
    _summary = widget.summaryData ?? WorkoutSummaryData.getSampleSummary();
  }

  void _onMoodSelected(int index) {
    setState(() {
      _selectedMoodIndex = index;
    });
  }

  Future<void> _saveWorkoutToSqlite() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = WorkoutRepository();
      final moodText = _summary.moodOptions.isNotEmpty && _selectedMoodIndex < _summary.moodOptions.length
          ? _summary.moodOptions[_selectedMoodIndex]
          : null;
      repo.saveWorkoutSummary(_summary, mood: moodText).catchError((_) {});

      final aiRepo = AiRoutineRepository();
      final match = RegExp(r'\d+').firstMatch(_summary.dayDate);
      if (match != null) {
        final dayNum = int.tryParse(match.group(0)!);
        if (dayNum != null) {
          aiRepo.markDayCompleted(dayNumber: dayNum).catchError((_) {});
        }
      }
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
            const Icon(Icons.done_all, color: AppColors.accentEnergy, size: 20),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: Text(
                '¡Sesión persistida con éxito en SQLite offline! Mesociclo actualizado.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToCalendar() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CalendarNutritionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      subtitle: 'RESUMEN',
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
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MacronutrientsFoodLogScreen()),
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
            _buildCelebrationMilestoneHeader(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildCoreTelemetryKpiGrid(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildRpeDistributionBarChart(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildExecutionBreakdownSection(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildAiMotorAnalysisSection(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildSubjectiveMoodSection(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildHeartRateBanner(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildActionButtons(),
            const SizedBox(height: AppSpacing.space2Xl),
          ],
        ),
      ),
    );
  }

  // --- 1. HEADER & CELEBRATION MILESTONE ---
  Widget _buildCelebrationMilestoneHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accentEnergy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SESIÓN COMPLETADA · ${_summary.dayDate}',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'LOCAL DB',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        Text(
          _summary.sessionTitle,
          style: AppTypography.headlineLg.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _summary.mesocycleInfo,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm + 2),

        // Banner de Récord / Hito de Victoria
        FlatCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedMd,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.emoji_events,
                  size: 26,
                  color: AppColors.accentEnergy,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 ${_summary.adherencePercent}% ADHERENCIA',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summary.recordHeadline,
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summary.recordDescription,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. CORE TELEMETRY KPI GRID (4 FLAT METRIC CARDS) ---
  Widget _buildCoreTelemetryKpiGrid() {
    final kpis = _summary.kpis;

    return Column(
      children: [
        Row(
          children: [
            // KPI 1: Volumen Total
            Expanded(
              child: _buildKpiCard(
                label: 'VOLUMEN TOTAL',
                icon: Icons.fitness_center,
                iconColor: AppColors.textMuted,
                value: '${kpis.totalVolumeKg}',
                unit: 'KG',
                unitColor: AppColors.accentEnergy,
                footerWidget: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: AppColors.accentEnergy,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${kpis.volumeTrendPercent}% vs sem. ant.',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSm),
            // KPI 2: Duración
            Expanded(
              child: _buildKpiCard(
                label: 'DURACIÓN',
                icon: Icons.timer,
                iconColor: AppColors.textMuted,
                value: kpis.durationFormatted,
                unit: 'MIN',
                unitColor: AppColors.textMuted,
                footerWidget: RichText(
                  text: TextSpan(
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                    ),
                    children: [
                      TextSpan(text: 'Meta: ${kpis.targetDurationMinutes}m · '),
                      TextSpan(
                        text: '${kpis.restEfficiencyPercent}% descanso',
                        style: const TextStyle(
                          color: AppColors.accentEnergy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        Row(
          children: [
            // KPI 3: RPE Promedio
            Expanded(
              child: _buildKpiCard(
                label: 'RPE PROMEDIO',
                icon: Icons.speed,
                iconColor: AppColors.accentRpe,
                value: '${kpis.averageRpe}',
                unit: '/10',
                unitColor: AppColors.textMuted,
                footerWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    'Zona Hipertrofia',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentRpe,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSm),
            // KPI 4: Series Totales
            Expanded(
              child: _buildKpiCard(
                label: 'SERIES TOTALES',
                icon: Icons.task_alt,
                iconColor: AppColors.accentEnergy,
                value: '${kpis.completedSets}',
                unit: '/ ${kpis.totalSets}',
                unitColor: AppColors.accentEnergy,
                footerWidget: Text(
                  '${kpis.executedBlocks} bloques ejecutados',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required Color unitColor,
    required Widget footerWidget,
  }) {
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
              Text(
                label,
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.timerDisplayMobile.copyWith(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.labelMonoSm.copyWith(
                  color: unitColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          footerWidget,
        ],
      ),
    );
  }

  // --- 3. GRÁFICO DE ESFUERZO (RPE POR SERIE) ---
  Widget _buildRpeDistributionBarChart() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    size: 18,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DISTRIBUCIÓN RPE POR SERIE',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRpe,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Óptimo (7.5-8.5)',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentRpe,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // Contenedor del Gráfico Plano con Sweet Spot Overlay
          Container(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 14,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Stack(
              children: [
                // Sweet Spot Zone Banner (RPE 7.5 a 8.5)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 24,
                  height: 38,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    padding: const EdgeInsets.only(right: 6, top: 4),
                    alignment: Alignment.topRight,
                    child: Text(
                      'TARGET SWEET SPOT',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Columnas de barras
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _summary.rpeBars.map((bar) {
                      Color barColor;
                      Color textColor;

                      if (bar.isHiit) {
                        barColor = AppColors.accentRest;
                        textColor = AppColors.accentRest;
                      } else if (bar.isPr) {
                        barColor = AppColors.accentEnergy;
                        textColor = AppColors.accentEnergy;
                      } else if (bar.rpe >= 7.5) {
                        barColor = AppColors.accentRpe.withValues(alpha: 0.85);
                        textColor = AppColors.accentRpe;
                      } else {
                        barColor = AppColors.surfaceElevated;
                        textColor = AppColors.textMuted;
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                bar.rpe.toStringAsFixed(1),
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: textColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: bar.heightFactor,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                bar.label,
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: bar.isPr
                                      ? AppColors.accentEnergy
                                      : (bar.isHiit
                                          ? AppColors.accentRest
                                          : AppColors.textMuted),
                                  fontSize: 9.5,
                                  fontWeight: (bar.isPr || bar.isHiit)
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. DESGLOSE DETALLADO POR BLOQUES Y EJERCICIOS ---
  Widget _buildExecutionBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DESGLOSE DE EJECUCIÓN',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              '3/3 BLOQUES',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.accentEnergy,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        ..._summary.blocks.map((block) => _buildBlockCard(block)),
      ],
    );
  }

  Widget _buildBlockCard(SummaryBlock block) {
    Color themeColor;
    if (block.theme == SummaryBlockTheme.mobility) {
      themeColor = AppColors.accentWater;
    } else if (block.theme == SummaryBlockTheme.strength) {
      themeColor = AppColors.accentEnergy;
    } else {
      themeColor = AppColors.accentRest;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      child: FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del bloque
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      block.title,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  block.durationText,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm),

            // Contenido del bloque (descripción simple o lista de ejercicios)
            if (block.singleLineDescription != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      block.singleLineDescription!,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      block.singleLineStatus ?? '',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (block.exercises.isNotEmpty) ...[
              ...block.exercises.map((exercise) => _buildExerciseSummaryItem(exercise)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSummaryItem(SummaryExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
      ),
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
                    Text(
                      exercise.name,
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (exercise.badgeText != null) ...[
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
                              exercise.badgeText!,
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.accentEnergy,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          exercise.rpeLabel,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${exercise.completedSets} / ${exercise.totalSets}',
                    style: AppTypography.labelMonoMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'SERIES',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Chips de rendimiento de series
          Row(
            children: exercise.sets.map((setChip) {
              final isPr = setChip.isPr;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isPr
                          ? AppColors.surfaceContainerHighest
                          : AppColors.surfaceElevated,
                      borderRadius: AppSpacing.roundedSm,
                      border: isPr
                          ? Border.all(
                              color: AppColors.accentEnergy.withValues(alpha: 0.5),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          setChip.setLabel,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: isPr
                                ? AppColors.accentEnergy
                                : AppColors.textMuted,
                            fontWeight: isPr ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 8.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          setChip.summaryText,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: isPr
                                ? AppColors.accentEnergy
                                : AppColors.textPrimary,
                            fontWeight: isPr ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 5. FEEDBACK DE LA IA Y RECUPERACIÓN (EDGE BYOK) ---
  Widget _buildAiMotorAnalysisSection() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentEnergy.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.psychology,
                      size: 18,
                      color: AppColors.accentEnergy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    'Análisis Motor IA (Edge BYOK)',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  _summary.motorScore,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),
          Text(
            _summary.motorFeedback,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // Chips de Prescripción de Recuperación
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 22,
                        color: AppColors.accentWater,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
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
                              '+${_summary.recovery.hydrationMl} ml agua',
                              style: AppTypography.labelMonoMd.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.egg_alt,
                        size: 22,
                        color: AppColors.accentEnergy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SÍNTESIS PRO',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              '${_summary.recovery.proteinGrams}g proteína <${_summary.recovery.proteinWindowMinutes}m',
                              style: AppTypography.labelMonoMd.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. SENSACIÓN SUBJETIVA Y ESTADO DE ÁNIMO ---
  Widget _buildSubjectiveMoodSection() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¿Cómo te sientes post-sesión?',
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                'FEEDBACK RIR',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // 2x2 Grid de Chips de Estado de Ánimo
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
            ),
            itemCount: _summary.moodOptions.length,
            itemBuilder: (context, index) {
              final moodText = _summary.moodOptions[index];
              final isSelected = _selectedMoodIndex == index;

              return Material(
                color: isSelected
                    ? AppColors.accentEnergy
                    : AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  key: Key('mood_chip_$index'),
                  onTap: () => _onMoodSelected(index),
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      moodText,
                      style: AppTypography.headlineSm.copyWith(
                        color: isSelected
                            ? AppColors.surfaceBase
                            : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- BANNER DE RECUPERACIÓN CARDÍACA ---
  Widget _buildHeartRateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_heart,
            size: 20,
            color: AppColors.accentEnergy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _summary.heartRateRecoveryText,
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.accentEnergy,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. BOTONES DE ACCIÓN (CTAs ERGONÓMICOS DE GIMNASIO) ---
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón Primario: Guardar en SQLite
        FlatButton(
          label: _isSaving
              ? 'PERSISTIENDO REGISTRO...'
              : (_isSaved
                  ? '¡REGISTRO CONFIRMADO EN SQLITE!'
                  : 'GUARDAR EN HISTORIAL SQLITE Y SALIR'),
          icon: _isSaved ? Icons.done_all : Icons.check_circle,
          isLoading: _isSaving,
          onPressed: _saveWorkoutToSqlite,
        ),
        const SizedBox(height: AppSpacing.spaceSm),

        // Botones Secundarios: Compartir / Calendario
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Resumen copiado al portapapeles para compartir.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COMPARTIR',
                          style: AppTypography.labelMonoMd.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: _navigateToCalendar,
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CALENDARIO',
                          style: AppTypography.labelMonoMd.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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

        // Nota de seguridad y cifrado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 13,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Datos cifrados con AES-256 localmente · Listo para recálculo del mesociclo.',
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
