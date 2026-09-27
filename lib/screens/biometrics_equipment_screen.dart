import 'package:fit_track/screens/macronutrients_food_log_screen.dart';
import 'package:flutter/material.dart';

import '../models/athlete_profile.dart';
import '../services/local_storage_service.dart';
import '../services/manual_routine_importer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/main_layout.dart';
import '../widgets/equipment_tile.dart';
import '../widgets/flat_button.dart';
import '../widgets/flat_card.dart';
import '../widgets/segmented_selector.dart';
import '../widgets/stepper_control.dart';
import 'api_key_config_screen.dart';
import 'calendar_nutrition_screen.dart';

class BiometricsEquipmentScreen extends StatefulWidget {
  final AthleteProfile? initialProfile;

  const BiometricsEquipmentScreen({super.key, this.initialProfile});

  @override
  State<BiometricsEquipmentScreen> createState() =>
      _BiometricsEquipmentScreenState();
}

class _BiometricsEquipmentScreenState extends State<BiometricsEquipmentScreen> {
  late AthleteProfile _profile;
  bool _isLoading = true;
  bool _hasSavedProfileInDb = false;
  bool _isSaving = false;
  String _saveButtonText = 'Guardar Perfil y Actualizar Plan IA';
  IconData _saveButtonIcon = Icons.save;
  int _currentNavIndex = 2; // Ajustes

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile!;
      _isLoading = false;
      _hasSavedProfileInDb = true;
    } else {
      _profile = AthleteProfile.empty();
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final loaded = await LocalStorageService.instance.getProfile();
    if (mounted) {
      setState(() {
        if (loaded != null) {
          _profile = loaded;
          _hasSavedProfileInDb = true;
        } else {
          _profile = AthleteProfile.empty();
          _hasSavedProfileInDb = false;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _saveButtonText = 'Sincronizando Plan IA...';
      _saveButtonIcon = Icons.sync;
    });

    await LocalStorageService.instance.saveProfile(_profile);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasSavedProfileInDb = true;
        _saveButtonText = 'Perfil Guardado con Éxito';
        _saveButtonIcon = Icons.task_alt;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: const BorderSide(color: AppColors.accentEnergy),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.accentEnergy,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  'Datos biométricos y equipamiento persistidos en local.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _saveButtonText = 'Guardar Perfil y Actualizar Plan IA';
          _saveButtonIcon = Icons.save;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceBase,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentEnergy),
        ),
      );
    }

    return MainLayout(
      subtitle: 'AJUSTES',
      currentNavIndex: _currentNavIndex,
      onNavIndexChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CalendarNutritionScreen(),
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MacronutrientsFoodLogScreen(),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.margin,
          vertical: AppSpacing.spaceMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSafetyBadgesAndTitle(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSection1Biometrics(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSection2Availability(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSection3EquipmentInventory(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSection4TrainingGoals(),
            const SizedBox(height: AppSpacing.spaceLg),
            _buildSaveActionSection(),
            const SizedBox(height: AppSpacing.space2Xl),
          ],
        ),
      ),
    );
  }

  // --- SUBHEADER Y BADGES DE SEGURIDAD ---
  Widget _buildSafetyBadgesAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceSm + 2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${_profile.athleteId}',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: AppSpacing.roundedSm,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApiKeyConfigScreen(),
                    ),
                  );
                },
                borderRadius: AppSpacing.roundedSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spaceSm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accentEnergy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LOCAL STORAGE ENCRYPTED',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.accentEnergy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        Text(
          'PERFIL Y BIOMETRÍA',
          style: AppTypography.headlineLg.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceXs),
        Text(
          'Parámetros antropométricos y equipamiento para personalizar tus rutinas generadas por IA.',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        if (!_hasSavedProfileInDb) ...[
          const SizedBox(height: AppSpacing.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.accentEnergy,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Text(
                    'Base de datos limpia: No hay perfil en SQLite. Configura tus datos y presiona "Guardar Perfil" para persistirlos.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- SECCIÓN 1: DATOS BIOMÉTRICOS BASE (RN-01 / RN-02) ---
  Widget _buildSection1Biometrics() {
    final double displayWeightVal = _profile.displayWeight;
    final double equivWeightVal = _profile.displayEquivalentWeight;
    final String unitStr = _profile.massUnit;
    final String equivUnitStr = _profile.displayEquivalentUnit;

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la Sección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 18,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    '1. DATOS BIOMÉTRICOS BASE',
                    style: AppTypography.labelMonoMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Sexo Biológico
          Text(
            'SEXO BIOLÓGICO (CÁLCULO TMB)',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedSelector<String>(
            options: const [
              SegmentOption(value: 'M', label: 'Masculino', icon: Icons.male),
              SegmentOption(value: 'F', label: 'Femenino', icon: Icons.female),
            ],
            selectedValue: _profile.biologicalSex,
            isFilledHighContrast: false,
            height: 48,
            onSelected: (val) {
              setState(() {
                _profile = _profile.copyWith(biologicalSex: val);
              });
            },
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Fila Edad y Unidad de Masa
          Row(
            children: [
              // Edad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EDAD (AÑOS)',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '14-90',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StepperControl(
                      value: _profile.age,
                      minValue: 14,
                      maxValue: 90,
                      onChanged: (newAge) {
                        setState(() {
                          _profile = _profile.copyWith(age: newAge);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),

              // Selector Unidad de Masa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UNIDAD MASA',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SegmentedSelector<String>(
                      options: const [
                        SegmentOption(value: 'lb', label: 'LB'),
                        SegmentOption(value: 'kg', label: 'KG'),
                      ],
                      selectedValue: _profile.massUnit,
                      isFilledHighContrast: true,
                      height: AppSpacing.minTouchTarget,
                      onSelected: (unit) {
                        setState(() {
                          _profile = _profile.copyWith(massUnit: unit);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Peso Actual y Altura
          Row(
            children: [
              // Peso Actual
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm + 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PESO ACTUAL',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final delta = _profile.massUnit == 'lb'
                                      ? 1.0
                                      : (1.0 / 0.45359237);
                                  setState(() {
                                    _profile = _profile.copyWith(
                                      weightInLb: (_profile.weightInLb - delta)
                                          .clamp(60.0, 500.0),
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  final delta = _profile.massUnit == 'lb'
                                      ? 1.0
                                      : (1.0 / 0.45359237);
                                  setState(() {
                                    _profile = _profile.copyWith(
                                      weightInLb: (_profile.weightInLb + delta)
                                          .clamp(60.0, 500.0),
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            displayWeightVal
                                .toStringAsFixed(1)
                                .replaceAll('.0', ''),
                            style: AppTypography.labelMonoLg.copyWith(
                              fontSize: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unitStr,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentEnergy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '≈ ${equivWeightVal.toStringAsFixed(1)} $equivUnitStr',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),

              // Estatura
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm + 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ESTATURA',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _profile = _profile.copyWith(
                                      heightInCm: (_profile.heightInCm - 1)
                                          .clamp(100.0, 250.0),
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _profile = _profile.copyWith(
                                      heightInCm: (_profile.heightInCm + 1)
                                          .clamp(100.0, 250.0),
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _profile.heightInCm.toStringAsFixed(0),
                            style: AppTypography.labelMonoLg.copyWith(
                              fontSize: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'cm',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentEnergy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _calculateFeetInches(_profile.heightInCm),
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Panel de Métricas Calculadas en Tiempo Real
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calculate,
                          size: 16,
                          color: AppColors.accentEnergy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MÉTRICAS CALCULADAS EN TIEMPO REAL',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentEnergy,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceSm + 2),

                // IMC
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMC ESTIMADO',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              text: _profile.bmi.toStringAsFixed(1),
                              style: AppTypography.labelMonoMd.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(
                                  text: ' kg/m²',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          _profile.bmiCategory.toUpperCase(),
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.accentRpe,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceSm),

                // TMB y TDEE
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TMB (BASAL)',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                text: _formatNumber(_profile.bmr),
                                style: AppTypography.labelMonoMd.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' kcal',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.accentEnergy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Harris-Benedict v2',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TDEE (GASTO TOTAL)',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                text: _formatNumber(_profile.tdee),
                                style: AppTypography.labelMonoMd.copyWith(
                                  color: AppColors.accentEnergy,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' kcal',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Actividad Moderada',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 2: HORARIOS Y DISPONIBILIDAD (RN-05) ---
  Widget _buildSection2Availability() {
    final times = [30, 45, 60];
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    '2. HORARIOS Y DISPONIBILIDAD',
                    style: AppTypography.labelMonoMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Límite por Sesión
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LÍMITE POR SESIÓN (ESTRICTO)',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_profile.sessionTimeMinutes} MIN ACTIVO',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.accentEnergy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: times.map((t) {
              final isSelected = _profile.sessionTimeMinutes == t;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Material(
                    color: isSelected
                        ? AppColors.accentEnergy
                        : AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedMd,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _profile = _profile.copyWith(sessionTimeMinutes: t);
                        });
                      },
                      borderRadius: AppSpacing.roundedMd,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$t',
                              style: AppTypography.headlineSm.copyWith(
                                color: isSelected
                                    ? AppColors.surfaceBase
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'minutos',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: isSelected
                                    ? AppColors.surfaceBase
                                    : AppColors.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'La IA modulará volumen, tempos y descanso intra-serie para consolidar el entrenamiento dentro de la ventana seleccionada.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),

          // Días de Entrenamiento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DÍAS DE ENTRENAMIENTO',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_profile.activeDaysCount} DÍAS / SEMANA',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.accentEnergy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              final isActive = _profile.activeDays[index];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Material(
                    color: isActive
                        ? AppColors.accentEnergy
                        : AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedSm,
                    child: InkWell(
                      onTap: () {
                        final updatedDays = List<bool>.from(
                          _profile.activeDays,
                        );
                        updatedDays[index] = !updatedDays[index];
                        setState(() {
                          _profile = _profile.copyWith(activeDays: updatedDays);
                        });
                      },
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          dayNames[index],
                          style: AppTypography.headlineSm.copyWith(
                            color: isActive
                                ? AppColors.surfaceBase
                                : AppColors.textMuted,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 3: INVENTARIO DISPONIBLE (RN-06) ---
  Widget _buildSection3EquipmentInventory() {
    final inv = _profile.equipmentInventory;

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 18,
                        color: AppColors.accentEnergy,
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Text(
                        '3. INVENTARIO DISPONIBLE',
                        style: AppTypography.labelMonoMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Filtro rígido para asignación motriz',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  '${_profile.activeEquipmentCount}/6 ACTIVOS',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // 1. Mancuernas ajustables
          EquipmentTile(
            title: 'Mancuernas ajustables',
            subtitle: 'Rango de carga adaptable',
            isSelected: inv['adjustable_dumbbells'] ?? false,
            trailingIcon: Icons.tune,
            subContent: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PESO MÁX DISPONIBLE:',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_profile.dumbbellMaxWeightKg > 2.0) {
                            setState(() {
                              _profile = _profile.copyWith(
                                dumbbellMaxWeightKg:
                                    _profile.dumbbellMaxWeightKg - 2.0,
                              );
                            });
                          }
                        },
                        child: const Icon(
                          Icons.remove_circle_outline,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_profile.dumbbellMaxWeightKg.toStringAsFixed(0)} kg',
                        style: AppTypography.labelMonoMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (_profile.dumbbellMaxWeightKg < 100.0) {
                            setState(() {
                              _profile = _profile.copyWith(
                                dumbbellMaxWeightKg:
                                    _profile.dumbbellMaxWeightKg + 2.0,
                              );
                            });
                          }
                        },
                        child: const Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'c/u',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onToggle: (val) => _updateEquipment('adjustable_dumbbells', val),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // 2. Peso corporal / Calistenia
          EquipmentTile(
            title: 'Peso corporal / Calistenia',
            subtitle: 'Flexiones, sentadillas, fondos',
            tagLabel: 'BÁSICO',
            tagColor: AppColors.accentEnergy,
            isSelected: inv['bodyweight'] ?? false,
            onToggle: (val) => _updateEquipment('bodyweight', val),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // 3. Rueda abdominal (Ab-Wheel)
          EquipmentTile(
            title: 'Rueda abdominal (Ab-Wheel)',
            subtitle: 'Antiextensión lumbar estricta',
            tagLabel: 'ACCESORIO',
            tagColor: AppColors.textSecondary,
            isSelected: inv['ab_wheel'] ?? false,
            onToggle: (val) => _updateEquipment('ab_wheel', val),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // 4. Bandas elásticas de resistencia
          EquipmentTile(
            title: 'Bandas elásticas de resistencia',
            subtitle: 'Set ligero, medio y pesado',
            tagLabel: 'ACCESORIO',
            tagColor: AppColors.textSecondary,
            isSelected: inv['resistance_bands'] ?? false,
            onToggle: (val) => _updateEquipment('resistance_bands', val),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // 5. Barra olímpica y discos
          EquipmentTile(
            title: 'Barra olímpica y discos',
            subtitle: 'No disponible en ubicación actual',
            tagLabel: 'EXCLUIDO',
            tagColor: AppColors.textMuted,
            isSelected: inv['barbell'] ?? false,
            onToggle: (val) => _updateEquipment('barbell', val),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // 6. Banco reclinable multiajuste
          EquipmentTile(
            title: 'Banco reclinable multiajuste',
            subtitle: 'Sustituido por trabajo en suelo',
            tagLabel: 'EXCLUIDO',
            tagColor: AppColors.textMuted,
            isSelected: inv['incline_bench'] ?? false,
            onToggle: (val) => _updateEquipment('incline_bench', val),
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Garantía RN-06
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceSm + 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 18,
                  color: AppColors.accentRpe,
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Garantía: ',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: 'La IA solo prescribirá ejercicios 100% factibles con el equipamiento seleccionado. Se omitirán variantes de press en banca o racks pesados.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateEquipment(String key, bool value) {
    final updated = Map<String, bool>.from(_profile.equipmentInventory);
    updated[key] = value;
    setState(() {
      _profile = _profile.copyWith(equipmentInventory: updated);
    });
  }

  // --- SECCIÓN 4: OBJETIVOS Y FOCO ---
  Widget _buildSection4TrainingGoals() {
    final goals = [
      _GoalOption(
        key: 'FAT_LOSS',
        title: 'Pérdida de Grasa y Definición',
        description: 'Déficit calórico moderado + densidad metabólica y retención de masa magra.',
      ),
      _GoalOption(
        key: 'HYPERTROPHY',
        title: 'Hipertrofia y Masa Muscular',
        description: 'Superávit controlado + volumen orientado a tensión mecánica máxima.',
      ),
      _GoalOption(
        key: 'STRENGTH',
        title: 'Fuerza y Rendimiento Funcional',
        description:
            'Cargas elevadas, descansos extendidos y eficiencia neuromuscular.',
      ),
    ];

    final secondaryOptions = [
      _SecondaryOption(id: 'CARDIO', label: 'Resistencia cardiovascular'),
      _SecondaryOption(id: 'CORE', label: 'Core & Estabilidad'),
      _SecondaryOption(id: 'POSTURE', label: 'Salud postural'),
    ];

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.adjust, // target icon
                    size: 18,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    '4. OBJETIVOS Y FOCO',
                    style: AppTypography.labelMonoMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'MACRO-PLAN',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          Text(
            'OBJETIVO PRIMARIO DE CICLO',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Tarjetas de objetivos
          ...goals.map((goal) {
            final isSelected = _profile.primaryGoal == goal.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
              child: Material(
                color: isSelected
                    ? AppColors.surfaceElevated
                    : AppColors.surfaceContainerLow.withValues(alpha: 0.75),
                borderRadius: AppSpacing.roundedMd,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _profile = _profile.copyWith(primaryGoal: goal.key);
                    });
                  },
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.spaceMd),
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.borderStrong
                            : AppColors.borderSubtle,
                        width: AppSpacing.borderWidthSubtle,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio circle indicator
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.accentEnergy
                                : AppColors.surfaceContainerHighest,
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceBase,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.spaceSm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: AppTypography.headlineSm.copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.description,
                                style: AppTypography.bodySm.copyWith(
                                  color: isSelected
                                      ? AppColors.accentEnergy
                                      : AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.spaceSm),

          // Prioridades secundarias
          Text(
            'PRIORIDADES SECUNDARIAS (OPCIONAL)',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSpacing.spaceSm,
            runSpacing: AppSpacing.spaceSm,
            children: secondaryOptions.map((opt) {
              final isChecked = _profile.secondaryPriorities.contains(opt.id);
              return Material(
                color: isChecked
                    ? AppColors.surfaceElevated
                    : AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.roundedFull,
                child: InkWell(
                  onTap: () {
                    final updated = List<String>.from(
                      _profile.secondaryPriorities,
                    );
                    if (isChecked) {
                      updated.remove(opt.id);
                    } else {
                      updated.add(opt.id);
                    }
                    setState(() {
                      _profile = _profile.copyWith(
                        secondaryPriorities: updated,
                      );
                    });
                  },
                  borderRadius: AppSpacing.roundedFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.roundedFull,
                      border: Border.all(
                        color: isChecked
                            ? AppColors.accentEnergy
                            : AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isChecked ? Icons.check : Icons.add,
                          size: 16,
                          color: isChecked
                              ? AppColors.accentEnergy
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: isChecked
                                ? AppColors.accentEnergy
                                : AppColors.textMuted,
                            fontWeight: isChecked
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- BOTÓN DE ACCIÓN Y MENSAJE DE PERSISTENCIA ---
  Widget _buildSaveActionSection() {
    return Column(
      children: [
        FlatButton(
          label: _saveButtonText,
          icon: _saveButtonIcon,
          isLoading: _isSaving,
          onPressed: _handleSave,
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        Row(
          children: [
            Expanded(
              child: FlatButton(
                label: 'COPIAR PROMPT',
                icon: Icons.content_copy,
                variant: FlatButtonVariant.secondary,
                height: 48,
                onPressed: () {
                  ManualRoutineImporter.instance.copyPromptToClipboard(
                    context,
                    profile: _profile,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(
              child: FlatButton(
                label: 'CARGAR JSON',
                icon: Icons.upload_file,
                variant: FlatButtonVariant.secondary,
                height: 48,
                onPressed: () {
                  ManualRoutineImporter.instance.showImportDialog(
                    context,
                    profile: _profile,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Persistencia local-first protegida en almacenamiento local. Listo para recomputar macrociclo.',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _calculateFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '≈ $feet ft $inches in';
  }
}

class _GoalOption {
  final String key;
  final String title;
  final String description;

  const _GoalOption({
    required this.key,
    required this.title,
    required this.description,
  });
}

class _SecondaryOption {
  final String id;
  final String label;

  const _SecondaryOption({required this.id, required this.label});
}
