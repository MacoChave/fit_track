import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/calendar_models.dart';
import '../../theme/app_colors.dart';
import '../database_helper.dart';

/// Modelo de entidad de ejercicio extraído y guardado desde el JSON de IA
class RoutineExerciseRecord {
  final String id;
  final String routineDayId;
  final String planId;
  final String scheduledDate; // Fecha (YYYY-MM-DD)
  final String diaSemana; // Lunes, Martes, etc.
  final int blockNumber;
  final String blockType;
  final String exerciseOrder;
  final String exerciseId;
  final String exerciseName;
  final int series; // Series
  final int repeticionesObjetivo; // Repeticiones
  final String equipoRequerido; // Equipo
  final int descansoSegundos;
  final double? pesoSugeridoKg;
  final String? notasTecnicas;
  final bool isBodyweight;

  RoutineExerciseRecord({
    required this.id,
    required this.routineDayId,
    required this.planId,
    required this.scheduledDate,
    required this.diaSemana,
    required this.blockNumber,
    required this.blockType,
    required this.exerciseOrder,
    required this.exerciseId,
    required this.exerciseName,
    required this.series,
    required this.repeticionesObjetivo,
    required this.equipoRequerido,
    required this.descansoSegundos,
    this.pesoSugeridoKg,
    this.notasTecnicas,
    this.isBodyweight = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_day_id': routineDayId,
      'plan_id': planId,
      'scheduled_date': scheduledDate,
      'dia_semana': diaSemana,
      'block_number': blockNumber,
      'block_type': blockType,
      'exercise_order': exerciseOrder,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'series': series,
      'repeticiones_objetivo': repeticionesObjetivo,
      'equipo_requerido': equipoRequerido,
      'descanso_segundos': descansoSegundos,
      'peso_sugerido_kg': pesoSugeridoKg,
      'notas_tecnicas': notasTecnicas,
      'is_bodyweight': isBodyweight ? 1 : 0,
    };
  }

  factory RoutineExerciseRecord.fromMap(Map<String, dynamic> map) {
    return RoutineExerciseRecord(
      id: map['id'] as String,
      routineDayId: map['routine_day_id'] as String,
      planId: map['plan_id'] as String,
      scheduledDate: map['scheduled_date'] as String,
      diaSemana: map['dia_semana'] as String,
      blockNumber: (map['block_number'] as num).toInt(),
      blockType: map['block_type'] as String,
      exerciseOrder: map['exercise_order'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      series: (map['series'] as num).toInt(),
      repeticionesObjetivo: (map['repeticiones_objetivo'] as num).toInt(),
      equipoRequerido: map['equipo_requerido'] as String,
      descansoSegundos: (map['descanso_segundos'] as num).toInt(),
      pesoSugeridoKg: (map['peso_sugerido_kg'] as num?)?.toDouble(),
      notasTecnicas: map['notas_tecnicas'] as String?,
      isBodyweight: (map['is_bodyweight'] as num?)?.toInt() == 1,
    );
  }
}

/// Registro de generación de IA (prompt y respuesta en JSON)
class AiGenerationRecord {
  final String id;
  final String planId;
  final String createdAt;
  final String provider;
  final String model;
  final String promptText;
  final String rawResponseJson;
  final int weeksCount;
  final String primaryGoal;
  final String status;

  AiGenerationRecord({
    required this.id,
    required this.planId,
    required this.createdAt,
    required this.provider,
    required this.model,
    required this.promptText,
    required this.rawResponseJson,
    required this.weeksCount,
    required this.primaryGoal,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'created_at': createdAt,
      'provider': provider,
      'model': model,
      'prompt_text': promptText,
      'raw_response_json': rawResponseJson,
      'weeks_count': weeksCount,
      'primary_goal': primaryGoal,
      'status': status,
    };
  }

