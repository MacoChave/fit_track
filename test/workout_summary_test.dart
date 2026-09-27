import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/workout_summary_models.dart';
import 'package:fit_track/screens/workout_summary_screen.dart';

void main() {
  group('Workout Summary Models Test', () {
    test('Sample summary generates complete telemetry and KPIs', () {
      final summary = WorkoutSummaryData.getSampleSummary();

      expect(summary.sessionTitle, 'Empuje y Densidad Metabólica');
      expect(summary.dayDate, 'MARTES 22');
      expect(summary.adherencePercent, 100);
      expect(summary.recordHeadline, contains('+2 kg'));

      // KPIs
      expect(summary.kpis.totalVolumeKg, 4180);
      expect(summary.kpis.volumeTrendPercent, 8.5);
      expect(summary.kpis.durationFormatted, '41:15');
      expect(summary.kpis.targetDurationMinutes, 40);
      expect(summary.kpis.restEfficiencyPercent, 98);
      expect(summary.kpis.averageRpe, 7.8);
      expect(summary.kpis.completedSets, 12);
      expect(summary.kpis.totalSets, 12);

      // RPE Bars
      expect(summary.rpeBars.length, 8);
      expect(summary.rpeBars[0].label, 'S1');
      expect(summary.rpeBars[0].rpe, 7.0);
      expect(summary.rpeBars[2].isPr, isTrue);
      expect(summary.rpeBars[7].isHiit, isTrue);
      expect(summary.rpeBars[7].rpe, 9.0);

      // Blocks
      expect(summary.blocks.length, 3);
      expect(summary.blocks[0].title, contains('MOVILIDAD'));
      expect(summary.blocks[1].title, contains('FUERZA BASE'));
      expect(summary.blocks[1].exercises.length, 2);
      expect(summary.blocks[2].title, contains('FINISHER'));

      // Recovery
      expect(summary.recovery.hydrationMl, 750);
      expect(summary.recovery.proteinGrams, 35);
      expect(summary.recovery.proteinWindowMinutes, 60);

      // Mood & Cardiac
      expect(summary.moodOptions.length, 4);
      expect(summary.heartRateRecoveryText, contains('-32 BPM'));
    });

    test('RpeBarItem computes valid heightFactor', () {
      const bar1 = RpeBarItem(label: 'S1', rpe: 8.0);
      expect(bar1.heightFactor, 0.8);

      const bar2 = RpeBarItem(label: 'S2', rpe: 10.0);
      expect(bar2.heightFactor, 1.0);

      const bar3 = RpeBarItem(label: 'S3', rpe: 0.0);
      expect(bar3.heightFactor, 0.1); // clamped
    });
  });

  group('WorkoutSummaryScreen Widget Tests', () {
    testWidgets('Renders all milestone, telemetry, and breakdown sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSummaryScreen(),
        ),
      );
      await tester.pump();

      // Top Header
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('RESUMEN'), findsOneWidget);
      expect(find.text('SYNC'), findsOneWidget);

      // Celebration Milestone
      expect(find.text('SESIÓN COMPLETADA · MARTES 22'), findsOneWidget);
      expect(find.text('LOCAL DB'), findsOneWidget);
      expect(find.text('Empuje y Densidad Metabólica'), findsOneWidget);
      expect(find.text('🔥 100% ADHERENCIA'), findsOneWidget);
      expect(find.text('Nuevo récord en Press con mancuernas (+2 kg)'), findsOneWidget);

      // Core Telemetry KPI Grid
      expect(find.text('VOLUMEN TOTAL'), findsOneWidget);
      expect(find.text('4180'), findsOneWidget);
      expect(find.text('+8.5% vs sem. ant.'), findsOneWidget);
      expect(find.text('DURACIÓN'), findsOneWidget);
      expect(find.text('41:15'), findsOneWidget);
      expect(find.text('RPE PROMEDIO'), findsOneWidget);
      expect(find.text('7.8'), findsOneWidget);
      expect(find.text('Zona Hipertrofia'), findsOneWidget);
      expect(find.text('SERIES TOTALES'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // RPE Distribution Bar Chart
      expect(find.text('DISTRIBUCIÓN RPE POR SERIE'), findsOneWidget);
      expect(find.text('TARGET SWEET SPOT'), findsOneWidget);
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('HIIT'), findsOneWidget);

      // Blocks & Exercises Breakdown
      expect(find.text('DESGLOSE DE EJECUCIÓN'), findsOneWidget);
      expect(find.text('3/3 BLOQUES'), findsOneWidget);
      expect(find.text('BLOQUE 1 · MOVILIDAD & CALENTAMIENTO'), findsOneWidget);
      expect(find.text('BLOQUE 2 · FUERZA BASE (HIPERTROFIA)'), findsOneWidget);
      expect(find.text('Press de pecho con mancuernas'), findsOneWidget);
      expect(find.text('Flexiones declinadas'), findsOneWidget);
      expect(find.text('BLOQUE 3 · FINISHER METABÓLICO'), findsOneWidget);

      // AI Motor Analysis & Recovery
      expect(find.text('Análisis Motor IA (Edge BYOK)'), findsOneWidget);
      expect(find.text('9.4/10 TÉCNICA'), findsOneWidget);
      expect(find.text('+750 ml agua'), findsOneWidget);
      expect(find.text('35g proteína <60m'), findsOneWidget);

      // Subjective Mood & Cardiac
      expect(find.text('¿Cómo te sientes post-sesión?'), findsOneWidget);
      expect(find.text('FEEDBACK RIR'), findsOneWidget);
      expect(find.text('Energizado 💪'), findsOneWidget);
      expect(find.text('Exhausto ⚡'), findsOneWidget);
      expect(find.text('Satisfecho 🎯'), findsOneWidget);
      expect(find.text('Sobrecargado ⚠️'), findsOneWidget);
      expect(
        find.text('RITMO CARDÍACO REGISTRADO: RECUPERACIÓN ÓPTIMA (-32 BPM EN 2 MIN)'),
        findsOneWidget,
      );

      // Actions
      expect(find.text('GUARDAR EN HISTORIAL SQLITE Y SALIR'), findsOneWidget);
      expect(find.text('COMPARTIR'), findsOneWidget);
      expect(find.text('CALENDARIO'), findsWidgets);
    });

    testWidgets('Selects post-session subjective mood chip', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSummaryScreen(),
        ),
      );
      await tester.pump();

      // Tap 'Exhausto ⚡' chip (index 1)
      final exhaustoChip = find.byKey(const Key('mood_chip_1'));
      expect(exhaustoChip, findsOneWidget);

      await tester.tap(exhaustoChip);
      await tester.pump();

      // Verify chip tapped without errors
      expect(find.text('Exhausto ⚡'), findsOneWidget);
    });

    testWidgets('Persists workout to SQLite on primary action tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSummaryScreen(),
        ),
      );
      await tester.pump();

      final saveButton = find.text('GUARDAR EN HISTORIAL SQLITE Y SALIR');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump(); // Start saving

      // Button enters loading / persisting state (renders spinner)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance timer for simulated async save
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 700));

      // Button reflects completed state
      expect(find.text('¡REGISTRO CONFIRMADO EN SQLITE!'), findsOneWidget);

      // SnackBar displayed
      expect(
        find.text('¡Sesión persistida con éxito en SQLite offline! Mesociclo actualizado.'),
        findsOneWidget,
      );
    });
  });
}
