class RpeBarItem {
  final String label; // e.g., 'S1', 'S2', 'HIIT'
  final double rpe; // e.g., 7.0, 7.5, 8.0, 9.0
  final bool isPr;
  final bool isHiit;

  const RpeBarItem({
    required this.label,
    required this.rpe,
    this.isPr = false,
    this.isHiit = false,
  });

  // Altura relativa para un gráfico con escala de 0 a 10
  double get heightFactor => (rpe / 10.0).clamp(0.1, 1.0);
}

class SessionKpis {
  final int totalVolumeKg;
  final double volumeTrendPercent;
  final String durationFormatted;
  final int targetDurationMinutes;
  final int restEfficiencyPercent;
  final double averageRpe;
  final int completedSets;
  final int totalSets;
  final int executedBlocks;

  const SessionKpis({
    required this.totalVolumeKg,
    required this.volumeTrendPercent,
    required this.durationFormatted,
    required this.targetDurationMinutes,
    required this.restEfficiencyPercent,
    required this.averageRpe,
    required this.completedSets,
    required this.totalSets,
    required this.executedBlocks,
  });
}

class SetPerformanceChip {
  final String setLabel; // 'SET 1', 'SET 2', 'SET 3 (PR)'
  final String summaryText; // '10 × 22kg', '12 reps'
  final bool isPr;

  const SetPerformanceChip({
    required this.setLabel,
    required this.summaryText,
    this.isPr = false,
  });
}

class SummaryExercise {
  final String name;
  final String? badgeText; // 'PR +2 KG', 'Peso Corporal'
  final String rpeLabel; // 'RPE 8.0', '· RPE 7.5'
  final int completedSets;
  final int totalSets;
  final List<SetPerformanceChip> sets;

  const SummaryExercise({
    required this.name,
    this.badgeText,
    required this.rpeLabel,
    required this.completedSets,
    required this.totalSets,
    required this.sets,
  });
}

enum SummaryBlockTheme {
  mobility,
  strength,
  finisher,
}

class SummaryBlock {
  final int blockNumber;
  final String title;
  final SummaryBlockTheme theme;
  final String durationText;
  final String? singleLineDescription;
  final String? singleLineStatus;
  final List<SummaryExercise> exercises;

  const SummaryBlock({
    required this.blockNumber,
    required this.title,
    required this.theme,
    required this.durationText,
    this.singleLineDescription,
    this.singleLineStatus,
    this.exercises = const [],
  });
}

class RecoveryPrescription {
  final int hydrationMl;
  final int proteinGrams;
  final int proteinWindowMinutes;

  const RecoveryPrescription({
    required this.hydrationMl,
    required this.proteinGrams,
    required this.proteinWindowMinutes,
  });
}

class WorkoutSummaryData {
  final String sessionTitle;
  final String dayDate;
  final String mesocycleInfo;
  final int adherencePercent;
  final String recordHeadline;
  final String recordDescription;
  final SessionKpis kpis;
  final List<RpeBarItem> rpeBars;
  final List<SummaryBlock> blocks;
  final String motorScore;
  final String motorFeedback;
  final RecoveryPrescription recovery;
  final List<String> moodOptions;
  final String heartRateRecoveryText;

  const WorkoutSummaryData({
    required this.sessionTitle,
    required this.dayDate,
    required this.mesocycleInfo,
    required this.adherencePercent,
    required this.recordHeadline,
    required this.recordDescription,
    required this.kpis,
    required this.rpeBars,
    required this.blocks,
    required this.motorScore,
    required this.motorFeedback,
    required this.recovery,
    required this.moodOptions,
    required this.heartRateRecoveryText,
  });

