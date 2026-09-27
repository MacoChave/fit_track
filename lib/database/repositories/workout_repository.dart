import 'package:sqflite/sqflite.dart';
import '../../models/workout_execution_models.dart';
import '../../models/workout_summary_models.dart';
import '../database_helper.dart';

/// Repositorio de SQLite para registrar entrenamientos, cargas, series y resúmenes de sesión (RF-EXE-01, RF-EXE-02).
class WorkoutRepository {
  final DatabaseHelper _dbHelper;

  WorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Guarda una serie ejecutada individualmente en SQLite (RF-EXE-02)
  Future<void> saveSetLog({
    required WorkoutSet set,
    required String exerciseName,
    String? workoutLogId,
    DateTime? date,
    bool isPr = false,
  }) async {
    final db = await _dbHelper.database;
    final scheduledDateStr = _formatDate(date ?? DateTime.now());
    final setId = '${exerciseName}_s${set.setNumber}_$scheduledDateStr';

    await db.insert(
      'workout_set_logs',
      {
        'id': setId,
        'workout_log_id': workoutLogId,
        'exercise_name': exerciseName,
        'set_number': set.setNumber,
        'scheduled_date': scheduledDateStr,
        'target_reps': set.targetReps,
        'actual_reps': set.actualReps,
        'target_weight_kg': set.targetWeightKg,
        'actual_weight_kg': set.actualWeightKg,
        'target_rpe': set.targetRpe,
        'actual_rpe': set.actualRpe,
        'status': set.status.name,
        'notes': set.notes,
        'is_pr': isPr ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Recupera la última carga y repeticiones registradas para un ejercicio (Criterio de Aceptación RF-EXE-02)
  Future<Map<String, dynamic>?> getLastLoggedWeightAndReps(String exerciseName) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'workout_set_logs',
      where: 'exercise_name = ? AND status = ?',
      whereArgs: [exerciseName, WorkoutSetStatus.completed.name],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return {
        'actualWeightKg': (results.first['actual_weight_kg'] as num).toDouble(),
        'actualReps': (results.first['actual_reps'] as num).toInt(),
        'actualRpe': (results.first['actual_rpe'] as num).toDouble(),
        'notes': results.first['notes'] as String?,
      };
    }
    return null;
  }

  /// Guarda la finalización de un ejercicio y sus datos en SQLite (RF-EXE-01, RF-EXE-02)
  Future<void> saveCompletedExercise({
    required String exerciseName,
    int completedSets = 3,
    double lastWeightKg = 22.0,
    int lastReps = 10,
    double avgRpe = 8.0,
    String? scheduledDate,
  }) async {
    final db = await _dbHelper.database;
    final dateStr = scheduledDate ?? _formatDate(DateTime.now());
    final id = 'exercise_${exerciseName}_$dateStr';

    await db.insert(
      'workout_set_logs',
      {
        'id': id,
        'exercise_name': exerciseName,
        'set_number': completedSets,
        'scheduled_date': dateStr,
        'target_reps': lastReps,
        'actual_reps': lastReps,
        'target_weight_kg': lastWeightKg,
        'actual_weight_kg': lastWeightKg,
        'target_rpe': avgRpe,
        'actual_rpe': avgRpe,
        'status': WorkoutSetStatus.completed.name,
        'notes': 'Ejercicio completado',
        'is_pr': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Guarda el resumen completo de una sesión de entrenamiento ejecutada
  Future<void> saveWorkoutSummary(
    WorkoutSummaryData summary, {
    String? mood,
    DateTime? sessionDate,
  }) async {
    final db = await _dbHelper.database;
    final date = sessionDate ?? DateTime.now();
    final scheduledDateStr = _formatDate(date);
    final logId = 'workout_${scheduledDateStr}_${date.millisecondsSinceEpoch}';

    await db.transaction((txn) async {
      await txn.insert(
        'workout_logs',
        {
          'id': logId,
          'scheduled_date': scheduledDateStr,
          'day_date': summary.dayDate,
          'session_title': summary.sessionTitle,
          'adherence_percent': summary.adherencePercent,
          'record_headline': summary.recordHeadline,
          'record_description': summary.recordDescription,
          'total_volume_kg': summary.kpis.totalVolumeKg,
          'volume_trend_percent': summary.kpis.volumeTrendPercent,
          'duration_formatted': summary.kpis.durationFormatted,
          'target_duration_minutes': summary.kpis.targetDurationMinutes,
          'rest_efficiency_percent': summary.kpis.restEfficiencyPercent,
          'average_rpe': summary.kpis.averageRpe,
          'completed_sets': summary.kpis.completedSets,
          'total_sets': summary.kpis.totalSets,
          'executed_blocks': summary.kpis.executedBlocks,
          'motor_score': summary.motorScore,
          'motor_feedback': summary.motorFeedback,
          'mood': mood ?? (summary.moodOptions.isNotEmpty ? summary.moodOptions[0] : null),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Guardar también las series de los bloques del resumen
      for (final block in summary.blocks) {
        for (final exercise in block.exercises) {
          for (int sIdx = 0; sIdx < exercise.sets.length; sIdx++) {
            final setChip = exercise.sets[sIdx];
            final setId = '${logId}_${exercise.name}_s${sIdx + 1}';

            await txn.insert(
              'workout_set_logs',
              {
                'id': setId,
                'workout_log_id': logId,
                'exercise_name': exercise.name,
                'set_number': sIdx + 1,
                'scheduled_date': scheduledDateStr,
                'target_reps': 10,
                'actual_reps': 10,
                'target_weight_kg': 22.0,
                'actual_weight_kg': 22.0,
                'target_rpe': 8.0,
                'actual_rpe': 8.0,
                'status': 'completed',
                'notes': setChip.summaryText,
                'is_pr': setChip.isPr ? 1 : 0,
                'created_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });
  }

  /// Consulta el historial de sesiones guardadas
  Future<List<Map<String, dynamic>>> getWorkoutLogsHistory() async {
    final db = await _dbHelper.database;
    return await db.query(
      'workout_logs',
      orderBy: 'created_at DESC',
    );
  }

  /// Consulta las series de una sesión
  Future<List<Map<String, dynamic>>> getSetsForSession(String workoutLogId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'workout_set_logs',
      where: 'workout_log_id = ?',
      whereArgs: [workoutLogId],
      orderBy: 'set_number ASC',
    );
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
