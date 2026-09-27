import '../models/athlete_profile.dart';

/// Compilador de prompt estandarizado para proveedores de IA (RF-IA-01, RN-05, RN-06).
/// Concatena parámetros biométricos, restricciones de tiempo, equipamiento estricto
/// y el esquema JSON requerido por la especificación DERCAS 5.2.
class AiPromptBuilder {
  static const String jsonSchemaContract = '''
{
  "plan_id": "uuid-v4",
  "semanas": 4,
  "objetivo_primario": "Perdida de Grasa y Definicion",
  "dias": [
    {
      "dia_semana": "Lunes",
      "enfoque": "Empuje y Densidad Metabolica",
      "duracion_estimada_min": 40,
      "calentamiento": [
        { "nombre": "Rotaciones articulares", "duracion_seg": 60 },
        { "nombre": "Sentadilla libre", "repeticiones": 15 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "press_mancuernas_plano",
              "nombre": "Press de pecho con mancuernas",
              "series": 3,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 60,
              "equipo_requerido": "mancuernas",
              "notas_tecnicas": "Mantener retraccion escapular y 2s en la bajada"
            }
          ]
        }
      ],
      "finisher_core": {
        "nombre": "Tabata Mountain Climbers",
        "duracion_seg": 240
      },
      "guia_nutricional": {
        "calorias_objetivo": 1900,
        "proteina_gramos": 145,
        "agua_litros": 3.0
      }
    }
  ]
}''';

  /// Construye el prompt del sistema y de usuario a partir del perfil del atleta
  static String buildPrompt(AthleteProfile profile, {int weeks = 4}) {
    final activeDaysNames = <String>[];
    const dayLabels = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    for (int i = 0; i < profile.activeDays.length && i < dayLabels.length; i++) {
      if (profile.activeDays[i]) {
        activeDaysNames.add(dayLabels[i]);
      }
    }

    final availableEquipment = profile.equipmentInventory.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return '''
Actúa como un entrenador personal de élite y nutricionista deportivo de precisión.
Genera una programación de entrenamiento y guía nutricional deportiva adaptada estrictamente al siguiente perfil de atleta:

[PARÁMETROS BIOMÉTRICOS DEL ATLETA (RF-CFG-01)]
- Sexo biológico: ${profile.biologicalSex == 'M' ? 'Masculino' : 'Femenino'}
- Edad: ${profile.age} años
- Peso actual: ${profile.weightInLb.toStringAsFixed(1)} lb (${profile.weightInKg.toStringAsFixed(1)} kg)
- Estatura: ${profile.heightInCm.toStringAsFixed(1)} cm
- IMC Calculado: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})
- Tasa Metabólica Basal (BMR): ${profile.bmr} kcal
- Gasto Energético Total Diario (TDEE estimado): ${profile.tdee} kcal
- Objetivo Principal: ${profile.primaryGoal}
- Prioridades Secundarias: ${profile.secondaryPriorities.join(', ')}

[DISPONIBILIDAD Y EQUIPAMIENTO (RN-05, RN-06)]
- Duración estricta por sesión: ${profile.sessionTimeMinutes} minutos (incluyendo 5 min de calentamiento + descansos).
- Días activos por semana (${profile.activeDaysCount}): ${activeDaysNames.join(', ')}.
- Inventario de equipamiento disponible EXCLUSIVO: ${availableEquipment.join(', ')}.
- Carga máxima en mancuernas ajustables: ${profile.dumbbellMaxWeightKg} kg por mancuerna.

[REGLAS DE NEGOCIO ESTRICTAS]
1. RN-05: El tiempo total de cada sesión DEBE ajustarse a ${profile.sessionTimeMinutes} min.
2. RN-06: PROHIBIDO prescribir ejercicios que requieran equipamiento no listado (ej. no incluir barras ni poleas si no están en el inventario). Solo usar: ${availableEquipment.join(', ')}.
3. Formato de salida: Devuelve ÚNICAMENTE un JSON válido que cumpla estrictamente con la siguiente estructura y sin texto adicional:

$jsonSchemaContract
''';
  }
}
