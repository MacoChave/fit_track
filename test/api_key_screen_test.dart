import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/screens/api_key_config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ApiKeyConfigScreen renders BYOK controls, providers, and security badges', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Establecer resolución móvil adecuada para la pantalla completa
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeyConfigScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Validar encabezados y badges de hardware
    expect(find.text('FITTRACK AI'), findsOneWidget);
    expect(find.text('AES-256 ZERO-SERVER'), findsOneWidget);
    expect(find.textContaining('CONFIGURACIÓN IA'), findsOneWidget);

    // Validar selector de proveedores
    expect(find.text('Gemini'), findsOneWidget);
    expect(find.text('GPT-4o'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('RECOMENDADO'), findsOneWidget);

    // Validar campo de API Key y nota de seguridad RN-03
    expect(find.text('CLAVE DE API (API KEY)'), findsOneWidget);
    expect(find.textContaining('RN-03:', findRichText: true), findsOneWidget);

    // Validar botón de ping test
    expect(find.text('PROBAR CONEXIÓN (PING TEST LIVE)'), findsOneWidget);

    // Probar conexión ingresando clave
    await tester.enterText(find.byType(TextField).first, 'AIzaSyA8B7C6D5E4F3G2H1I0J9K8L7M6N5O4P3Q');
    await tester.tap(find.text('PROBAR CONEXIÓN (PING TEST LIVE)'));
    await tester.pumpAndSettle();

    // Validar tarjeta de resultado de ping test (TC-01)
    expect(find.textContaining('HTTP 200 OK'), findsOneWidget);
    expect(find.text('TC-01 PASSED'), findsOneWidget);
    expect(find.text('LATENCIA ROUND-TRIP'), findsOneWidget);
    expect(find.text('CUOTA DISPONIBLE'), findsOneWidget);

    // Validar parámetros de rutina (RN-05)
    expect(find.text('OPTIMIZAR DURACIÓN DE SESIÓN (RN-05)'), findsOneWidget);
    expect(find.text('30 MINUTOS'), findsOneWidget);
    expect(find.text('45 MINUTOS'), findsOneWidget);
    expect(find.text('CIENTÍFICO / PRECISO'), findsOneWidget);
    expect(find.text('ADAPTATIVO / VARIADO'), findsOneWidget);

    // Validar botón de persistir credencial
    expect(find.text('GUARDAR CONFIGURACIÓN EN SQLITE'), findsOneWidget);

    // Validar transparencia y obtención de clave
    expect(find.text('TRANSPARENCIA & MODELO BYOK'), findsOneWidget);
    expect(find.textContaining('Google AI Studio'), findsWidgets);
  });
}
