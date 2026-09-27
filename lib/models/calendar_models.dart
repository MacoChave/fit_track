import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum DayStatusType {
  completed,
  today,
  pending,
  activeRest,
  recovery,
}

class ExerciseItem {
  final String order;
  final String name;
  final String description;
  final String? durationOrReps;
  final String? seriesAndReps;
  final int? restSeconds;
  final double? weightKg;
  final bool isBodyweight;
  final String? technicalNote;
  final bool isCompleted;

  const ExerciseItem({
    required this.order,
    required this.name,
    required this.description,
    this.durationOrReps,
    this.seriesAndReps,
    this.restSeconds,
    this.weightKg,
    this.isBodyweight = false,
    this.technicalNote,
    this.isCompleted = false,
  });
}

class ExerciseBlock {
  final int blockNumber;
  final String title;
  final int durationMinutes;
  final Color indicatorColor;
  final List<ExerciseItem> exercises;

  const ExerciseBlock({
    required this.blockNumber,
    required this.title,
    required this.durationMinutes,
    required this.indicatorColor,
    required this.exercises,
  });
}

class MealItem {
  final String id;
  final String name;
  final String description;
  final int calories;
  final int proteinGrams;
  bool isCompleted;

  MealItem({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.proteinGrams,
    this.isCompleted = false,
  });

