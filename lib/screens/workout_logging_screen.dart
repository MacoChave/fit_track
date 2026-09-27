import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/ai_routine_repository.dart';
import '../database/repositories/workout_repository.dart';
import '../models/calendar_models.dart';
import '../models/workout_execution_models.dart';
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
import 'workout_summary_screen.dart';

class WorkoutLoggingScreen extends StatefulWidget {
  final DaySchedule? daySchedule;
  final ExerciseItem? initialExercise;
  final List<ExerciseItem>? exercises;
  final bool fallbackToSample;

  const WorkoutLoggingScreen({
    super.key,
    this.daySchedule,
    this.initialExercise,
    this.exercises,
    this.fallbackToSample = false,
  });

  @override
  State<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends State<WorkoutLoggingScreen> {
  late LiveExerciseSession _session;
  late TextEditingController _notesController;

  double _currentWeight = 22.0;
  int _currentReps = 10;
  int _currentRpe = 8;
  int _timerSeconds = 48;
  Timer? _countdownTimer;
  bool _audioBeepsEnabled = true;
  bool _isSetConfirmed = false;
  int _currentNavIndex = -1; // Pantalla de sesión activa (no está en la barra principal)

  // Contexto de rutina desde SQLite
  bool _isSampleMode = true;
  bool _hasNoSession = false;
  List<ExerciseItem> _routineExercises = [];
  int _currentExerciseIndex = 0;
  int _activeSetIndex = 1; // en sample mode, serie 2 es activa
  String _currentEquipment = 'Mancuernas';

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: 'Retracción escapular sólida, cadencia 2-0-1-0 limpia',
    );

    if (widget.fallbackToSample) {
      _isSampleMode = true;
      _session = LiveExerciseSession.getSampleSession();
      _startTimer();
      return;
    }

