import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/workout_execution_models.dart';
import 'package:fit_track/screens/workout_logging_screen.dart';

void main() {
  group('Workout Execution Models Test', () {
    test('Sample live session is generated with correct defaults', () {
      final session = LiveExerciseSession.getSampleSession();

      expect(session.exerciseName, 'Press de pecho con mancuernas');
      expect(session.sets.length, 3);

      expect(session.sets[0].status, WorkoutSetStatus.completed);
      expect(session.sets[1].status, WorkoutSetStatus.active);
      expect(session.sets[2].status, WorkoutSetStatus.pending);

      expect(session.sets[0].actualWeightKg, 22.0);
      expect(session.sets[0].actualReps, 10);
      expect(session.sets[0].actualRpe, 7.5);
    });

    test('LiveExerciseSession RPE descriptions map covers RPE 1 through 10', () {
      expect(LiveExerciseSession.rpeDescriptions.length, 10);
      expect(LiveExerciseSession.rpeDescriptions[8], contains('RPE 8: RIR 2'));
      expect(LiveExerciseSession.rpeDescriptions[9], contains('RPE 9: RIR 1'));
      expect(LiveExerciseSession.rpeDescriptions[10], contains('RPE 10: RIR 0'));
    });
  });

  group('WorkoutLoggingScreen Widget Tests', () {
    testWidgets('Renders all main sections and UI modules', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Header verification
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('REGISTRO EN VIVO'), findsOneWidget);

      // Live Status HUD
      expect(find.text('EN VIVO · SERIE 2 DE 3'), findsWidgets);
      expect(find.text('Press de pecho con mancuernas'), findsWidgets);
      expect(find.text('DESCANSO EN CURSO'), findsOneWidget);

      // Stepper & Reps
      expect(find.text('CARGA UTILIZADA (POR MANCUERNA)'), findsOneWidget);
      expect(find.text('22.0'), findsOneWidget);
      expect(find.text('REPETICIONES EJECUTADAS'), findsOneWidget);

      // RPE Scale & Feedback
      expect(find.text('ESFUERZO PERCIBIDO (RPE)'), findsOneWidget);
      expect(find.text('RPE 8.0 · RIR 2'), findsWidgets);

      // Set History & Progress
      expect(find.text('PROGRESO DE SERIES'), findsOneWidget);
      expect(find.text('COMPLETA'), findsOneWidget);
      expect(find.text('ACTUAL'), findsOneWidget);
      expect(find.text('EN ESPERA'), findsOneWidget);

      // Ergonomic confirmation button
      expect(find.text('Confirmar Serie 2 y Descansar'), findsOneWidget);
    });

    testWidgets('Adjusts weight via steppers and quick preset chips', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Initial weight: 22.0
      expect(find.text('22.0'), findsOneWidget);

      // Tap + button
      final plusBtn = find.text('+');
      await tester.tap(plusBtn);
      await tester.pump();
      expect(find.text('23.0'), findsOneWidget);

      // Tap - button
      final minusBtn = find.text('-');
      await tester.tap(minusBtn);
      await tester.pump();
      expect(find.text('22.0'), findsOneWidget);

      // Tap preset chip 24 kg
      final chip24 = find.text('24 kg');
      await tester.tap(chip24);
      await tester.pump();
      expect(find.text('24.0'), findsOneWidget);
    });

    testWidgets('RPE selection updates RIR and tactical advice', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Default RPE is 8 -> RIR 2
      expect(find.text('RPE 8.0 · RIR 2'), findsWidgets);

      // Select RPE 9 via key
      final rpe9Button = find.byKey(const Key('rpe_9'));
      await tester.tap(rpe9Button);
      await tester.pump();

      // Now RIR is 1
      expect(find.text('RPE 9.0 · RIR 1'), findsWidgets);
      expect(find.text(LiveExerciseSession.rpeDescriptions[9]!), findsOneWidget);

      // Select RPE 10 via key
      final rpe10Button = find.byKey(const Key('rpe_10'));
      await tester.tap(rpe10Button);
      await tester.pump();

      expect(find.text('RPE 10.0 · RIR 0'), findsWidgets);
      expect(find.text(LiveExerciseSession.rpeDescriptions[10]!), findsOneWidget);
    });

    testWidgets('Timer rest interaction: +30s and saltar descanso', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Initial timer starts at 00:48
      expect(find.text('00:48'), findsOneWidget);

      // Tap +30s button
      final add30Btn = find.text('30s');
      await tester.tap(add30Btn);
      await tester.pump();

      // 48 + 30 = 78s = 01:18
      expect(find.text('01:18'), findsOneWidget);

      // Tap 'OMITIR DESCANSO' button
      final skipBtn = find.text('OMITIR DESCANSO');
      await tester.tap(skipBtn);
      await tester.pump();

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Confirms set and transitions state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(fallbackToSample: true),
        ),
      );
      await tester.pump();

      // Confirm button
      final confirmBtn = find.text('Confirmar Serie 2 y Descansar');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pump();

      // SnackBar shows
      expect(find.text('¡Serie 2 registrada! Iniciando descanso previo a Serie 3.'), findsOneWidget);

      // Button updates for next series
      expect(find.text('Confirmar Serie 3 y Finalizar'), findsOneWidget);
    });

    testWidgets('Muestra estado limpio sin sesión cuando no hay datos en SQLite', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutLoggingScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('BASE DE DATOS LIMPIA'), findsOneWidget);
      expect(find.text('Ir al Calendario'), findsOneWidget);
    });
  });
}