  MealItem copyWith({bool? isCompleted}) {
    return MealItem(
      id: id,
      name: name,
      description: description,
      calories: calories,
      proteinGrams: proteinGrams,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class DaySchedule {
  final String dayLetter; // L, M, X, J, V, S, D
  final int dayNumber; // 21, 22, 23...
  final DayStatusType statusType;
  final String sessionTitle;
  final String sessionNumberLabel;
  final int durationMinutes;
  final int blockCount;
  final String equipmentSummary;
  final int rpe;
  final List<ExerciseBlock> blocks;
  final int targetCalories;
  int loggedCalories;
  final int targetProteinGrams;
  int loggedProteinGrams;
  final double targetWaterLiters;
  double loggedWaterLiters;
  List<MealItem> meals;

  DaySchedule({
    required this.dayLetter,
    required this.dayNumber,
    required this.statusType,
    required this.sessionTitle,
    required this.sessionNumberLabel,
    required this.durationMinutes,
    required this.blockCount,
    required this.equipmentSummary,
    required this.rpe,
    required this.blocks,
    required this.targetCalories,
    required this.loggedCalories,
    required this.targetProteinGrams,
    required this.loggedProteinGrams,
    required this.targetWaterLiters,
    required this.loggedWaterLiters,
    required this.meals,
  });

  static List<DaySchedule> getWeekData() {
    return [
      // Lunes 21: Completado
      DaySchedule(
        dayLetter: 'L',
        dayNumber: 21,
        statusType: DayStatusType.completed,
        sessionTitle: 'Fuerza Superior & Core',
        sessionNumberLabel: 'Sesión 01/05',
        durationMinutes: 45,
        blockCount: 3,
        equipmentSummary: 'Mancuernas',
        rpe: 8,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 1850,
        targetProteinGrams: 145,
        loggedProteinGrams: 145,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 3.0,
        meals: [],
      ),
      // Martes 22: Hoy / Activo (Empuje y Densidad Metabólica)
      DaySchedule(
        dayLetter: 'M',
        dayNumber: 22,
        statusType: DayStatusType.today,
        sessionTitle: 'Empuje y Densidad Metabólica',
        sessionNumberLabel: 'Sesión 02/05',
        durationMinutes: 40,
        blockCount: 3,
        equipmentSummary: 'Manc. + Peso C.',
        rpe: 8,
        blocks: const [
          ExerciseBlock(
            blockNumber: 1,
            title: 'Bloque 1 · Calentamiento',
            durationMinutes: 5,
            indicatorColor: AppColors.accentWater,
            exercises: [
              ExerciseItem(
                order: '01',
                name: 'Rotaciones articulares',
                description: 'Hombros, muñecas y tórax',
                durationOrReps: '60s',
              ),
              ExerciseItem(
                order: '02',
                name: 'Sentadilla libre',
                description: 'Activación pélvica dinámica',
                durationOrReps: '15 reps',
              ),
            ],
          ),
          ExerciseBlock(
            blockNumber: 2,
            title: 'Bloque 2 · Fuerza Base',
            durationMinutes: 25,
            indicatorColor: AppColors.accentEnergy,
            exercises: [
              ExerciseItem(
                order: '01',
                name: 'Press de pecho con mancuernas',
                description: 'Press plano de alta tensión',
                seriesAndReps: '3 Series × 10 Reps',
                restSeconds: 60,
                weightKg: 22.0,
                technicalNote:
                    'Nota técnica: Mantener retracción escapular y 2s controlados en la bajada.',
              ),
              ExerciseItem(
                order: '02',
                name: 'Flexiones declinadas',
                description: 'Énfasis en haz clavicular',
                seriesAndReps: '3 Series × 12 Reps',
                restSeconds: 45,
                isBodyweight: true,
              ),
            ],
          ),
          ExerciseBlock(
            blockNumber: 3,
            title: 'Bloque 3 · Finisher & Core',
            durationMinutes: 4,
            indicatorColor: AppColors.accentRpe,
            exercises: [
              ExerciseItem(
                order: '01',
                name: 'Tabata Mountain Climbers',
                description: '8 intervalos: 20s Max Esfuerzo / 10s Pausa',
                durationOrReps: '240s',
              ),
            ],
          ),
        ],
        targetCalories: 1900,
        loggedCalories: 1420,
        targetProteinGrams: 145,
        loggedProteinGrams: 110,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 2.25,
        meals: [
          MealItem(
            id: 'breakfast',
            name: 'Desayuno',
            description: 'Omelette 3 huevos con espinacas y avena',
            calories: 420,
            proteinGrams: 32,
            isCompleted: true,
          ),
          MealItem(
            id: 'lunch',
            name: 'Almuerzo',
            description: 'Pechuga a la plancha con arroz integral y brócoli',
            calories: 580,
            proteinGrams: 48,
            isCompleted: true,
          ),
          MealItem(
            id: 'snack',
            name: 'Merienda',
            description: 'Batido de proteína con frutos rojos',
            calories: 220,
            proteinGrams: 30,
            isCompleted: false,
          ),
          MealItem(
            id: 'dinner',
            name: 'Cena',
            description: 'Pescado blanco al horno con batata',
            calories: 450,
            proteinGrams: 35,
            isCompleted: false,
          ),
        ],
      ),
      // Miércoles 23: Tracción
      DaySchedule(
        dayLetter: 'X',
        dayNumber: 23,
        statusType: DayStatusType.pending,
        sessionTitle: 'Tracción e Isquiosurales',
        sessionNumberLabel: 'Sesión 03/05',
        durationMinutes: 45,
        blockCount: 3,
        equipmentSummary: 'Mancuernas + Bandas',
        rpe: 8,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 0,
        targetProteinGrams: 145,
        loggedProteinGrams: 0,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 0.0,
        meals: [],
      ),
      // Jueves 24: Pierna
      DaySchedule(
        dayLetter: 'J',
        dayNumber: 24,
        statusType: DayStatusType.pending,
        sessionTitle: 'Pierna y Glúteo Unilateral',
        sessionNumberLabel: 'Sesión 04/05',
        durationMinutes: 40,
        blockCount: 3,
        equipmentSummary: 'Mancuernas',
        rpe: 8,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 0,
        targetProteinGrams: 145,
        loggedProteinGrams: 0,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 0.0,
        meals: [],
      ),
      // Viernes 25: Full Body
      DaySchedule(
        dayLetter: 'V',
        dayNumber: 25,
        statusType: DayStatusType.pending,
        sessionTitle: 'Full Body Metabólico',
        sessionNumberLabel: 'Sesión 05/05',
        durationMinutes: 45,
        blockCount: 3,
        equipmentSummary: 'Manc. + Bandas',
        rpe: 9,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 0,
        targetProteinGrams: 145,
        loggedProteinGrams: 0,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 0.0,
        meals: [],
      ),
      // Sábado 26: Descanso Activo
      DaySchedule(
        dayLetter: 'S',
        dayNumber: 26,
        statusType: DayStatusType.activeRest,
        sessionTitle: 'Caminata 8k + Movilidad',
        sessionNumberLabel: 'Descanso Activo',
        durationMinutes: 45,
        blockCount: 1,
        equipmentSummary: 'Ninguno',
        rpe: 4,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 0,
        targetProteinGrams: 145,
        loggedProteinGrams: 0,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 0.0,
        meals: [],
      ),
      // Domingo 27: Recuperación
      DaySchedule(
        dayLetter: 'D',
        dayNumber: 27,
        statusType: DayStatusType.recovery,
        sessionTitle: 'Recuperación y Carga Semanal',
        sessionNumberLabel: 'Descanso Total',
        durationMinutes: 0,
        blockCount: 0,
        equipmentSummary: 'Ninguno',
        rpe: 1,
        blocks: const [],
        targetCalories: 1900,
        loggedCalories: 0,
        targetProteinGrams: 145,
        loggedProteinGrams: 0,
        targetWaterLiters: 3.0,
        loggedWaterLiters: 0.0,
        meals: [],
      ),
    ];
  }
}
