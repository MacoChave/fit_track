import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/repositories/ai_routine_repository.dart';
import '../models/athlete_profile.dart';
import '../services/ai_prompt_builder.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/flat_button.dart';

/// Resultado de la operación de importación manual de rutina
class ManualImportResult {
  final bool isSuccess;
  final String message;
  final String? planId;
  final int daysCount;
  final int exercisesCount;

  const ManualImportResult({
    required this.isSuccess,
    required this.message,
    this.planId,
    this.daysCount = 0,
    this.exercisesCount = 0,
  });
}

/// Servicio para el flujo manual de generación de rutina sin API Key (BYOK Manual)
class ManualRoutineImporter {
  static final ManualRoutineImporter instance = ManualRoutineImporter._();
  ManualRoutineImporter._();

  /// Copia al portapapeles el prompt de entrenamiento compilado para el atleta
  Future<String> copyPromptToClipboard(
    BuildContext context, {
    AthleteProfile? profile,
  }) async {
    final athlete =
        profile ??
        await LocalStorageService.instance.getProfile() ??
        AthleteProfile.empty();
    final prompt = AiPromptBuilder.buildPrompt(athlete);

    await Clipboard.setData(ClipboardData(text: prompt));

    if (context.mounted) {
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
                Icons.content_copy,
                color: AppColors.accentEnergy,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  '¡Prompt copiado! Pégalo en tu IA favorita (ChatGPT, Claude, Gemini Web).',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return prompt;
  }

  /// Valida e importa una cadena de texto JSON a SQLite, extrayendo fecha, series, repeticiones y equipo
  Future<ManualImportResult> importJsonString(
    String rawJson, {
    String? promptText,
    AthleteProfile? profile,
  }) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      return const ManualImportResult(
        isSuccess: false,
        message: 'El contenido JSON no puede estar vacío.',
      );
    }

    // Limpiar posibles bloques markdown ```json ... ``` devueltos por LLMs
    String sanitized = trimmed;
    if (sanitized.startsWith('```')) {
      sanitized = sanitized.replaceAll(
        RegExp(r'^```(json)?\n?', multiLine: true),
        '',
      );
      sanitized = sanitized
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();
    }

    Map<String, dynamic> decoded;
    try {
      final parsed = json.decode(sanitized);
      if (parsed is! Map<String, dynamic>) {
        return const ManualImportResult(
          isSuccess: false,
          message:
              'El JSON debe ser un objeto raíz con la estructura del plan.',
        );
      }
      decoded = parsed;
    } catch (e) {
      return ManualImportResult(
        isSuccess: false,
        message:
            'Error de sintaxis JSON: $e. Asegúrate de copiar el JSON completo generado por tu IA.',
      );
    }

    // Validación básica del contrato DERCAS 5.2
    if (!decoded.containsKey('dias') || decoded['dias'] is! List) {
      return const ManualImportResult(
        isSuccess: false,
        message: 'Formato incompatible: Falta la lista "dias" requerida por la especificación.',
      );
    }

    final athlete =
        profile ??
        await LocalStorageService.instance.getProfile() ??
        AthleteProfile.empty();
    final effectivePrompt = promptText ?? AiPromptBuilder.buildPrompt(athlete);

    final planId =
        decoded['plan_id']?.toString() ??
        'plan_manual_${DateTime.now().millisecondsSinceEpoch}';
    final diasList = decoded['dias'] as List<dynamic>;

    int totalExercises = 0;
    for (final dia in diasList) {
      if (dia is Map<String, dynamic> && dia['bloques'] is List) {
        for (final bloque in dia['bloques'] as List<dynamic>) {
          if (bloque is Map<String, dynamic> && bloque['ejercicios'] is List) {
            totalExercises += (bloque['ejercicios'] as List<dynamic>).length;
          }
        }
      }
    }

    final repo = AiRoutineRepository();

    // 1. Guardar prompt y JSON recibido en ai_generations
    await repo.saveAiPromptAndResponse(
      prompt: effectivePrompt,
      rawJson: sanitized,
      provider: 'Manual / Web LLM (Sin API Key)',
      model: 'Custom LLM Web Export',
      planId: planId,
      weeks: (decoded['semanas'] as num?)?.toInt() ?? 4,
      primaryGoal:
          decoded['objetivo_primario']?.toString() ?? athlete.primaryGoal,
    );

