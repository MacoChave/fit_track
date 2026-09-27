enum WorkoutSetStatus {
  completed,
  active,
  pending,
}

class WorkoutSet {
  final int setNumber;
  final int targetReps;
  final double targetWeightKg;
  int actualReps;
  double actualWeightKg;
  double targetRpe;
  double actualRpe;
  WorkoutSetStatus status;
  String? notes;

  WorkoutSet({
    required this.setNumber,
    required this.targetReps,
    required this.targetWeightKg,
    required this.actualReps,
    required this.actualWeightKg,
    required this.targetRpe,
    required this.actualRpe,
    this.status = WorkoutSetStatus.pending,
    this.notes,
  });

  WorkoutSet copyWith({
    int? setNumber,
    int? targetReps,
    double? targetWeightKg,
    int? actualReps,
    double? actualWeightKg,
    double? targetRpe,
    double? actualRpe,
    WorkoutSetStatus? status,
    String? notes,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      actualReps: actualReps ?? this.actualReps,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      targetRpe: targetRpe ?? this.targetRpe,
      actualRpe: actualRpe ?? this.actualRpe,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class LiveExerciseSession {
  final String exerciseName;
  final String prescription;
  final String rirTarget;
  final int restSeconds;
  final List<WorkoutSet> sets;

  LiveExerciseSession({
    required this.exerciseName,
    required this.prescription,
    required this.rirTarget,
    required this.restSeconds,
    required this.sets,
  });

  static LiveExerciseSession getSampleSession() {
    return LiveExerciseSession(
      exerciseName: 'Press de pecho con mancuernas',
      prescription: '10 reps @ 22kg/mancuerna',
      rirTarget: 'RIR 2-3',
      restSeconds: 48,
      sets: [
        WorkoutSet(
          setNumber: 1,
          targetReps: 10,
          targetWeightKg: 22.0,
          actualReps: 10,
          actualWeightKg: 22.0,
          targetRpe: 7.5,
          actualRpe: 7.5,
          status: WorkoutSetStatus.completed,
          notes: 'RPE 7.5 · RIR 2-3',
        ),
        WorkoutSet(
          setNumber: 2,
          targetReps: 10,
          targetWeightKg: 22.0,
          actualReps: 10,
          actualWeightKg: 22.0,
          targetRpe: 8.0,
          actualRpe: 8.0,
          status: WorkoutSetStatus.active,
          notes: 'Retracción escapular sólida, cadencia 2-0-1-0 limpia',
        ),
        WorkoutSet(
          setNumber: 3,
          targetReps: 10,
          targetWeightKg: 24.0,
          actualReps: 10,
          actualWeightKg: 24.0,
          targetRpe: 8.5,
          actualRpe: 8.5,
          status: WorkoutSetStatus.pending,
          notes: 'Prescrito · RPE 8.5',
        ),
      ],
    );
  }

  static const Map<int, String> rpeDescriptions = {
    1: 'RPE 1: Esfuerzo prácticamente nulo, recuperación activa pasiva.',
    2: 'RPE 2: Esfuerzo sumamente ligero, calentamiento sin fatiga.',
    3: 'RPE 3: Carga muy baja, ritmo fluido y sin resistencia articular.',
    4: 'RPE 4: Inicio de calentamiento específico, velocidad máxima.',
    5: 'RPE 5: Serie de aproximación, quedan más de 5 reps en recámara.',
    6: 'RPE 6: RIR 4. Velocidad alta sostenida, calentamiento final.',
    7: 'RPE 7: RIR 3. Inicio de estímulo hipertrófico efectivo.',
    8: 'RPE 8: RIR 2. Esfuerzo óptimo para ganancia de masa muscular y fuerza.',
    9: 'RPE 9: RIR 1. Máxima cercanía al fallo seguro sin degradar técnica.',
    10: 'RPE 10: RIR 0. Fallo concéntrico absoluto, 0 repeticiones restantes.',
  };
}
