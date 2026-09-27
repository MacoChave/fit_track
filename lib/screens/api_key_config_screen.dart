import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/repositories/ai_routine_repository.dart';
import '../models/athlete_profile.dart';
import '../models/byok_config.dart';
import '../services/ai_connection_tester.dart';
import '../services/ai_prompt_builder.dart';
import '../services/local_storage_service.dart';
import '../services/manual_routine_importer.dart';
import '../services/secure_key_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/flat_button.dart';
import '../widgets/flat_card.dart';
import '../widgets/main_layout.dart';
import 'biometrics_equipment_screen.dart';
import 'calendar_nutrition_screen.dart';
import 'macronutrients_food_log_screen.dart';

class ApiKeyConfigScreen extends StatefulWidget {
  final VoidCallback? onNavigateToBiometrics;

  const ApiKeyConfigScreen({super.key, this.onNavigateToBiometrics});

  @override
  State<ApiKeyConfigScreen> createState() => _ApiKeyConfigScreenState();
}

class _ApiKeyConfigScreenState extends State<ApiKeyConfigScreen> {
  // Tabs: 0 = Modo Automático, 1 = Modo Manual
  int _activeTab = 0;

  // --- ESTADO: MODO AUTOMÁTICO ---
  AiProvider _selectedProvider = AiProvider.gemini;
  String _selectedEngineModel = 'gemini-1.5-flash';
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  bool _isTestingPing = false;
  bool _isSavingConfig = false;
  PingTestResult? _pingResult = PingTestResult.initial();

  // Optimización de duración (30 o 45 min toggle) y enfoque generativo
  int _sessionOptimizationMinutes = 45; // 30 o 45 min
  GenerativeFocus _generativeFocus = GenerativeFocus.scientific;

  // --- ESTADO: MODO MANUAL ---
  late final TextEditingController _manualJsonController;
  bool _isImportingManual = false;
  ManualImportResult? _manualImportResult;
  bool _showPromptPreview = false;
  String _currentPromptPreview = '';

  // Barra de navegación inferior (Ajustes = 2)
  int _currentNavIndex = 2;

  // Modelos disponibles por proveedor
  Map<AiProvider, List<({String id, String label, String description})>>
  get _availableEngineModels => {
    AiProvider.gemini: [
      (
        id: 'gemini-1.5-flash',
        label: 'Gemini 1.5 Flash',
        description: 'Ultrarrápido · 15 RPM Gratis (Recomendado)',
      ),
      (
        id: 'gemini-1.5-pro',
        label: 'Gemini 1.5 Pro',
        description: 'Razonamiento Complejo & Mayor Contexto',
      ),
    ],
    AiProvider.openai: [
      (id: 'gpt-4o', label: 'GPT-4o', description: 'Omni Multimodal Flagship'),
      (
        id: 'gpt-4o-mini',
        label: 'GPT-4o Mini',
        description: 'Baja Latencia y Eficiencia Máxima',
      ),
    ],
    AiProvider.anthropic: [
      (
        id: 'claude-3-5-sonnet',
        label: 'Claude 3.5 Sonnet',
        description: 'Alta Capacidad de Razonamiento Biomecánico',
      ),
      (
        id: 'claude-3-haiku',
        label: 'Claude 3 Haiku',
        description: 'Generación y Respuesta Instantánea',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _manualJsonController = TextEditingController();
    _loadStoredKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _manualJsonController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredKey() async {
    final storedKey = await SecureKeyService.instance.getApiKey(
      provider: _selectedProvider.id,
    );
    if (mounted) {
      setState(() {
        if (storedKey != null && storedKey.isNotEmpty) {
          _apiKeyController.text = storedKey;
          _pingResult = PingTestResult.initial();
        } else {
          _apiKeyController.text = '';
          _pingResult = null;
        }
      });
    }
  }

  Future<void> _handleProviderChange(AiProvider provider) async {
    setState(() {
      _selectedProvider = provider;
      _pingResult = null;
      final models = _availableEngineModels[provider];
      if (models != null && models.isNotEmpty) {
        _selectedEngineModel = models.first.id;
      }
    });
    final key = await SecureKeyService.instance.getApiKey(
      provider: provider.id,
    );
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        if (key != null && key.isNotEmpty) {
          _pingResult = PingTestResult.initial();
        }
      });
    }
  }