    if (widget.daySchedule != null ||
        widget.initialExercise != null ||
        widget.exercises != null) {
      _isSampleMode = false;
      if (widget.daySchedule != null) {
        for (final block in widget.daySchedule!.blocks) {
          _routineExercises.addAll(block.exercises);
        }
      } else if (widget.exercises != null) {
        _routineExercises = List.from(widget.exercises!);
      }
      if (_routineExercises.isEmpty && widget.initialExercise != null) {
        _routineExercises = [widget.initialExercise!];
      }

      int targetIdx = 0;
      if (widget.initialExercise != null && _routineExercises.isNotEmpty) {
        final found = _routineExercises.indexWhere(
          (e) => e.name.trim().toLowerCase() == widget.initialExercise!.name.trim().toLowerCase(),
        );
        if (found != -1) targetIdx = found;
      }

      if (_routineExercises.isNotEmpty) {
        _loadExerciseAtIndex(targetIdx);
        _startTimer();
      } else {
        _hasNoSession = true;
      }
    } else {
      // Intentar cargar rutina desde SQLite (Local-First DERCAS)
      _hasNoSession = true;
      _session = LiveExerciseSession.getSampleSession();
      _loadRoutineFromSqlite();
    }
  }

  Future<void> _loadRoutineFromSqlite() async {
    try {
      final repo = AiRoutineRepository();
      final schedules = await repo.getWeekSchedule();
      if (schedules.isNotEmpty) {
        final todaySchedule = schedules.firstWhere(
          (s) => s.statusType == DayStatusType.today,
          orElse: () => schedules.first,
        );
        final exercises = <ExerciseItem>[];
        for (final block in todaySchedule.blocks) {
          exercises.addAll(block.exercises);
        }
        if (exercises.isNotEmpty && mounted) {
          setState(() {
            _routineExercises = exercises;
            _isSampleMode = false;
            _hasNoSession = false;
            _loadExerciseAtIndex(0);
          });
          _startTimer();
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _hasNoSession = true;
      });
    }
  }

  void _loadExerciseAtIndex(int index) {
    if (index < 0 || index >= _routineExercises.length) return;
    _currentExerciseIndex = index;
    final ex = _routineExercises[index];

    int seriesCount = 3;
    int targetReps = 10;
    if (ex.seriesAndReps != null) {
      final match = RegExp(r'(\d+)\s*Series\s*×\s*(\d+)\s*Reps', caseSensitive: false)
          .firstMatch(ex.seriesAndReps!);
      if (match != null) {
        seriesCount = int.tryParse(match.group(1)!) ?? 3;
        targetReps = int.tryParse(match.group(2)!) ?? 10;
      }
    }

    String equipment = 'Mancuernas';
    if (ex.description.contains('·')) {
      equipment = ex.description.split('·').first.trim();
    } else if (widget.daySchedule != null && widget.daySchedule!.equipmentSummary.isNotEmpty) {
      equipment = widget.daySchedule!.equipmentSummary;
    }
    _currentEquipment = equipment;

    final double defaultWeight = ex.weightKg ?? 22.0;
    _currentWeight = defaultWeight;
    _currentReps = targetReps;
    _currentRpe = 8;
    _timerSeconds = ex.restSeconds ?? 60;
    _activeSetIndex = 0;
    _isSetConfirmed = false;

    final sets = List.generate(seriesCount, (i) {
      return WorkoutSet(
        setNumber: i + 1,
        targetReps: targetReps,
        targetWeightKg: defaultWeight,
        actualReps: targetReps,
        actualWeightKg: defaultWeight,
        targetRpe: 8.0,
        actualRpe: 8.0,
        status: i == 0 ? WorkoutSetStatus.active : WorkoutSetStatus.pending,
        notes: i == 0
            ? (ex.technicalNote ?? 'Técnica limpia y controlada')
            : 'Prescrito · RPE 8.0',
      );
    });

    _session = LiveExerciseSession(
      exerciseName: ex.name,
      prescription: '$targetReps reps @ ${defaultWeight.toStringAsFixed(1)} kg · $equipment',
      rirTarget: 'RIR 2',
      restSeconds: ex.restSeconds ?? 60,
      sets: sets,
    );

    _notesController.text = ex.technicalNote ?? 'Técnica limpia y controlada';
    _loadPreviousLogsFromSqlite(ex.name);
  }

  Future<void> _loadPreviousLogsFromSqlite(String exerciseName) async {
    try {
      final repo = WorkoutRepository();
      final lastLog = await repo.getLastLoggedWeightAndReps(exerciseName);
      if (lastLog != null && mounted) {
        setState(() {
          _currentWeight = (lastLog['actualWeightKg'] as num?)?.toDouble() ?? _currentWeight;
          _currentReps = (lastLog['actualReps'] as num?)?.toInt() ?? _currentReps;
          final rpe = (lastLog['actualRpe'] as num?)?.toInt();
          if (rpe != null && rpe >= 1 && rpe <= 10) {
            _currentRpe = rpe;
          }
          if (_session.sets.isNotEmpty && _session.sets[0].status == WorkoutSetStatus.active) {
            _session.sets[0].actualWeightKg = _currentWeight;
            _session.sets[0].actualReps = _currentReps;
          }
        });
      }
    } catch (_) {}
  }

  void _persistActiveSetRepOrWeight() {
    try {
      if (_session.sets.isNotEmpty && _activeSetIndex < _session.sets.length) {
        final currentSet = _session.sets[_activeSetIndex];
        currentSet.actualReps = _currentReps;
        currentSet.actualWeightKg = _currentWeight;
        currentSet.actualRpe = _currentRpe.toDouble();
        final repo = WorkoutRepository();
        repo.saveSetLog(
          set: currentSet,
          exerciseName: _session.exerciseName,
        );
      }
    } catch (_) {}
  }

  void _updateWeight(double weight) {
    setState(() {
      _currentWeight = weight;
      if (_session.sets.isNotEmpty && _activeSetIndex < _session.sets.length) {
        _session.sets[_activeSetIndex].actualWeightKg = weight;
      }
    });
    _persistActiveSetRepOrWeight();
  }

  void _updateReps(int reps) {
    setState(() {
      _currentReps = reps;
      if (_session.sets.isNotEmpty && _activeSetIndex < _session.sets.length) {
        _session.sets[_activeSetIndex].actualReps = reps;
      }
    });
    _persistActiveSetRepOrWeight();
  }

  void _updateRpe(int rpe) {
    setState(() {
      _currentRpe = rpe;
      if (_session.sets.isNotEmpty && _activeSetIndex < _session.sets.length) {
        _session.sets[_activeSetIndex].actualRpe = rpe.toDouble();
      }
    });
    _persistActiveSetRepOrWeight();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _add30Seconds() {
    setState(() {
      _timerSeconds += 30;
    });
  }

  void _skipRest() {
    setState(() {
      _timerSeconds = 0;
      _countdownTimer?.cancel();
    });
  }

  void _toggleAudioBeeps() {
    setState(() {
      _audioBeepsEnabled = !_audioBeepsEnabled;
    });
  }

  Future<void> _confirmCurrentSet() async {
    if (_isSampleMode) {
      if (_isSetConfirmed) {
        final set3 = _session.sets[2];
        set3.actualWeightKg = _currentWeight;
        set3.actualReps = _currentReps;
        set3.actualRpe = _currentRpe.toDouble();
        set3.status = WorkoutSetStatus.completed;
        set3.notes = 'RPE $_currentRpe.0 · Finalizada';

        try {
          final repo = WorkoutRepository();
          await repo.saveSetLog(
            set: set3,
            exerciseName: _session.exerciseName,
          );
          await repo.saveCompletedExercise(
            exerciseName: _session.exerciseName,
            completedSets: 3,
            lastWeightKg: _currentWeight,
            lastReps: _currentReps,
            avgRpe: _currentRpe.toDouble(),
          );
        } catch (_) {}

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutSummaryScreen(),
          ),
        );
        return;
      }

      setState(() {
        _isSetConfirmed = true;
        final set2 = _session.sets[1];
        set2.actualWeightKg = _currentWeight;
        set2.actualReps = _currentReps;
        set2.actualRpe = _currentRpe.toDouble();
        set2.status = WorkoutSetStatus.completed;
        set2.notes = 'RPE $_currentRpe.0 · Completada';

        // Activar serie 3
        _session.sets[2].status = WorkoutSetStatus.active;
      });

      try {
        final repo = WorkoutRepository();
        repo.saveSetLog(
          set: _session.sets[1],
          exerciseName: _session.exerciseName,
        );
      } catch (_) {}

      if (!mounted) return;

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
              const Icon(Icons.task_alt, color: AppColors.accentEnergy, size: 20),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  '¡Serie 2 registrada! Iniciando descanso previo a Serie 3.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Modo Rutina desde SQLite
    if (_activeSetIndex >= _session.sets.length) {
      await _finishRoutine();
      return;
    }

    final currentSet = _session.sets[_activeSetIndex];
    setState(() {
      currentSet.actualWeightKg = _currentWeight;
      currentSet.actualReps = _currentReps;
      currentSet.actualRpe = _currentRpe.toDouble();
      currentSet.status = WorkoutSetStatus.completed;
      currentSet.notes = _notesController.text.isNotEmpty
          ? _notesController.text
          : 'RPE $_currentRpe.0 · Completada';
    });

    try {
      final repo = WorkoutRepository();
      await repo.saveSetLog(
        set: currentSet,
        exerciseName: _session.exerciseName,
      );
    } catch (_) {}

    final completedSetNum = currentSet.setNumber;

    if (_activeSetIndex + 1 < _session.sets.length) {
      setState(() {
        _activeSetIndex++;
        _session.sets[_activeSetIndex].status = WorkoutSetStatus.active;
        _timerSeconds = _session.restSeconds;
      });
      _startTimer();

      if (!mounted) return;

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
              const Icon(Icons.task_alt, color: AppColors.accentEnergy, size: 20),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  '¡Serie $completedSetNum registrada! Iniciando descanso previo a Serie ${_session.sets[_activeSetIndex].setNumber}.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Última serie de este ejercicio -> persistir ejercicio finalizado en SQLite
      try {
        final aiRepo = AiRoutineRepository();
        await aiRepo.markExerciseCompleted(
          exerciseName: _session.exerciseName,
        );
        final workoutRepo = WorkoutRepository();
        await workoutRepo.saveCompletedExercise(
          exerciseName: _session.exerciseName,
          completedSets: _session.sets.length,
          lastWeightKg: _currentWeight,
          lastReps: _currentReps,
          avgRpe: _currentRpe.toDouble(),
        );
      } catch (_) {}

      if (_currentExerciseIndex + 1 < _routineExercises.length) {
        if (!mounted) return;

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
                    '¡${_session.exerciseName} completado! Pasando a ${_routineExercises[_currentExerciseIndex + 1].name}',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _loadExerciseAtIndex(_currentExerciseIndex + 1);
        });
      } else {
        await _finishRoutine();
      }
    }
  }

  Future<void> _finishRoutine() async {
    try {
      final aiRepo = AiRoutineRepository();
      if (widget.daySchedule != null) {
        await aiRepo.markDayCompleted(dayNumber: widget.daySchedule!.dayNumber);
      }
    } catch (_) {}

    final summary = _buildWorkoutSummary();

    try {
      final workoutRepo = WorkoutRepository();
      await workoutRepo.saveWorkoutSummary(summary);
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          summaryData: summary,
        ),
      ),
    );
  }

  WorkoutSummaryData _buildWorkoutSummary() {
    final title = widget.daySchedule?.sessionTitle ?? _session.exerciseName;
    final dateStr = widget.daySchedule != null
        ? '${widget.daySchedule!.dayLetter} ${widget.daySchedule!.dayNumber}'
        : 'HOY';

    final List<SummaryExercise> summaryExercises = [];
    if (_routineExercises.isNotEmpty) {
      for (final ex in _routineExercises) {
        summaryExercises.add(
          SummaryExercise(
            name: ex.name,
            rpeLabel: 'RPE 8.0',
            completedSets: 3,
            totalSets: 3,
            badgeText: ex.isBodyweight ? 'Peso Corporal' : null,
            sets: [
              SetPerformanceChip(
                setLabel: 'SET 1',
                summaryText: '10 × ${(ex.weightKg ?? 22.0).toStringAsFixed(0)}kg',
              ),
              SetPerformanceChip(
                setLabel: 'SET 2',
                summaryText: '10 × ${(ex.weightKg ?? 22.0).toStringAsFixed(0)}kg',
              ),
              SetPerformanceChip(
                setLabel: 'SET 3',
                summaryText: '10 × ${(ex.weightKg ?? 22.0).toStringAsFixed(0)}kg',
                isPr: true,
              ),
            ],
          ),
        );
      }
    } else {
      summaryExercises.add(
        SummaryExercise(
          name: _session.exerciseName,
          rpeLabel: 'RPE $_currentRpe.0',
          completedSets: _session.sets.length,
          totalSets: _session.sets.length,
          sets: _session.sets.map((s) => SetPerformanceChip(
            setLabel: 'SET ${s.setNumber}',
            summaryText: '${s.actualReps} × ${s.actualWeightKg.toStringAsFixed(0)}kg',
          )).toList(),
        ),
      );
    }

    final totalSets = summaryExercises.fold<int>(0, (sum, e) => sum + e.totalSets);

    return WorkoutSummaryData(
      sessionTitle: title,
      dayDate: dateStr,
      mesocycleInfo: 'Mesociclo Activo · Sesión SQLite',
      adherencePercent: 100,
      recordHeadline: '¡Sesión completada con éxito!',
      recordDescription: 'Completaste los ejercicios programados para la sesión.',
      kpis: SessionKpis(
        totalVolumeKg: (_currentWeight * _currentReps * totalSets).toInt(),
        volumeTrendPercent: 5.0,
        durationFormatted: '${widget.daySchedule?.durationMinutes ?? 40}:00',
        targetDurationMinutes: widget.daySchedule?.durationMinutes ?? 40,
        restEfficiencyPercent: 95,
        averageRpe: _currentRpe.toDouble(),
        completedSets: totalSets,
        totalSets: totalSets,
        executedBlocks: widget.daySchedule?.blockCount ?? 1,
      ),
      rpeBars: [
        const RpeBarItem(label: 'S1', rpe: 7.5),
        RpeBarItem(label: 'S2', rpe: _currentRpe.toDouble()),
        const RpeBarItem(label: 'S3', rpe: 8.5, isPr: true),
      ],
      blocks: [
        SummaryBlock(
          blockNumber: 1,
          title: 'Bloque Principal de Fuerza',
          theme: SummaryBlockTheme.strength,
          durationText: '${widget.daySchedule?.durationMinutes ?? 40} MIN',
          exercises: summaryExercises,
        ),
      ],
      motorScore: '96/100',
      motorFeedback: 'Control biomecánico sólido y simetría de movimiento óptima.',
      recovery: const RecoveryPrescription(
        hydrationMl: 650,
        proteinGrams: 35,
        proteinWindowMinutes: 45,
      ),
      moodOptions: const ['Energizado 💪', 'Fatigado 🔋', 'Satisfecho ✨', 'Adolorido 🩹'],
      heartRateRecoveryText: 'Frecuencia cardiaca normalizada en 90 segundos.',
    );
  }

  String get _formattedTimer {
    final mins = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_timerSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  int get _currentRir => (10 - _currentRpe).clamp(0, 10);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      subtitle: 'REGISTRO EN VIVO',
      currentNavIndex: _currentNavIndex,
      onNavIndexChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CalendarNutritionScreen(),
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MacronutrientsFoodLogScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BiometricsEquipmentScreen(),
            ),
          );
        }
      },
      child: _hasNoSession
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2Xl),
                child: FlatCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spaceLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fitness_center_outlined,
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
                          'No hay ninguna sesión de entrenamiento programada en la base de datos SQLite.\n\nGenera una rutina con IA o importa tu archivo JSON en el Calendario para comenzar a registrar series y cargas.',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.spaceLg),
                        FlatButton(
                          label: 'Ir al Calendario',
                          icon: Icons.calendar_today,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CalendarNutritionScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
                vertical: AppSpacing.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLiveStatusAndTimerHUD(),
                  const SizedBox(height: AppSpacing.spaceMd),
                  _buildMainRegistrationModule(),
                  const SizedBox(height: AppSpacing.spaceMd),
                  _buildSetHistoryProgressSection(),
                  const SizedBox(height: AppSpacing.spaceMd),
                  _buildErgonomicActionButtons(),
                  const SizedBox(height: AppSpacing.space2Xl),
                ],
              ),
            ),
    );
  }

  // --- BANNER EN VIVO Y REST TIMER HUD ---
  Widget _buildLiveStatusAndTimerHUD() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges de estado superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentEnergy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSampleMode
                        ? 'EN VIVO · SERIE 2 DE 3'
                        : 'EN VIVO · SERIE ${_activeSetIndex + 1} DE ${_session.sets.length}',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _toggleAudioBeeps,
                borderRadius: AppSpacing.roundedFull,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _audioBeepsEnabled ? Icons.volume_up : Icons.volume_off,
                        size: 14,
                        color: _audioBeepsEnabled
                            ? AppColors.onSurfaceVariant
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _audioBeepsEnabled ? 'BEEPS ACTIVO' : 'SILENCIADO',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: _audioBeepsEnabled
                              ? AppColors.onSurfaceVariant
                              : AppColors.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Título del Ejercicio & RIR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session.exerciseName,
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.adjust,
                          size: 14,
                          color: AppColors.accentEnergy,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Prescripción: ${_session.prescription}',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  _session.rirTarget,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!_isSampleMode && _routineExercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentWater.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.accentWater.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 12, color: AppColors.accentWater),
                      const SizedBox(width: 4),
                      Text(
                        _currentEquipment.toUpperCase(),
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.accentWater,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_routineExercises.length > 1)
                  Row(
                    children: [
                      InkWell(
                        onTap: _currentExerciseIndex > 0
                            ? () => setState(() => _loadExerciseAtIndex(_currentExerciseIndex - 1))
                            : null,
                        child: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: _currentExerciseIndex > 0
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentExerciseIndex + 1}/${_routineExercises.length}',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _currentExerciseIndex + 1 < _routineExercises.length
                            ? () => setState(() => _loadExerciseAtIndex(_currentExerciseIndex + 1))
                            : null,
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _currentExerciseIndex + 1 < _routineExercises.length
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // Rest Timer HUD (Contenedor con cuenta regresiva)
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer,
                        size: 20,
                        color: AppColors.accentEnergy,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESCANSO EN CURSO',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _formattedTimer,
                          style: AppTypography.timerDisplayMobile.copyWith(
                            fontSize: 34,
                            height: 1.05,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Material(
                      color: AppColors.surfaceCard,
                      borderRadius: AppSpacing.roundedSm,
                      child: InkWell(
                        onTap: _add30Seconds,
                        borderRadius: AppSpacing.roundedSm,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add,
                                size: 15,
                                color: AppColors.accentEnergy,
                              ),
                              Text(
                                '30s',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: AppColors.surfaceCard,
                      borderRadius: AppSpacing.roundedSm,
                      child: InkWell(
                        onTap: _toggleAudioBeeps,
                        borderRadius: AppSpacing.roundedSm,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            _audioBeepsEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 18,
                            color: _audioBeepsEnabled
                                ? AppColors.accentEnergy
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MÓDULO PRINCIPAL DE REGISTRO (RF-EXE-02) ---
  Widget _buildMainRegistrationModule() {
    final double lbEquiv = _currentWeight * 2.20462;

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titular de Registro & Indicador SQLite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 18,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REGISTRO DE CARGAS',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.storage,
                    size: 14,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SQLite Offline',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // 1. Carga Real (Weight Stepper)
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CARGA UTILIZADA (POR MANCUERNA)',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '+2 kg vs previa',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stepper grande (56dp touch height)
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Material(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppSpacing.roundedMd,
                        child: InkWell(
                          onTap: () {
                            if (_currentWeight > 1.0) {
                              _updateWeight(_currentWeight - 1.0);
                            }
                          },
                          borderRadius: AppSpacing.roundedMd,
                          child: const Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _currentWeight.toStringAsFixed(1),
                                  style: AppTypography.labelMonoLg.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kg',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${lbEquiv.toStringAsFixed(1)} lb equiv.',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Material(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppSpacing.roundedMd,
                        child: InkWell(
                          onTap: () {
                            _updateWeight(_currentWeight + 1.0);
                          },
                          borderRadius: AppSpacing.roundedMd,
                          child: const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Presets rápidos (18, 20, 22, 24 kg)
                Row(
                  children: [18.0, 20.0, 22.0, 24.0].map((preset) {
                    final isSelected = _currentWeight == preset;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Material(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppSpacing.roundedSm,
                          child: InkWell(
                            onTap: () {
                              _updateWeight(preset);
                            },
                            borderRadius: AppSpacing.roundedSm,
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '${preset.toInt()} kg',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelected
                                      ? AppColors.accentEnergy
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // 2. Repeticiones Ejecutadas
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REPETICIONES EJECUTADAS',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Meta: 10 reps',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Botones rápidos de 8 a 12 (56dp target)
                Row(
                  children: [
                    _buildRepOption(8, '-2'),
                    _buildRepOption(9, '-1'),
                    _buildRepOption(10, 'META'),
                    _buildRepOption(11, '+1'),
                    _buildRepOption(12, '+2'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // 3. Escala RPE (1-10) con RIR Contextual
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ESFUERZO PERCIBIDO (RPE)',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'RPE $_currentRpe.0 · RIR $_currentRir',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.accentEnergy,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 10 casillas RPE
                Row(
                  children: List.generate(10, (idx) {
                    final rpeVal = idx + 1;
                    final isSelected = _currentRpe == rpeVal;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Material(
                          color: isSelected
                              ? AppColors.accentEnergy
                              : AppColors.surfaceElevated,
                          borderRadius: AppSpacing.roundedSm,
                          child: InkWell(
                            key: Key('rpe_$rpeVal'),
                            onTap: () {
                              _updateRpe(rpeVal);
                            },
                            borderRadius: AppSpacing.roundedSm,
                            child: Container(
                              height: 38,
                              alignment: Alignment.center,
                              child: Text(
                                '$rpeVal',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelected
                                      ? AppColors.surfaceBase
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Mensaje contextual descriptivo del RPE
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
                        size: 15,
                        color: AppColors.accentEnergy,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          LiveExerciseSession.rpeDescriptions[_currentRpe] ?? '',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),

          // 4. Nota de Técnica / Sensación (Opcional)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOTA DE TÉCNICA / SENSACIÓN (OPCIONAL)',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _notesController,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepOption(int rep, String sublabel) {
    final isSelected = _currentReps == rep;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: isSelected ? AppColors.accentEnergy : AppColors.surfaceElevated,
          borderRadius: AppSpacing.roundedMd,
          child: InkWell(
            onTap: () {
              _updateReps(rep);
            },
            borderRadius: AppSpacing.roundedMd,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$rep',
                    style: AppTypography.headlineSm.copyWith(
                      color: isSelected
                          ? AppColors.surfaceBase
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: isSelected
                          ? AppColors.surfaceBase
                          : (sublabel == 'META'
                              ? AppColors.accentEnergy
                              : AppColors.textMuted),
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PROGRESO DE SERIES EN LA SESIÓN ---
  Widget _buildSetHistoryProgressSection() {
    if (_isSampleMode) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESO DE SERIES',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isSetConfirmed ? '2 de 3 Completadas' : '1 de 3 Completadas',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm + 2),

            // Serie 1: Completada
            _buildSetProgressRow(
              setNumber: 1,
              title: '10 reps @ 22.0 kg',
              subtitle: 'RPE 7.5 · RIR 2-3',
              tagLabel: 'COMPLETA',
              tagColor: AppColors.accentEnergy,
              isCompleted: true,
            ),
            const SizedBox(height: 6),

            // Serie 2: Editando en vivo / Actual
            _buildSetProgressRow(
              setNumber: 2,
              title: '$_currentReps reps @ ${_currentWeight.toStringAsFixed(1)} kg',
              subtitle: 'RPE $_currentRpe.0 · Editando en vivo',
              tagLabel: _isSetConfirmed ? 'COMPLETA' : 'ACTUAL',
              tagColor: _isSetConfirmed ? AppColors.accentEnergy : AppColors.accentRpe,
              isCurrent: !_isSetConfirmed,
              isCompleted: _isSetConfirmed,
            ),
            const SizedBox(height: 6),

            // Serie 3: En espera
            _buildSetProgressRow(
              setNumber: 3,
              title: 'Meta: 10 reps @ 22-24 kg',
              subtitle: 'Prescrito · RPE 8.5',
              tagLabel: _isSetConfirmed ? 'ACTUAL' : 'EN ESPERA',
              tagColor: _isSetConfirmed ? AppColors.accentRpe : AppColors.textMuted,
              isCurrent: _isSetConfirmed,
              isPending: !_isSetConfirmed,
            ),
          ],
        ),
      );
    }

    final completedCount = _session.sets.where((s) => s.status == WorkoutSetStatus.completed).length;

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESO DE SERIES',
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '$completedCount de ${_session.sets.length} Completadas',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),
          ..._session.sets.map((s) {
            final isCompleted = s.status == WorkoutSetStatus.completed;
            final isCurrent = s.status == WorkoutSetStatus.active;
            final isPending = s.status == WorkoutSetStatus.pending;

            String title;
            String subtitle;
            String tagLabel;
            Color tagColor;

            if (isCompleted) {
              title = '${s.actualReps} reps @ ${s.actualWeightKg.toStringAsFixed(1)} kg';
              subtitle = 'RPE ${s.actualRpe.toStringAsFixed(1)} · ${s.notes ?? "Completada"}';
              tagLabel = 'COMPLETA';
              tagColor = AppColors.accentEnergy;
            } else if (isCurrent) {
              title = '$_currentReps reps @ ${_currentWeight.toStringAsFixed(1)} kg';
              subtitle = 'RPE $_currentRpe.0 · Editando en vivo';
              tagLabel = 'ACTUAL';
              tagColor = AppColors.accentRpe;
            } else {
              title = 'Meta: ${s.targetReps} reps @ ${s.targetWeightKg.toStringAsFixed(1)} kg';
              subtitle = 'Prescrito · RPE ${s.targetRpe.toStringAsFixed(1)}';
              tagLabel = 'EN ESPERA';
              tagColor = AppColors.textMuted;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildSetProgressRow(
                setNumber: s.setNumber,
                title: title,
                subtitle: subtitle,
                tagLabel: tagLabel,
                tagColor: tagColor,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isPending: isPending,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSetProgressRow({
    required int setNumber,
    required String title,
    required String subtitle,
    required String tagLabel,
    required Color tagColor,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isPending = false,
  }) {
    Color circleBg;
    Color circleFg;

    if (isCompleted) {
      circleBg = AppColors.accentEnergy.withValues(alpha: 0.2);
      circleFg = AppColors.accentEnergy;
    } else if (isCurrent) {
      circleBg = AppColors.accentRpe;
      circleFg = AppColors.surfaceBase;
    } else {
      circleBg = AppColors.surfaceElevated;
      circleFg = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.surfaceContainerHighest
            : (isPending ? AppColors.surfaceContainerLowest : AppColors.surfaceElevated),
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$setNumber',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: circleFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMonoMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: isCurrent ? AppColors.accentRpe : AppColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.accentEnergy.withValues(alpha: 0.15)
                  : (isCurrent
                      ? AppColors.accentRpe.withValues(alpha: 0.2)
                      : AppColors.surfaceElevated),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                if (isCompleted) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 13,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  tagLabel,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: tagColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTONES ERGONÓMICOS DE GIMNASIO (RNF-04) ---
  Widget _buildErgonomicActionButtons() {
    String primaryLabel;
    if (_isSampleMode) {
      primaryLabel = _isSetConfirmed
          ? 'Confirmar Serie 3 y Finalizar'
          : 'Confirmar Serie 2 y Descansar';
    } else {
      if (_activeSetIndex + 1 < _session.sets.length) {
        primaryLabel = 'Confirmar Serie ${_activeSetIndex + 1} y Descansar';
      } else if (_currentExerciseIndex + 1 < _routineExercises.length) {
        primaryLabel = 'Confirmar Serie ${_activeSetIndex + 1} y Siguiente Ejercicio';
      } else {
        primaryLabel = 'Confirmar Serie ${_activeSetIndex + 1} y Finalizar';
      }
    }

    return Column(
      children: [
        // Botón Principal de Confirmación (56-58dp)
        FlatButton(
          label: primaryLabel,
          icon: Icons.task_alt,
          onPressed: _confirmCurrentSet,
        ),
        const SizedBox(height: AppSpacing.spaceSm),

        // Botones Secundarios: Omitir Descanso / Descartar Serie
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: _skipRest,
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fast_forward,
                          size: 16,
                          color: AppColors.accentRpe,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'OMITIR DESCANSO',
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
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Serie descartada del registro.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.accentRest),
                        ),
                      ),
                    );
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cancel,
                          size: 16,
                          color: AppColors.accentRest,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DESCARTAR SERIE',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.accentRest,
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
      ],
    );
  }
}