  static WorkoutSummaryData getSampleSummary() {
    return const WorkoutSummaryData(
      sessionTitle: 'Empuje y Densidad Metabólica',
      dayDate: 'MARTES 22',
      mesocycleInfo: 'Mesociclo 3 · Semana 2 · Sesión #14',
      adherencePercent: 100,
      recordHeadline: 'Nuevo récord en Press con mancuernas (+2 kg)',
      recordDescription:
          'Superaste el volumen estimado para este bloque con cadencia perfecta.',
      kpis: SessionKpis(
        totalVolumeKg: 4180,
        volumeTrendPercent: 8.5,
        durationFormatted: '41:15',
        targetDurationMinutes: 40,
        restEfficiencyPercent: 98,
        averageRpe: 7.8,
        completedSets: 12,
        totalSets: 12,
        executedBlocks: 3,
      ),
      rpeBars: [
        RpeBarItem(label: 'S1', rpe: 7.0),
        RpeBarItem(label: 'S2', rpe: 7.5),
        RpeBarItem(label: 'S3', rpe: 8.0, isPr: true),
        RpeBarItem(label: 'S4', rpe: 7.5),
        RpeBarItem(label: 'S5', rpe: 8.0),
        RpeBarItem(label: 'S6', rpe: 8.5, isPr: true),
        RpeBarItem(label: 'S7', rpe: 7.5),
        RpeBarItem(label: 'HIIT', rpe: 9.0, isHiit: true),
      ],
      blocks: [
        SummaryBlock(
          blockNumber: 1,
          title: 'BLOQUE 1 · MOVILIDAD & CALENTAMIENTO',
          theme: SummaryBlockTheme.mobility,
          durationText: '05:00 MIN',
          singleLineDescription:
              'Dislocaciones de hombro + Scapular push-ups',
          singleLineStatus: 'COMPLETO',
        ),
        SummaryBlock(
          blockNumber: 2,
          title: 'BLOQUE 2 · FUERZA BASE (HIPERTROFIA)',
          theme: SummaryBlockTheme.strength,
          durationText: '26:15 MIN',
          exercises: [
            SummaryExercise(
              name: 'Press de pecho con mancuernas',
              badgeText: 'PR +2 KG',
              rpeLabel: 'RPE 8.0',
              completedSets: 3,
              totalSets: 3,
              sets: [
                SetPerformanceChip(setLabel: 'SET 1', summaryText: '10 × 22kg'),
                SetPerformanceChip(setLabel: 'SET 2', summaryText: '10 × 22kg'),
                SetPerformanceChip(
                  setLabel: 'SET 3 (PR)',
                  summaryText: '10 × 22kg',
                  isPr: true,
                ),
              ],
            ),
            SummaryExercise(
              name: 'Flexiones declinadas',
              badgeText: 'Peso Corporal',
              rpeLabel: '· RPE 7.5',
              completedSets: 3,
              totalSets: 3,
              sets: [
                SetPerformanceChip(setLabel: 'SET 1', summaryText: '12 reps'),
                SetPerformanceChip(setLabel: 'SET 2', summaryText: '12 reps'),
                SetPerformanceChip(setLabel: 'SET 3', summaryText: '12 reps'),
              ],
            ),
          ],
        ),
        SummaryBlock(
          blockNumber: 3,
          title: 'BLOQUE 3 · FINISHER METABÓLICO',
          theme: SummaryBlockTheme.finisher,
          durationText: '08:00 MIN',
          singleLineDescription:
              'Tabata Mountain Climbers\n8 intervalos · 240s activos @ Máx Esfuerzo',
          singleLineStatus: 'RPE 9.0',
        ),
      ],
      motorScore: '9.4/10 TÉCNICA',
      motorFeedback:
          'Sobrecarga efectiva lograda sin comprometer la cadencia (tempo 2-0-1-0 respetado en press con mancuernas). Excelente reclutamiento de fibras pectorales sin compensación lumbar en declinadas.',
      recovery: RecoveryPrescription(
        hydrationMl: 750,
        proteinGrams: 35,
        proteinWindowMinutes: 60,
      ),
      moodOptions: [
        'Energizado 💪',
        'Exhausto ⚡',
        'Satisfecho 🎯',
        'Sobrecargado ⚠️',
      ],
      heartRateRecoveryText:
          'RITMO CARDÍACO REGISTRADO: RECUPERACIÓN ÓPTIMA (-32 BPM EN 2 MIN)',
    );
  }
}