    // 2. Procesar y guardar relacionalmente: fecha, series, repeticiones y equipo
    await repo.importRoutineFromJson(sanitized);

    return ManualImportResult(
      isSuccess: true,
      message:
          '¡Rutina importada con éxito! Se guardaron $totalExercises ejercicios en ${diasList.length} jornadas.',
      planId: planId,
      daysCount: diasList.length,
      exercisesCount: totalExercises,
    );
  }

  /// Abre el selector de archivos del sistema operativo para que el usuario elija su archivo `.json`
  Future<ManualImportResult> pickAndImportJsonFile(
    BuildContext context, {
    AthleteProfile? profile,
  }) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (picked == null) {
        return const ManualImportResult(
          isSuccess: false,
          message: 'No se seleccionó ningún archivo.',
        );
      }
      final bytes = await picked.readAsBytes();
      final jsonContent = utf8.decode(bytes);

      if (jsonContent.isEmpty) {
        return const ManualImportResult(
          isSuccess: false,
          message: 'El archivo seleccionado está vacío.',
        );
      }

      final importResult = await importJsonString(
        jsonContent,
        profile: profile,
      );

      if (context.mounted) {
        _showResultSnackBar(context, importResult);
      }

      return importResult;
    } catch (e) {
      final errResult = ManualImportResult(
        isSuccess: false,
        message: 'No se pudo leer el archivo: $e',
      );
      if (context.mounted) {
        _showResultSnackBar(context, errResult);
      }
      return errResult;
    }
  }

  /// Muestra un modal con selector de archivo y área de texto para pegar JSON directamente
  Future<void> showImportDialog(
    BuildContext context, {
    AthleteProfile? profile,
    VoidCallback? onImportSuccess,
  }) async {
    final textController = TextEditingController();
    bool isProcessing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.margin,
                right: AppSpacing.margin,
                top: AppSpacing.spaceLg,
                bottom:
                    MediaQuery.of(modalContext).viewInsets.bottom +
                    AppSpacing.spaceXl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cargar Rutina JSON (Sin API Key)',
                        style: AppTypography.headlineLg.copyWith(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spaceSm),
                  Text(
                    'Selecciona el archivo .json que descargaste de tu IA o pega el código JSON directamente abajo:',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceMd),

                  // Botón para seleccionar archivo desde el explorador
                  FlatButton(
                    label: 'SELECCIONAR ARCHIVO .JSON DEL DISPOSITIVO',
                    icon: Icons.folder_open,
                    variant: FlatButtonVariant.secondary,
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setModalState(() => isProcessing = true);
                            Navigator.pop(modalContext);
                            final res = await pickAndImportJsonFile(
                              context,
                              profile: profile,
                            );
                            if (res.isSuccess && onImportSuccess != null) {
                              onImportSuccess();
                            }
                          },
                  ),

                  const SizedBox(height: AppSpacing.spaceMd),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spaceSm,
                        ),
                        child: Text(
                          'O PEGA EL TEXTO JSON',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spaceMd),

                  // Campo de texto para pegar JSON
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(AppSpacing.spaceSm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBase,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: TextField(
                      controller: textController,
                      maxLines: null,
                      expands: true,
                      style: AppTypography.bodySm.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '{\n  "plan_id": "...",\n  "dias": [...]\n}',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.spaceLg),

                  // Botón importar texto
                  FlatButton(
                    label: isProcessing
                        ? 'GUARDANDO EN SQLITE...'
                        : 'GUARDAR RUTINA EN SQLITE',
                    icon: Icons.download_done,
                    isLoading: isProcessing,
                    variant: FlatButtonVariant.primary,
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final raw = textController.text.trim();
                            if (raw.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor pega el JSON o selecciona un archivo.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isProcessing = true);
                            final res = await importJsonString(
                              raw,
                              profile: profile,
                            );
                            setModalState(() => isProcessing = false);

                            if (context.mounted) {
                              Navigator.pop(modalContext);
                              _showResultSnackBar(context, res);
                            }

                            if (res.isSuccess && onImportSuccess != null) {
                              onImportSuccess();
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showResultSnackBar(BuildContext context, ManualImportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(
            color: result.isSuccess ? AppColors.accentEnergy : Colors.redAccent,
          ),
        ),
        content: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle : Icons.error_outline,
              color: result.isSuccess
                  ? AppColors.accentEnergy
                  : Colors.redAccent,
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
