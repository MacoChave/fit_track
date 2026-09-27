import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders logo, title, subtitle, progress indicator and security note', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(seconds: 10), // Duración larga para verificar UI estática
            nextScreen: SizedBox(),
          ),
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('AI-POWERED ATHLETE PERFORMANCE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('LOCAL-FIRST ARCHITECTURE · ENCRYPTED'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });

    testWidgets('Transitions to next screen after duration expires', (tester) async {
      SharedPreferences.setMockInitialValues({});

      const targetKey = Key('target_screen');

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(milliseconds: 200),
            nextScreen: Scaffold(key: targetKey, body: Text('TARGET REACHED')),
          ),
        ),
      );

      expect(find.text('FITTRACK AI'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byKey(targetKey), findsOneWidget);
      expect(find.text('TARGET REACHED'), findsOneWidget);
    });
  });
}