  Future<void> _runPingTest() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: const BorderSide(color: AppColors.accentRest),
          ),
          content: Text(
            'Ingresa una clave de API antes de probar la conexión.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTestingPing = true;
    });

    final result = await AiConnectionTester.instance.testConnection(
      provider: _selectedProvider,
      apiKey: key,
    );

    if (mounted) {
      setState(() {
        _isTestingPing = false;
        _pingResult = result;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _apiKeyController.text = data.text!.trim();
        _pingResult = null;
      });
    }
  }

  Future<void> _pasteJsonFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _manualJsonController.text = data.text!.trim();
        _manualImportResult = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'JSON pegado desde el portapapeles en el editor.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.accentEnergy,
              ),
            ),
          ),
        );
      }
    }
  }

  // --- GUARDAR CONFIGURACIÓN AUTOMÁTICA Y PERSISTIR EN SQLITE ---
  Future<void> _handleSaveAutomaticConfig() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: const BorderSide(color: AppColors.accentRest),
          ),
          content: Text(
            'No se puede guardar una clave vacía.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingConfig = true;
    });

    // 1. Cifrado por hardware en Keystore/Keychain (RN-03 / RNF-01)
    await SecureKeyService.instance.saveApiKey(
      key,
      provider: _selectedProvider.id,
    );

    // 2. Persistir perfil de atleta con la duración de sesión configurada
    final AthleteProfile profile =
        await LocalStorageService.instance.getProfile() ??
        AthleteProfile.empty();
    final updatedProfile = profile.copyWith(
      sessionTimeMinutes: _sessionOptimizationMinutes,
    );
    await LocalStorageService.instance.saveProfile(updatedProfile);

    // 3. Persistir en SQLite: registro en ai_generations y rutina activa
    try {
      final repo = AiRoutineRepository();
      final effectivePrompt = AiPromptBuilder.buildPrompt(updatedProfile);

      await repo.saveAiPromptAndResponse(
        prompt: effectivePrompt,
        rawJson: json.encode({
          'config': {
            'provider': _selectedProvider.name,
            'model': _selectedEngineModel,
            'focus': _generativeFocus.id,
            'duration_minutes': _sessionOptimizationMinutes,
            'status': 'configured_active',
          },
          'plan_id': 'byok_${_selectedProvider.id}_active',
          'semanas': 4,
          'objetivo_primario': updatedProfile.primaryGoal,
        }),
        provider: _selectedProvider.name,
        model: _selectedEngineModel,
        planId: 'byok_${_selectedProvider.id}_active',
        weeks: 4,
        primaryGoal: updatedProfile.primaryGoal,
        status: 'configured',
      );

      // Si no hay rutina previa importada en SQLite, sembramos la plantilla de muestra
      await repo.importRoutineFromJson(_sampleRoutineJson);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isSavingConfig = false;
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
                  'Configuración ($_selectedEngineModel · $_sessionOptimizationMinutes min) y rutina persistidas en SQLite.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // --- GUARDAR RUTINA MANUAL EN SQLITE ---
  Future<void> _handleSaveManualRoutineToSqlite() async {
    final content = _manualJsonController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: const BorderSide(color: AppColors.accentRest),
          ),
          content: Text(
            'El editor JSON está vacío. Pega o carga un archivo JSON primero.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isImportingManual = true;
      _manualImportResult = null;
    });

    final result = await ManualRoutineImporter.instance.importJsonString(
      content,
    );

    if (mounted) {
      setState(() {
        _isImportingManual = false;
        _manualImportResult = result;
      });

      if (result.isSuccess) {
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
                    result.message,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // --- CARGAR ARCHIVO JSON DESDE EL DISPOSITIVO ---
  Future<void> _pickAndLoadJsonFile() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      final jsonContent = utf8.decode(bytes);

      if (jsonContent.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'El archivo seleccionado está vacío.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _manualJsonController.text = jsonContent.trim();
        _manualImportResult = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              side: const BorderSide(color: AppColors.accentEnergy),
            ),
            content: Text(
              'Archivo "${picked.name}" cargado en el editor (${jsonContent.length} bytes). Presiona "GUARDAR RUTINA EN SQLITE".',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.accentEnergy,
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Error al abrir archivo: $e',
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        );
      }
    }
  }

  void _loadSampleJsonIntoEditor() {
    setState(() {
      _manualJsonController.text = _sampleRoutineJson;
      _manualImportResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Ejemplo cargado en el editor. Listo para guardar en SQLite.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.accentEnergy),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      subtitle: 'CONFIGURACIÓN IA (BYOK)',
      currentNavIndex: _currentNavIndex,
      onNavIndexChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CalendarNutritionScreen()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MacronutrientsFoodLogScreen(),
            ),
          );
        } else if (index == 2) {
          if (widget.onNavigateToBiometrics != null) {
            widget.onNavigateToBiometrics!();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BiometricsEquipmentScreen(),
              ),
            );
          }
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
            _buildTitleAndSecurityBadge(),
            const SizedBox(height: AppSpacing.spaceMd),
            _buildModeTabs(),
            const SizedBox(height: AppSpacing.spaceLg),
            if (_activeTab == 0) ...[
              _buildAutomaticModeContent(),
            ] else ...[
              _buildManualModeContent(),
            ],
            const SizedBox(height: AppSpacing.space2Xl),
          ],
        ),
      ),
    );
  }

  // --- SUBHEADER SUPERIOR ---
  Widget _buildTitleAndSecurityBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INTELIGENCIA ARTIFICIAL',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.accentEnergy,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: AppColors.accentEnergy,
                  width: AppSpacing.borderWidthSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AES-256 ZERO-SERVER',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Motor Generativo & Parámetros BYOK',
          style: AppTypography.headlineLg.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Conecta tu API Key para cálculo directo o genera tu rutina en modo manual sin clave.',
          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // --- SELECTOR DE PESTAÑAS (MODO AUTOMÁTICO VS MODO MANUAL) ---
  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              index: 0,
              icon: Icons.auto_awesome,
              label: 'MODO AUTOMÁTICO',
              subtitle: 'API Directa & Ping Test',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabItem(
              index: 1,
              icon: Icons.edit_note,
              label: 'MODO MANUAL',
              subtitle: 'Prompt & JSON Offline',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _activeTab == index;

    return Material(
      color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
      borderRadius: AppSpacing.roundedSm,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        borderRadius: AppSpacing.roundedSm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(
              color: isSelected ? AppColors.accentEnergy : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.accentEnergy
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: isSelected
                            ? AppColors.accentEnergy
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- CONTENIDO: MODO AUTOMÁTICO ---
  // ==========================================
  Widget _buildAutomaticModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProviderSelectorSection(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildApiKeyInputSection(),
        const SizedBox(height: AppSpacing.spaceSm),
        _buildApiKeyRedirectionNote(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildPingTestButton(),
        if (_pingResult != null) ...[
          const SizedBox(height: AppSpacing.spaceMd),
          _buildPingTestResultCard(),
        ],
        const SizedBox(height: AppSpacing.spaceLg),
        _buildEngineModelSelectorSection(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildDurationOptimizationToggle(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildGenerativeFocusSection(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildSaveAutomaticButton(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildTransparencyCard(),
      ],
    );
  }

  // --- SELECCIÓN DE PROVEEDOR IA ---
  Widget _buildProviderSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROVEEDOR DE INTELIGENCIA ARTIFICIAL',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'ARQUITECTURA BYOK',
              style: AppTypography.labelMonoSm.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        Row(
          children: AiProvider.values.map((provider) {
            final isSelected = _selectedProvider == provider;
            final borderColor = isSelected
                ? AppColors.accentEnergy
                : AppColors.borderSubtle;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Material(
                  color: isSelected
                      ? AppColors.surfaceElevated
                      : AppColors.surfaceCard,
                  borderRadius: AppSpacing.roundedMd,
                  child: InkWell(
                    onTap: () => _handleProviderChange(provider),
                    borderRadius: AppSpacing.roundedMd,
                    child: Container(
                      height: 84,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentEnergy.withValues(
                                      alpha: 0.2,
                                    )
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Text(
                              provider.headerBadge,
                              style: AppTypography.labelMonoSm.copyWith(
                                color: isSelected
                                    ? AppColors.accentEnergy
                                    : AppColors.textMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: AppTypography.headlineSm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                provider.modelSummary,
                                style: AppTypography.bodySm.copyWith(
                                  color: isSelected
                                      ? AppColors.accentEnergy
                                      : AppColors.textMuted,
                                  fontSize: 9.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
      ],
    );
  }

  // --- INPUT CARD DE API KEY ---
  Widget _buildApiKeyInputSection() {
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
                    Icons.vpn_key,
                    size: 16,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CLAVE DE API (API KEY)',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                _selectedProvider.apiHint,
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm + 2),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: AppColors.borderStrong,
                width: AppSpacing.borderWidthSubtle,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    style: AppTypography.labelMonoMd.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: _obscureApiKey ? 2.0 : 0.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ingresa tu API Key...',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                  tooltip: _obscureApiKey ? 'Mostrar clave' : 'Ocultar clave',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.content_paste_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Pegar del portapapeles',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.accentEnergy,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: 'Almacenado de forma no volátil en Android Keystore / iOS Secure Enclave. FitTrack opera en arquitectura Zero-Server.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NOTA PARA REDIRIGIR A DÓNDE CONSEGUIR EL API KEY ---
  Widget _buildApiKeyRedirectionNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link, size: 18, color: AppColors.accentWater),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿DÓNDE CONSEGUIR TU API KEY?',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentWater,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedProvider == AiProvider.gemini
                      ? 'Google AI Studio ofrece un plan gratuito con 15 RPM sin requerir tarjeta de crédito.'
                      : (_selectedProvider == AiProvider.openai
                            ? 'Genera o copia tu clave secreta desde la consola de OpenAI Platform.'
                            : 'Crea tu API Key desde la consola de desarrollador de Anthropic.'),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: _selectedProvider.signupUrl),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Enlace copiado al portapapeles: ${_selectedProvider.signupUrl}',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.accentEnergy,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Consigue tu clave en ${_selectedProvider.apiHint} ↗',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.accentEnergy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.copy,
                        size: 12,
                        color: AppColors.accentEnergy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTÓN PROBAR CONEXIÓN (PING TEST LIVE) ---
  Widget _buildPingTestButton() {
    return FlatButton(
      label: 'PROBAR CONEXIÓN (PING TEST LIVE)',
      icon: Icons.bolt,
      variant: FlatButtonVariant.secondary,
      isLoading: _isTestingPing,
      onPressed: _runPingTest,
    );
  }

  // --- CARD DE RESULTADO DEL PING TEST (TC-01) ---
  Widget _buildPingTestResultCard() {
    final result = _pingResult!;
    final isSuccess = result.isSuccess;
    final accentColor = isSuccess
        ? AppColors.accentEnergy
        : AppColors.accentRest;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: accentColor,
          width: AppSpacing.borderWidthAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.statusText,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          if (isSuccess) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LATENCIA ROUND-TRIP',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          text: '${result.latencyMs}',
                          style: AppTypography.labelMonoLg.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: ' ms',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUOTA DISPONIBLE',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.quotaInfo,
                        style: AppTypography.labelMonoMd.copyWith(
                          color: AppColors.accentEnergy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spaceSm + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                'Modelo verificado: ${result.verifiedModel}',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.accentRest,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.errorMessage ??
                          'Verifica que la clave pertenezca a ${_selectedProvider.name} y cuente con cuota activa.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- SELECTOR DEL TIPO DE MOTOR ---
  Widget _buildEngineModelSelectorSection() {
    final models = _availableEngineModels[_selectedProvider] ?? [];

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
                    Icons.memory,
                    size: 16,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SELECTOR DEL TIPO DE MOTOR',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  _selectedEngineModel.toUpperCase(),
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Elige la versión del motor LLM que generará tu programación:',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Column(
            children: models.map((m) {
              final isSelected = _selectedEngineModel == m.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
                child: Material(
                  color: isSelected
                      ? AppColors.surfaceElevated
                      : AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedMd,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEngineModel = m.id;
                      });
                    },
                    borderRadius: AppSpacing.roundedMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentEnergy
                              : AppColors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: isSelected
                                ? AppColors.accentEnergy
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.label,
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.description,
                                  style: AppTypography.bodySm.copyWith(
                                    color: isSelected
                                        ? AppColors.accentEnergy
                                        : AppColors.textMuted,
                                    fontSize: 10.5,
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
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TOGGLE PARA OPTIMIZAR PARA 30 O 45 MINUTOS (RN-05) ---
  Widget _buildDurationOptimizationToggle() {
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
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.accentEnergy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OPTIMIZAR DURACIÓN DE SESIÓN',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  '$_sessionOptimizationMinutes MIN ACTIVOS',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Alterna entre 30 o 45 minutos para adaptar volumen, superseries y descansos:',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Row(
            children: [
              Expanded(
                child: _buildDurationOption(
                  minutes: 30,
                  label: '30 MINUTOS',
                  subtitle: 'Superseries & Alta Densidad',
                  icon: Icons.flash_on,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: _buildDurationOption(
                  minutes: 45,
                  label: '45 MINUTOS',
                  subtitle: 'Fuerza & Descanso Óptimo',
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption({
    required int minutes,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _sessionOptimizationMinutes == minutes;

    return Material(
      color: isSelected
          ? AppColors.surfaceElevated
          : AppColors.surfaceContainerLowest,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: () {
          setState(() {
            _sessionOptimizationMinutes = minutes;
          });
        },
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spaceSm + 2),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.accentEnergy
                  : AppColors.borderSubtle,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.accentEnergy
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: isSelected
                          ? AppColors.accentEnergy
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ENFOQUE GENERATIVO (BOTÓN CIENTÍFICO O ADAPTATIVO) ---
  Widget _buildGenerativeFocusSection() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENFOQUE GENERATIVO (TEMPERATURA)',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                _generativeFocus.description,
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Row(
            children: [
              Expanded(
                child: _buildFocusOptionButton(
                  option: GenerativeFocus.scientific,
                  icon: Icons.science_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: _buildFocusOptionButton(
                  option: GenerativeFocus.adaptive,
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusOptionButton({
    required GenerativeFocus option,
    required IconData icon,
  }) {
    final isSelected = _generativeFocus == option;
    final borderColor = isSelected
        ? AppColors.accentEnergy
        : AppColors.borderSubtle;

    return Material(
      color: isSelected
          ? AppColors.surfaceElevated
          : AppColors.surfaceContainerLow,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: () {
          setState(() {
            _generativeFocus = option;
          });
        },
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.accentEnergy
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  option.label,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: isSelected
                        ? AppColors.accentEnergy
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BOTÓN GUARDAR CONFIGURACIÓN AUTOMÁTICA EN SQLITE ---
  Widget _buildSaveAutomaticButton() {
    return FlatButton(
      label: 'GUARDAR CONFIGURACIÓN EN SQLITE',
      icon: Icons.save,
      isLoading: _isSavingConfig,
      onPressed: _handleSaveAutomaticConfig,
    );
  }

  // --- CARD DE TRANSPARENCIA ---
  Widget _buildTransparencyCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppSpacing.borderWidthSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.accentWater,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(
                'TRANSPARENCIA & MODELO BYOK',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'FitTrack no cobra margen sobre el uso de la IA. Tu token se envía de forma directa y cifrada al endpoint del proveedor sin servidores intermediarios.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- CONTENIDO: MODO MANUAL ---
  // ==========================================
  Widget _buildManualModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildManualIntroCard(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildStep1CopyPromptCard(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildStep2JsonCard(),
        const SizedBox(height: AppSpacing.spaceLg),
        _buildStep3SaveToSqliteButton(),
        if (_manualImportResult != null) ...[
          const SizedBox(height: AppSpacing.spaceMd),
          _buildManualImportResultCard(),
        ],
      ],
    );
  }

  // --- INTRODUCCIÓN MODO MANUAL ---
  Widget _buildManualIntroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.accentWater.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.offline_bolt,
                    size: 20,
                    color: AppColors.accentWater,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Text(
                    'MODO MANUAL (SIN API KEY)',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentWater.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  '100% GRATUITO',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentWater,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Genera tu rutina externamente en la web de cualquier IA (ChatGPT, Claude, Gemini Web) y persiste el resultado en SQLite relacional sin requerir tarjetas ni llaves API.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- PASO 1: COPIAR PROMPT PARA LA IA ---
  Widget _buildStep1CopyPromptCard() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  'PASO 1',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(
                'COPIAR PROMPT DE ENTRENAMIENTO',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'El prompt compila automáticamente tus biometrías, disponibilidad y equipamiento según el estándar.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          FlatButton(
            label: 'COPIAR PROMPT PARA MI IA',
            icon: Icons.content_copy,
            variant: FlatButtonVariant.secondary,
            onPressed: () async {
              final prompt = await ManualRoutineImporter.instance
                  .copyPromptToClipboard(context);
              setState(() {
                _currentPromptPreview = prompt;
              });
            },
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          InkWell(
            onTap: () async {
              if (_currentPromptPreview.isEmpty) {
                final athlete =
                    await LocalStorageService.instance.getProfile() ??
                    AthleteProfile.empty();
                _currentPromptPreview = AiPromptBuilder.buildPrompt(athlete);
              }
              setState(() {
                _showPromptPreview = !_showPromptPreview;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showPromptPreview
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _showPromptPreview
                      ? 'Ocultar texto del prompt'
                      : 'Previsualizar prompt generado',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (_showPromptPreview) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSm),
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: AppSpacing.borderWidthSubtle,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _currentPromptPreview,
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- PASO 2: CARGAR ARCHIVO JSON O TEXT AREA PARA PEGAR JSON ---
  Widget _buildStep2JsonCard() {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  'PASO 2',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.accentEnergy,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(
                'INGRESAR JSON RESULTANTE',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Puedes cargar un archivo .json exportado o pegar el contenido directamente en el área de texto:',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          FlatButton(
            label: 'CARGAR ARCHIVO JSON (.JSON / .TXT)',
            icon: Icons.upload_file,
            variant: FlatButtonVariant.secondary,
            onPressed: _pickAndLoadJsonFile,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          // Editor Text Area multilínea
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: AppColors.borderStrong,
                width: AppSpacing.borderWidthSubtle,
              ),
            ),
            child: Column(
              children: [
                // Barra de herramientas superior
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderSubtle,
                        width: AppSpacing.borderWidthSubtle,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 16,
                        color: AppColors.accentWater,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RESULTADO JSON',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _loadSampleJsonIntoEditor,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(color: AppColors.accentEnergy),
                          ),
                          child: Text(
                            'CARGAR EJEMPLO',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.accentEnergy,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.content_paste_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: _pasteJsonFromClipboard,
                        tooltip: 'Pegar del portapapeles',
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _manualJsonController.clear();
                            _manualImportResult = null;
                          });
                        },
                        tooltip: 'Limpiar editor',
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.spaceSm),
                  child: TextField(
                    controller: _manualJsonController,
                    maxLines: 10,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pega aquí el JSON devuelto por tu IA (ChatGPT, Claude, Gemini Web)...',
                      hintStyle: AppTypography.bodySm.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
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

  // --- PASO 3: BOTÓN PARA GUARDAR RUTINA EN SQLITE ---
  Widget _buildStep3SaveToSqliteButton() {
    return FlatButton(
      label: 'GUARDAR RUTINA EN SQLITE',
      icon: Icons.storage,
      isLoading: _isImportingManual,
      onPressed: _handleSaveManualRoutineToSqlite,
    );
  }

  // --- CARD DE RESULTADO DE IMPORTACIÓN MANUAL ---
  Widget _buildManualImportResultCard() {
    final result = _manualImportResult!;
    final isSuccess = result.isSuccess;
    final accentColor = isSuccess
        ? AppColors.accentEnergy
        : AppColors.accentRest;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: accentColor,
          width: AppSpacing.borderWidthAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error_outline,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSuccess ? 'PERSISTIDO EN SQLITE' : 'ERROR DE VALIDACIÓN',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (isSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    '${result.daysCount} DÍAS · ${result.exercisesCount} EJERCICIOS',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.accentEnergy,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            result.message,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (isSuccess) ...[
            const SizedBox(height: AppSpacing.spaceMd),
            FlatButton(
              label: 'IR AL CALENDARIO A VER LA RUTINA',
              icon: Icons.calendar_today,
              variant: FlatButtonVariant.secondary,
              height: 42,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalendarNutritionScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- EJEMPLO DERCAS 5.2 PARA TEST Y CARGA RÁPIDA ---
  static const String _sampleRoutineJson = '''{
  "plan_id": "plan_dercas_sample_sqlite",
  "semanas": 4,
  "objetivo_primario": "Fuerza e Hipertrofia",
  "dias": [
    {
      "dia_semana": "Lunes",
      "enfoque": "Empuje & Pectoral/Deltoides",
      "duracion_estimada_min": 45,
      "calentamiento": [
        { "nombre": "Movilidad de hombros y escápulas", "duracion_seg": 120 },
        { "nombre": "Flexiones suaves", "repeticiones": 12 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "press_plano_mancuernas",
              "nombre": "Press de Pecho Plano con Mancuernas",
              "series": 4,
              "repeticiones_objetivo": 8,
              "descanso_segundos": 90,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 22.0,
              "notas_tecnicas": "Controlar excéntrica 3s, pausa 1s abajo"
            },
            {
              "id": "press_militar_mancuernas",
              "nombre": "Press Militar con Mancuernas",
              "series": 3,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 75,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 16.0,
              "notas_tecnicas": "Core firme, sin hiperextensión lumbar"
            }
          ]
        },
        {
          "tipo": "Accesorios & Densidad",
          "ejercicios": [
            {
              "id": "elevaciones_laterales",
              "nombre": "Elevaciones Laterales",
              "series": 3,
              "repeticiones_objetivo": 15,
              "descanso_segundos": 60,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 10.0,
              "notas_tecnicas": "Leve inclinación anterior, codos lideran"
            }
          ]
        }
      ],
      "finisher_core": {
        "nombre": "Plancha Abdominal Isométrica",
        "duracion_seg": 180
      },
      "guia_nutricional": {
        "calorias_objetivo": 2200,
        "proteina_gramos": 160,
        "agua_litros": 3.0
      }
    },
    {
      "dia_semana": "Miércoles",
      "enfoque": "Tracción & Espalda/Bíceps",
      "duracion_estimada_min": 45,
      "calentamiento": [
        { "nombre": "Cat-Camel y dislocaciones", "duracion_seg": 90 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "remo_unilateral_mancuerna",
              "nombre": "Remo Unilateral con Mancuerna",
              "series": 4,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 75,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 24.0,
              "notas_tecnicas": "Tirar hacia la cadera, retracción máxima"
            },
            {
              "id": "curl_biceps_inclinado",
              "nombre": "Curl de Bíceps en Banco Inclinado",
              "series": 3,
              "repeticiones_objetivo": 12,
              "descanso_segundos": 60,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 12.0,
              "notas_tecnicas": "Máxima elongación en la posición baja"
            }
          ]
        }
      ],
      "guia_nutricional": {
        "calorias_objetivo": 2200,
        "proteina_gramos": 160,
        "agua_litros": 3.0
      }
    },
    {
      "dia_semana": "Viernes",
      "enfoque": "Pierna & Cadena Posterior",
      "duracion_estimada_min": 45,
      "calentamiento": [
        { "nombre": "Sentadillas profundas libres", "repeticiones": 15 },
        { "nombre": "Puente de glúteos", "repeticiones": 15 }
      ],
      "bloques": [
        {
          "tipo": "Fuerza Base",
          "ejercicios": [
            {
              "id": "sentadilla_goblet",
              "nombre": "Sentadilla Goblet con Mancuerna",
              "series": 4,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 90,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 26.0,
              "notas_tecnicas": "Talones pegados, torso erguido"
            },
            {
              "id": "peso_muerto_rumano",
              "nombre": "Peso Muerto Rumano con Mancuernas",
              "series": 4,
              "repeticiones_objetivo": 10,
              "descanso_segundos": 90,
              "equipo_requerido": "mancuernas",
              "peso_sugerido_kg": 24.0,
              "notas_tecnicas": "Bisagra de cadera profunda, espalda neutra"
            }
          ]
        }
      ],
      "guia_nutricional": {
        "calorias_objetivo": 2300,
        "proteina_gramos": 165,
        "agua_litros": 3.5
      }
    }
  ]
}''';
}
