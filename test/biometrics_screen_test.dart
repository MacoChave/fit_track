import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/athlete_profile.dart';
import 'package:fit_track/screens/biometrics_equipment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'BiometricsEquipmentScreen renders all core sections and components',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(home: BiometricsEquipmentScreen(initialProfile: AthleteProfile())),
      );
      await tester.pump();

      // Validar encabezados y títulos
      expect(find.text('FITTRACK AI'), findsOneWidget);
      expect(find.text('PERFIL Y BIOMETRÍA'), findsOneWidget);
      expect(find.text('LOCAL STORAGE ENCRYPTED'), findsOneWidget);

      // Validar secciones
      expect(find.text('1. DATOS BIOMÉTRICOS BASE'), findsOneWidget);
      expect(find.text('2. HORARIOS Y DISPONIBILIDAD'), findsOneWidget);
      expect(find.text('3. INVENTARIO DISPONIBLE'), findsOneWidget);
      expect(find.text('4. OBJETIVOS Y FOCO'), findsOneWidget);

      // Validar botón principal de acción
      expect(find.text('Guardar Perfil y Actualizar Plan IA'), findsOneWidget);

      // Validar barra de navegación (AJUSTES aparece en header y en bottom bar)
      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(find.text('NUTRICIÓN'), findsOneWidget);
      expect(find.text('AJUSTES'), findsNWidgets(2));
    },
  );
}
