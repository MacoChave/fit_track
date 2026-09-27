import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/models/athlete_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_track/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AthleteProfile Model & Biometric Calculations', () {
    test('Valores por defecto coinciden con especificación Stitch', () {
      const profile = AthleteProfile();

      expect(profile.athleteId, 'ATLETA-36A');
      expect(profile.biologicalSex, 'M');
      expect(profile.age, 36);
      expect(profile.massUnit, 'lb');
      expect(profile.weightInLb, 182.0);
      expect(profile.heightInCm, 170.0);
      expect(profile.sessionTimeMinutes, 45);
      expect(profile.activeDaysCount, 5);
      expect(profile.activeEquipmentCount, 4);
      expect(profile.primaryGoal, 'FAT_LOSS');
    });

    test('Cálculo reactivo de IMC y categorías de salud deportiva', () {
      const profile = AthleteProfile(
        weightInLb: 182.0,
        heightInCm: 170.0,
      );

      // 182 lb = 82.5538 kg; 82.5538 / (1.70^2) = 28.56
      expect(profile.bmi, greaterThan(28.0));
      expect(profile.bmi, lessThan(29.0));
      expect(profile.bmiCategory, 'Sobrepeso / Masa Muscular');
    });

    test('Cálculo de TMB (Harris-Benedict v2) y TDEE', () {
      const maleProfile = AthleteProfile(
        biologicalSex: 'M',
        age: 36,
        weightInLb: 182.0,
        heightInCm: 170.0,
      );

      expect(maleProfile.bmr, greaterThan(1600));
      expect(maleProfile.bmr, lessThan(1900));
      expect(maleProfile.tdee, greaterThan(maleProfile.bmr));

      const femaleProfile = AthleteProfile(
        biologicalSex: 'F',
        age: 36,
        weightInLb: 182.0,
        heightInCm: 170.0,
      );

      expect(femaleProfile.bmr, lessThan(maleProfile.bmr));
    });

    test('Conversión de unidades y visualización equivalente', () {
      const profileLb = AthleteProfile(massUnit: 'lb', weightInLb: 182.0);
      expect(profileLb.displayWeight, 182.0);
      expect(profileLb.displayEquivalentUnit, 'kg');
      expect(profileLb.displayEquivalentWeight, closeTo(82.55, 0.1));

      const profileKg = AthleteProfile(massUnit: 'kg', weightInLb: 182.0);
      expect(profileKg.displayWeight, closeTo(82.55, 0.1));
      expect(profileKg.displayEquivalentUnit, 'lb');
      expect(profileKg.displayEquivalentWeight, 182.0);
    });

    test('Serialización y deserialización JSON completa', () {
      const original = AthleteProfile(
        athleteId: 'ATLETA-TEST-01',
        age: 28,
        sessionTimeMinutes: 60,
        primaryGoal: 'HYPERTROPHY',
      );

      final jsonString = original.toJson();
      final restored = AthleteProfile.fromJson(jsonString);

      expect(restored.athleteId, original.athleteId);
      expect(restored.age, original.age);
      expect(restored.sessionTimeMinutes, original.sessionTimeMinutes);
      expect(restored.primaryGoal, original.primaryGoal);
    });

    test('LocalStorageService guarda y recupera perfil localmente', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LocalStorageService.instance;

      const profileToSave = AthleteProfile(
        athleteId: 'ATLETA-LOCAL-99',
        age: 42,
        sessionTimeMinutes: 30,
      );

      final saved = await service.saveProfile(profileToSave);
      expect(saved, isTrue);

      final loaded = await service.getProfile();
      expect(loaded, isNotNull);
      expect(loaded!.athleteId, 'ATLETA-LOCAL-99');
      expect(loaded.age, 42);
      expect(loaded.sessionTimeMinutes, 30);
    });
  });
}
