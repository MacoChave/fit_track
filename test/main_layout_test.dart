import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/widgets/main_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MainLayout Widget Tests', () {
    testWidgets('Renders toolbar, child content and default surface background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(
            title: 'FITTRACK AI',
            subtitle: 'TEST SUBTITLE',
            child: Text('Main Content Here'),
          ),
        ),
      );

      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('TEST SUBTITLE'), findsOneWidget);
      expect(find.text('Main Content Here'), findsOneWidget);
    });

    testWidgets('Renders bottom navigation bar when currentNavIndex and callback provided', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: MainLayout(
            subtitle: 'CALENDARIO',
            currentNavIndex: 0,
            onNavIndexChanged: (idx) => tappedIndex = idx,
            child: const SizedBox(),
          ),
        ),
      );

      expect(find.text('CALENDARIO'), findsNWidgets(2)); // En Header y BottomNav
      expect(find.text('NUTRICIÓN'), findsOneWidget);
      expect(find.text('AJUSTES'), findsOneWidget);

      await tester.tap(find.text('NUTRICIÓN'));
      await tester.pump();

      expect(tappedIndex, equals(1));
    });

    testWidgets('Hides app bar and bottom nav when flags are disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(
            showAppBar: false,
            showBottomNavBar: false,
            child: Text('Minimal Content'),
          ),
        ),
      );

      expect(find.text('Minimal Content'), findsOneWidget);
      expect(find.text('FITTRACK AI'), findsNothing);
      expect(find.text('CALENDARIO'), findsNothing);
    });

    testWidgets('Renders floating action button if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainLayout(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            child: const Text('With FAB'),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With FAB'), findsOneWidget);
    });
  });
}
