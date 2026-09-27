import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/widgets/app_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHeader Widget Tests', () {
    testWidgets('Renders default title, bolt icon, sync badge and avatar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(),
          ),
        ),
      );

      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('SYNC'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Renders custom title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              title: 'CUSTOM TITLE',
              subtitle: 'SUBTITLE TEST',
            ),
          ),
        ),
      );

      expect(find.text('CUSTOM TITLE'), findsOneWidget);
      expect(find.text('SUBTITLE TEST'), findsOneWidget);
    });

    testWidgets('Renders back button when showBackButton is true and triggers callback', (tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              showBackButton: true,
              onBackPressed: () {
                backPressed = true;
              },
            ),
          ),
        ),
      );

      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pump();

      expect(backPressed, isTrue);
    });

    testWidgets('Triggers onSyncPressed and onProfilePressed', (tester) async {
      bool syncTapped = false;
      bool profileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              onSyncPressed: () => syncTapped = true,
              onProfilePressed: () => profileTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('SYNC'));
      await tester.pump();
      expect(syncTapped, isTrue);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pump();
      expect(profileTapped, isTrue);
    });

    testWidgets('Supports custom actions override', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              actions: [
                Icon(Icons.settings),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('SYNC'), findsNothing);
      expect(find.byIcon(Icons.person), findsNothing);
    });
  });
}