  factory AiGenerationRecord.fromMap(Map<String, dynamic> map) {
    return AiGenerationRecord(
      id: map['id'] as String,
      planId: map['plan_id'] as String,
      createdAt: map['created_at'] as String,
      provider: map['provider'] as String,
      model: map['model'] as String,
      promptText: map['prompt_text'] as String,
      rawResponseJson: map['raw_response_json'] as String,
      weeksCount: (map['weeks_count'] as num).toInt(),
      primaryGoal: map['primary_goal'] as String,
      status: map['status'] as String,
    );
  }
}

/// Repositorio de SQLite para guardar prompts, respuestas JSON y extraer rutinas
class AiRoutineRepository {
  final DatabaseHelper _dbHelper;

  AiRoutineRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Guarda el prompt enviado a la IA y el resultado obtenido en JSON (RF-IA-01)
  Future<AiGenerationRecord> saveAiPromptAndResponse({
    required String prompt,
    required String rawJson,
    required String provider,
    String model = 'gemini-1.5-flash',
    String? planId,
    int? weeks,
    String? primaryGoal,
    String status = 'success',
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final genId = 'gen_${DateTime.now().millisecondsSinceEpoch}';

    // Intenta extraer plan_id, semanas y objetivo del JSON si no fueron provistos
    String resolvedPlanId = planId ?? 'plan_$genId';
    int resolvedWeeks = weeks ?? 4;
    String resolvedGoal = primaryGoal ?? 'Perdida de Grasa y Definicion';

    try {
      final decoded = json.decode(rawJson);
      if (decoded is Map<String, dynamic>) {
        if (decoded['plan_id'] != null) resolvedPlanId = decoded['plan_id'].toString();
        if (decoded['semanas'] != null) resolvedWeeks = (decoded['semanas'] as num).toInt();
        if (decoded['objetivo_primario'] != null) resolvedGoal = decoded['objetivo_primario'].toString();
      }
    } catch (_) {}

    final record = AiGenerationRecord(
      id: genId,
      planId: resolvedPlanId,
      createdAt: now,
      provider: provider,
      model: model,
      promptText: prompt,
      rawResponseJson: rawJson,
      weeksCount: resolvedWeeks,
      primaryGoal: resolvedGoal,
      status: status,
    );

    await db.insert(
      'ai_generations',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return record;
  }

  /// Procesa el JSON de la IA (DERCAS 5.2) y guarda en SQLite:
  /// el plan, los días y específicamente la FECHA, SERIES, REPETICIONES y EQUIPO de cada ejercicio.
  Future<void> importRoutineFromJson(
    String rawJson, {
    String? aiGenerationId,
    DateTime? weekStartDate,
  }) async {
    final db = await _dbHelper.database;
    final decoded = json.decode(rawJson) as Map<String, dynamic>;

    final planId = decoded['plan_id']?.toString() ?? 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final weeks = (decoded['semanas'] as num?)?.toInt() ?? 4;
    final primaryGoal = decoded['objetivo_primario']?.toString() ?? 'Perdida de Grasa y Definicion';
    final diasList = (decoded['dias'] as List<dynamic>?) ?? [];

    final startDate = weekStartDate ?? _getMondayOfWeek(DateTime.now());

    await db.transaction((txn) async {
      // Limpiar días y ejercicios previos de este mismo plan si ya existía para evitar colisiones
      await txn.delete('routine_exercises', where: 'plan_id = ?', whereArgs: [planId]);
      await txn.delete('routine_days', where: 'plan_id = ?', whereArgs: [planId]);

      // Desactivar planes anteriores si existen
      await txn.update('routine_plans', {'is_active': 0});

      // Insertar o reemplazar plan de rutina
      await txn.insert(
        'routine_plans',
        {
          'id': planId,
          'ai_generation_id': aiGenerationId,
          'weeks': weeks,
          'primary_goal': primaryGoal,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Mapeo de día de semana a desplazamiento de días desde el lunes
      final dayOffsetMap = {
        'lunes': 0,
        'martes': 1,
        'miércoles': 2,
        'miercoles': 2,
        'jueves': 3,
        'viernes': 4,
        'sábado': 5,
        'sabado': 5,
        'domingo': 6,
      };

      const dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

      for (int i = 0; i < diasList.length; i++) {
        final diaMap = diasList[i] as Map<String, dynamic>;
        final diaSemanaStr = diaMap['dia_semana']?.toString() ?? 'Lunes';
        final diaLower = diaSemanaStr.toLowerCase().trim();
        final offset = dayOffsetMap[diaLower] ?? i;

        final scheduledDateObj = startDate.add(Duration(days: offset));
        final scheduledDateStr = _formatDate(scheduledDateObj); // YYYY-MM-DD
        final dayNumber = scheduledDateObj.day;
        final dayLetter = dayLetters[offset % 7];

        final routineDayId = '${planId}_day_${offset + 1}';
        final sessionTitle = diaMap['enfoque']?.toString() ?? diaMap['tipo_sesion']?.toString() ?? 'Sesión Deportiva';
        final durationMin = (diaMap['duracion_estimada_min'] as num?)?.toInt() ?? (diaMap['duracion_minutos'] as num?)?.toInt() ?? 40;

        final warmup = diaMap['calentamiento'] != null ? json.encode(diaMap['calentamiento']) : null;
        final finisher = diaMap['finisher_core'] != null ? json.encode(diaMap['finisher_core']) : null;

        final guiaNutri = diaMap['guia_nutricional'] as Map<String, dynamic>?;
        final targetCal = (guiaNutri?['calorias_objetivo'] as num?)?.toInt() ?? (diaMap['calorias_objetivo'] as num?)?.toInt() ?? 1900;
        final targetProt = (guiaNutri?['proteina_gramos'] as num?)?.toInt() ?? (diaMap['proteina_objetivo_g'] as num?)?.toInt() ?? 145;
        final targetWater = (guiaNutri?['agua_litros'] as num?)?.toDouble() ?? (diaMap['agua_objetivo_l'] as num?)?.toDouble() ?? 3.0;

        // Estado del día (si es hoy, completado o pendiente)
        final todayStr = _formatDate(DateTime.now());
        String status = 'pending';
        if (scheduledDateStr == todayStr) {
          status = 'today';
        } else if (scheduledDateObj.isBefore(DateTime.now()) && scheduledDateStr != todayStr) {
          status = 'completed';
        }

        // Insertar día de rutina
        await txn.insert(
          'routine_days',
          {
            'id': routineDayId,
            'plan_id': planId,
            'day_letter': dayLetter,
            'day_number': dayNumber,
            'dia_semana': diaSemanaStr,
            'scheduled_date': scheduledDateStr,
            'session_title': sessionTitle,
            'session_number_label': 'Sesión 0${i + 1}/0${diasList.length}',
            'duration_minutes': durationMin,
            'equipment_summary': 'Mancuernas',
            'rpe': 8,
            'warmup_json': warmup,
            'finisher_json': finisher,
            'target_calories': targetCal,
            'target_protein_grams': targetProt,
            'target_water_liters': targetWater,
            'status': status,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Extraer bloques y ejercicios (guardando fecha, series, repeticiones y equipo)
        final bloques = (diaMap['bloques'] as List<dynamic>?) ?? [];
        for (int bIdx = 0; bIdx < bloques.length; bIdx++) {
          final bloqueMap = bloques[bIdx] as Map<String, dynamic>;
          final blockNumber = bIdx + 1;
          final blockType = bloqueMap['tipo']?.toString() ?? 'Fuerza';
          final ejercicios = (bloqueMap['ejercicios'] as List<dynamic>?) ?? [];

          for (int eIdx = 0; eIdx < ejercicios.length; eIdx++) {
            final ejMap = ejercicios[eIdx] as Map<String, dynamic>;
            final exerciseId = ejMap['id']?.toString() ?? ejMap['ejercicio_id']?.toString() ?? 'ej_${bIdx}_$eIdx';
            final exerciseName = ejMap['nombre']?.toString() ?? 'Ejercicio';
            final series = (ejMap['series'] as num?)?.toInt() ?? 3;
            final reps = (ejMap['repeticiones_objetivo'] as num?)?.toInt() ?? 10;
            final equipo = ejMap['equipo_requerido']?.toString() ?? 'peso_corporal';
            final descanso = (ejMap['descanso_segundos'] as num?)?.toInt() ?? 60;
            final notas = ejMap['notas_tecnicas']?.toString();
            final isBw = equipo.toLowerCase().contains('corporal') ||
                equipo.toLowerCase().contains('bodyweight');

            final exerciseRecordId = '${routineDayId}_ex_${blockNumber}_$eIdx';

            await txn.insert(
              'routine_exercises',
              {
                'id': exerciseRecordId,
                'routine_day_id': routineDayId,
                'plan_id': planId,
                'scheduled_date': scheduledDateStr, // FECHA
                'dia_semana': diaSemanaStr,
                'block_number': blockNumber,
                'block_type': blockType,
                'exercise_order': '0${eIdx + 1}',
                'exercise_id': exerciseId,
                'exercise_name': exerciseName,
                'series': series, // SERIES
                'repeticiones_objetivo': reps, // REPETICIONES
                'equipo_requerido': equipo, // EQUIPO
                'descanso_segundos': descanso,
                'peso_sugerido_kg': (ejMap['peso_sugerido_kg'] as num?)?.toDouble() ?? 22.0,
                'notas_tecnicas': notas,
                'is_bodyweight': isBw ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });
  }

  /// Consulta los ejercicios registrados filtrados por FECHA (YYYY-MM-DD o día de semana)
  /// Retorna series, repeticiones y equipo para la pantalla de entrenamiento y calendario
  Future<List<RoutineExerciseRecord>> getRoutineExercises({
    String? scheduledDate,
    String? diaSemana,
    String? planId,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (scheduledDate != null) {
      whereClauses.add('scheduled_date = ?');
      whereArgs.add(scheduledDate);
    }
    if (diaSemana != null) {
      whereClauses.add('dia_semana = ?');
      whereArgs.add(diaSemana);
    }
    if (planId != null) {
      whereClauses.add('plan_id = ?');
      whereArgs.add(planId);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'routine_exercises',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'scheduled_date ASC, block_number ASC, exercise_order ASC',
    );

    return results.map((m) => RoutineExerciseRecord.fromMap(m)).toList();
  }

  /// Consulta el calendario semanal completo directamente desde SQLite para la pantalla de Calendario
  /// Consulta el calendario semanal completo directamente desde SQLite para la pantalla de Calendario
  Future<List<DaySchedule>> getWeekSchedule({DateTime? referenceDate}) async {
    final db = await _dbHelper.database;
    final monday = _getMondayOfWeek(referenceDate ?? DateTime.now());
    final sunday = monday.add(const Duration(days: 6));

    final startDateStr = _formatDate(monday);
    final endDateStr = _formatDate(sunday);
    final todayStr = _formatDate(DateTime.now());

    // 1. Buscar los días del plan activo en SQLite
    final activePlans = await db.query(
      'routine_plans',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    final String? activePlanId = activePlans.isNotEmpty ? activePlans.first['id'] as String : null;

    List<Map<String, dynamic>> dayRows = [];
    if (activePlanId != null) {
      dayRows = await db.query(
        'routine_days',
        where: 'plan_id = ?',
        whereArgs: [activePlanId],
        orderBy: 'scheduled_date ASC',
      );
    }

    if (dayRows.isEmpty) {
      dayRows = await db.query(
        'routine_days',
        where: 'scheduled_date >= ? AND scheduled_date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'scheduled_date ASC',
      );
    }

    if (dayRows.isEmpty) {
      dayRows = await db.query(
        'routine_days',
        orderBy: 'scheduled_date ASC',
        limit: 7,
      );
    }

    if (dayRows.isEmpty) {
      // Si no hay datos en SQLite (base de datos limpia), NO retornar datos hardcodeados
      return [];
    }

    // Mapear los días obtenidos por fecha y por nombre de día (normalizado)
    final Map<String, Map<String, dynamic>> daysByDate = {};
    final Map<String, Map<String, dynamic>> daysByName = {};
    for (final row in dayRows) {
      final sDate = row['scheduled_date']?.toString();
      if (sDate != null && sDate.isNotEmpty) {
        daysByDate[sDate] = row;
      }
      final sName = row['dia_semana']?.toString().toLowerCase().trim();
      if (sName != null && sName.isNotEmpty) {
        daysByName[sName] = row;
        final normalized = sName.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
        daysByName[normalized] = row;
      }
    }

    const dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const normalizedDayNames = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

    final List<DaySchedule> schedules = [];

    // Construir los 7 días de la semana sincronizados con SQLite
    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayDateStr = _formatDate(dayDate);
      final dayNumber = dayDate.day;
      final dayLetter = dayLetters[i];
      final normName = normalizedDayNames[i];

      // Buscar si este día tiene rutina programada en SQLite
      final dayRow = daysByDate[dayDateStr] ?? daysByName[normName];

      if (dayRow != null) {
        final routineDayId = dayRow['id'] as String;

        // Consultar ejercicios del día desde SQLite
        final exerciseRows = await db.query(
          'routine_exercises',
          where: 'routine_day_id = ?',
          whereArgs: [routineDayId],
          orderBy: 'block_number ASC, exercise_order ASC',
        );

        // Agrupar ejercicios por bloques
        final Map<int, List<ExerciseItem>> blockExercisesMap = {};
        final Map<int, String> blockTitlesMap = {};

        for (final exRow in exerciseRows) {
          final bNum = (exRow['block_number'] as num).toInt();
          final bType = exRow['block_type'] as String;
          blockTitlesMap[bNum] = 'Bloque $bNum · $bType';

          final series = (exRow['series'] as num).toInt();
          final reps = (exRow['repeticiones_objetivo'] as num).toInt();
          final equipo = exRow['equipo_requerido'] as String;
          final descanso = (exRow['descanso_segundos'] as num).toInt();
          final notas = exRow['notas_tecnicas'] as String?;
          final isBw = (exRow['is_bodyweight'] as num?)?.toInt() == 1;

          final isCompleted = (exRow['is_completed'] as num?)?.toInt() == 1;

          final item = ExerciseItem(
            order: exRow['exercise_order'] as String,
            name: exRow['exercise_name'] as String,
            description: '$equipo · $series Series × $reps Reps',
            seriesAndReps: '$series Series × $reps Reps',
            restSeconds: descanso,
            weightKg: (exRow['peso_sugerido_kg'] as num?)?.toDouble() ?? 22.0,
            isBodyweight: isBw,
            technicalNote: notas,
            isCompleted: isCompleted,
          );

          blockExercisesMap.putIfAbsent(bNum, () => []).add(item);
        }

        final blocks = <ExerciseBlock>[];
        final colors = [AppColors.accentWater, AppColors.accentEnergy, AppColors.accentRpe];
        int colorIdx = 0;

        // Añadir calentamiento si existe en SQLite
        if (dayRow['warmup_json'] != null) {
          try {
            final warmupList = json.decode(dayRow['warmup_json'] as String) as List<dynamic>;
            final warmupItems = warmupList.map((w) {
              final wMap = w as Map<String, dynamic>;
              return ExerciseItem(
                order: '00',
                name: wMap['nombre']?.toString() ?? 'Movilidad Articular',
                description: wMap['duracion_seg'] != null
                    ? '${wMap['duracion_seg']}s de movilidad'
                    : '${wMap['repeticiones'] ?? 12} reps controladas',
                isBodyweight: true,
              );
            }).toList();

            if (warmupItems.isNotEmpty) {
              blocks.add(
                ExerciseBlock(
                  blockNumber: 0,
                  title: 'Bloque 0 · Calentamiento Dinámico',
                  durationMinutes: 5,
                  indicatorColor: AppColors.accentWater,
                  exercises: warmupItems,
                ),
              );
            }
          } catch (_) {}
        }

        // Añadir bloques de ejercicios principales
        blockExercisesMap.forEach((bNum, exercises) {
          blocks.add(
            ExerciseBlock(
              blockNumber: bNum,
              title: blockTitlesMap[bNum] ?? 'Bloque $bNum · Fuerza',
              durationMinutes: (dayRow['duration_minutes'] as num).toInt() ~/ (blockExercisesMap.isNotEmpty ? blockExercisesMap.length : 1),
              indicatorColor: colors[colorIdx % colors.length],
              exercises: exercises,
            ),
          );
          colorIdx++;
        });

        // Parsear estado de SQLite
        DayStatusType statusType = DayStatusType.pending;
        final statusStr = dayRow['status'] as String;
        if (statusStr == 'completed') {
          statusType = DayStatusType.completed;
        } else if (dayDateStr == todayStr || statusStr == 'today') {
          statusType = DayStatusType.today;
        } else if (statusStr == 'activeRest') {
          statusType = DayStatusType.activeRest;
        } else if (statusStr == 'recovery') {
          statusType = DayStatusType.recovery;
        }

        final targetCal = (dayRow['target_calories'] as num).toInt();
        final targetProt = (dayRow['target_protein_grams'] as num).toInt();
        final targetWater = (dayRow['target_water_liters'] as num).toDouble();

        // Generar comidas estructuradas para el día
        final meals = [
          MealItem(
            id: 'meal_1_$routineDayId',
            name: 'Desayuno Anabólico',
            description: 'Avena con proteína y frutos secos',
            calories: (targetCal * 0.28).round(),
            proteinGrams: (targetProt * 0.30).round(),
            isCompleted: statusType == DayStatusType.completed,
          ),
          MealItem(
            id: 'meal_2_$routineDayId',
            name: 'Almuerzo / Post-Entreno',
            description: 'Pechuga o ternera con arroz jazmín y verduras',
            calories: (targetCal * 0.42).round(),
            proteinGrams: (targetProt * 0.45).round(),
            isCompleted: statusType == DayStatusType.completed,
          ),
          MealItem(
            id: 'meal_3_$routineDayId',
            name: 'Cena Ligera de Recuperación',
            description: 'Salmón a la plancha con espárragos',
            calories: (targetCal * 0.30).round(),
            proteinGrams: (targetProt * 0.25).round(),
            isCompleted: false,
          ),
        ];

        schedules.add(
          DaySchedule(
            dayLetter: dayLetter,
            dayNumber: dayNumber,
            statusType: statusType,
            sessionTitle: dayRow['session_title'] as String,
            sessionNumberLabel: dayRow['session_number_label'] as String,
            durationMinutes: (dayRow['duration_minutes'] as num).toInt(),
            blockCount: blocks.length,
            equipmentSummary: dayRow['equipment_summary'] as String? ?? 'Mancuernas',
            rpe: (dayRow['rpe'] as num?)?.toInt() ?? 8,
            blocks: blocks,
            targetCalories: targetCal,
            loggedCalories: statusType == DayStatusType.completed ? targetCal : (targetCal * 0.75).round(),
            targetProteinGrams: targetProt,
            loggedProteinGrams: statusType == DayStatusType.completed ? targetProt : (targetProt * 0.75).round(),
            targetWaterLiters: targetWater,
            loggedWaterLiters: statusType == DayStatusType.completed ? targetWater : 2.25,
            meals: meals,
          ),
        );
      } else {
        // Día de descanso / recuperación sin entrenamiento prescrito
        final isToday = dayDateStr == todayStr;
        final isSunday = i == 6;

        schedules.add(
          DaySchedule(
            dayLetter: dayLetter,
            dayNumber: dayNumber,
            statusType: isToday
                ? DayStatusType.today
                : (isSunday ? DayStatusType.recovery : DayStatusType.activeRest),
            sessionTitle: isSunday
                ? 'Recuperación Neural & Descanso'
                : 'Descanso Activo & Movilidad',
            sessionNumberLabel: 'Descanso 0${i + 1}',
            durationMinutes: 20,
            blockCount: 0,
            equipmentSummary: 'Peso Corporal',
            rpe: 4,
            blocks: const [],
            targetCalories: 2000,
            loggedCalories: 1550,
            targetProteinGrams: 140,
            loggedProteinGrams: 110,
            targetWaterLiters: 2.5,
            loggedWaterLiters: 2.0,
            meals: [
              MealItem(
                id: 'meal_rest_1_$i',
                name: 'Desayuno Ligero',
                description: 'Yogur griego con granola y fruta',
                calories: 550,
                proteinGrams: 35,
              ),
              MealItem(
                id: 'meal_rest_2_$i',
                name: 'Almuerzo Equilibrado',
                description: 'Ensalada completa con atún o pollo',
                calories: 850,
                proteinGrams: 55,
              ),
              MealItem(
                id: 'meal_rest_3_$i',
                name: 'Cena Liviana',
                description: 'Crema de verduras con queso fresco',
                calories: 600,
                proteinGrams: 50,
              ),
            ],
          ),
        );
      }
    }

    return schedules;
  }

  /// Marca una jornada de rutina como completada en SQLite
  Future<void> markDayCompleted({
    int? dayNumber,
    String? scheduledDate,
    String? routineDayId,
  }) async {
    final db = await _dbHelper.database;
    if (routineDayId != null) {
      await db.update(
        'routine_days',
        {'status': 'completed'},
        where: 'id = ?',
        whereArgs: [routineDayId],
      );
    } else if (scheduledDate != null) {
      await db.update(
        'routine_days',
        {'status': 'completed'},
        where: 'scheduled_date = ?',
        whereArgs: [scheduledDate],
      );
    } else if (dayNumber != null) {
      await db.update(
        'routine_days',
        {'status': 'completed'},
        where: 'day_number = ?',
        whereArgs: [dayNumber],
      );
    }

    // Marcar también sus ejercicios asociados como completados en SQLite
    try {
      await db.execute('ALTER TABLE routine_exercises ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
      if (routineDayId != null) {
        await db.update('routine_exercises', {'is_completed': 1}, where: 'routine_day_id = ?', whereArgs: [routineDayId]);
      } else if (scheduledDate != null) {
        await db.update('routine_exercises', {'is_completed': 1}, where: 'scheduled_date = ?', whereArgs: [scheduledDate]);
      }
    } catch (_) {}
  }

  /// Marca un ejercicio individual como completado en SQLite
  Future<void> markExerciseCompleted({
    required String exerciseName,
    String? routineDayId,
    String? scheduledDate,
  }) async {
    final db = await _dbHelper.database;
    try {
      await db.execute('ALTER TABLE routine_exercises ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
    } catch (_) {}

    final List<String> whereClauses = ['exercise_name = ?'];
    final List<dynamic> whereArgs = [exerciseName];
    if (routineDayId != null) {
      whereClauses.add('routine_day_id = ?');
      whereArgs.add(routineDayId);
    }
    if (scheduledDate != null) {
      whereClauses.add('scheduled_date = ?');
      whereArgs.add(scheduledDate);
    }

    await db.update(
      'routine_exercises',
      {'is_completed': 1},
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  /// Consulta el historial de generaciones de IA (prompts y respuestas)
  Future<List<AiGenerationRecord>> getAiGenerationHistory() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'ai_generations',
      orderBy: 'created_at DESC',
    );
    return results.map((m) => AiGenerationRecord.fromMap(m)).toList();
  }

  /// Obtiene el plan activo actual desde SQLite o null si no hay ninguno
  Future<Map<String, dynamic>?> getActivePlan() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'routine_plans',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  static DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
