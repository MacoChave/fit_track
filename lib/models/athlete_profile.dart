import 'dart:convert';

/// Perfil de atleta y equipamiento con cálculos biométricos reactivos (RN-01, RN-02, RN-05, RN-06).
class AthleteProfile {
  final String athleteId;
  final String biologicalSex; // 'M' o 'F'
  final int age; // 14 a 90
  final String massUnit; // 'lb' o 'kg'
  final double weightInLb; // Almacenado normalizado en lb
  final double heightInCm; // Altura en cm
  final int sessionTimeMinutes; // 30, 45 o 60
  final List<bool> activeDays; // 7 días: [L, M, X, J, V, S, D]
  final Map<String, bool> equipmentInventory;
  final double dumbbellMaxWeightKg;
  final String primaryGoal; // 'FAT_LOSS', 'HYPERTROPHY', 'STRENGTH'
  final List<String> secondaryPriorities;

  const AthleteProfile({
    this.athleteId = 'ATLETA-36A',
    this.biologicalSex = 'M',
    this.age = 36,
    this.massUnit = 'lb',
    this.weightInLb = 182.0,
    this.heightInCm = 170.0,
    this.sessionTimeMinutes = 45,
    this.activeDays = const [false, true, true, true, true, true, false],
    this.equipmentInventory = const {
      'adjustable_dumbbells': true,
      'bodyweight': true,
      'ab_wheel': true,
      'resistance_bands': true,
      'barbell': false,
      'incline_bench': false,
    },
    this.dumbbellMaxWeightKg = 24.0,
    this.primaryGoal = 'FAT_LOSS',
    this.secondaryPriorities = const ['CARDIO', 'CORE'],
  });

  /// Perfil limpio para cuando no existen registros en SQLite (base de datos limpia)
  factory AthleteProfile.empty() {
    return const AthleteProfile(
      athleteId: 'SIN-ASIGNAR',
      biologicalSex: 'M',
      age: 25,
      massUnit: 'kg',
      weightInLb: 154.32358, // 70.0 kg
      heightInCm: 170.0,
      sessionTimeMinutes: 45,
      activeDays: [false, false, false, false, false, false, false],
      equipmentInventory: {
        'adjustable_dumbbells': false,
        'bodyweight': true,
        'ab_wheel': false,
        'resistance_bands': false,
        'barbell': false,
        'incline_bench': false,
      },
      dumbbellMaxWeightKg: 10.0,
      primaryGoal: 'FAT_LOSS',
      secondaryPriorities: [],
    );
  }

  /// Conversión de peso
  double get weightInKg => weightInLb * 0.45359237;

  double get displayWeight => massUnit == 'lb' ? weightInLb : weightInKg;

  double get displayEquivalentWeight => massUnit == 'lb' ? weightInKg : weightInLb;

  String get displayEquivalentUnit => massUnit == 'lb' ? 'kg' : 'lb';

  /// Cálculo del Índice de Masa Corporal (IMC)
  double get bmi {
    final heightInM = heightInCm / 100.0;
    if (heightInM <= 0) return 0.0;
    return weightInKg / (heightInM * heightInM);
  }

  /// Clasificación de IMC orientada a atletas
  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Bajo Peso';
    if (value < 25.0) return 'Normopeso';
    if (value < 30.0) return 'Sobrepeso / Masa Muscular';
    return 'Obesidad';
  }

  /// Tasa Metabólica Basal (TMB) calculada mediante Harris-Benedict (versión Roza y Shizgal)
  int get bmr {
    final w = weightInKg;
    final h = heightInCm;
    final a = age.toDouble();

    double result;
    if (biologicalSex == 'M') {
      result = 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
    } else {
      result = 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a);
    }
    return result.round();
  }

  /// Gasto Energético Total Diario (TDEE) para nivel de actividad moderada (x 1.375)
  int get tdee {
    return (bmr * 1.35).round();
  }

  int get activeDaysCount => activeDays.where((d) => d).length;

  int get activeEquipmentCount =>
      equipmentInventory.values.where((active) => active).length;

  AthleteProfile copyWith({
    String? athleteId,
    String? biologicalSex,
    int? age,
    String? massUnit,
    double? weightInLb,
    double? heightInCm,
    int? sessionTimeMinutes,
    List<bool>? activeDays,
    Map<String, bool>? equipmentInventory,
    double? dumbbellMaxWeightKg,
    String? primaryGoal,
    List<String>? secondaryPriorities,
  }) {
    return AthleteProfile(
      athleteId: athleteId ?? this.athleteId,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      age: age ?? this.age,
      massUnit: massUnit ?? this.massUnit,
      weightInLb: weightInLb ?? this.weightInLb,
      heightInCm: heightInCm ?? this.heightInCm,
      sessionTimeMinutes: sessionTimeMinutes ?? this.sessionTimeMinutes,
      activeDays: activeDays ?? List<bool>.from(this.activeDays),
      equipmentInventory: equipmentInventory ?? Map<String, bool>.from(this.equipmentInventory),
      dumbbellMaxWeightKg: dumbbellMaxWeightKg ?? this.dumbbellMaxWeightKg,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      secondaryPriorities: secondaryPriorities ?? List<String>.from(this.secondaryPriorities),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'biologicalSex': biologicalSex,
      'age': age,
      'massUnit': massUnit,
      'weightInLb': weightInLb,
      'heightInCm': heightInCm,
      'sessionTimeMinutes': sessionTimeMinutes,
      'activeDays': activeDays,
      'equipmentInventory': equipmentInventory,
      'dumbbellMaxWeightKg': dumbbellMaxWeightKg,
      'primaryGoal': primaryGoal,
      'secondaryPriorities': secondaryPriorities,
    };
  }

  factory AthleteProfile.fromMap(Map<String, dynamic> map) {
    return AthleteProfile(
      athleteId: map['athleteId'] as String? ?? 'ATLETA-36A',
      biologicalSex: map['biologicalSex'] as String? ?? 'M',
      age: (map['age'] as num?)?.toInt() ?? 36,
      massUnit: map['massUnit'] as String? ?? 'lb',
      weightInLb: (map['weightInLb'] as num?)?.toDouble() ?? 182.0,
      heightInCm: (map['heightInCm'] as num?)?.toDouble() ?? 170.0,
      sessionTimeMinutes: (map['sessionTimeMinutes'] as num?)?.toInt() ?? 45,
      activeDays: (map['activeDays'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [false, true, true, true, true, true, false],
      equipmentInventory: (map['equipmentInventory'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          const {
            'adjustable_dumbbells': true,
            'bodyweight': true,
            'ab_wheel': true,
            'resistance_bands': true,
            'barbell': false,
            'incline_bench': false,
          },
      dumbbellMaxWeightKg: (map['dumbbellMaxWeightKg'] as num?)?.toDouble() ?? 24.0,
      primaryGoal: map['primaryGoal'] as String? ?? 'FAT_LOSS',
      secondaryPriorities: (map['secondaryPriorities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['CARDIO', 'CORE'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AthleteProfile.fromJson(String source) =>
      AthleteProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
