import 'package:flutter/material.dart';

import 'package:fit_track/features/app_update/data/services/update_service.dart';
import 'package:fit_track/features/app_update/domain/entities/version_info.dart';
import 'package:fit_track/theme/app_colors.dart';
import 'package:fit_track/theme/app_spacing.dart';
import 'package:fit_track/theme/app_typography.dart';
import 'package:fit_track/widgets/flat_button.dart';

class UpdateDialog extends StatefulWidget {
  final VersionInfo info;
  final Future<bool> Function(VersionInfo info, ValueChanged<double> onProgress)?
      onDownload;

  const UpdateDialog({
    super.key,
    required this.info,
    this.onDownload,
  });

  static Future<void> show(BuildContext context, VersionInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
        child: UpdateDialog(info: info),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0;
  bool _downloading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_downloading,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: AppColors.accentEnergy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva versión disponible',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.info.version} (Build ${widget.info.buildNumber})',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.spaceLg),

            // Novedades
            Text(
              'Novedades:',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.spaceSm),

            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: widget.info.releaseNotes.isEmpty
                  ? Text(
                      'Mejoras generales de estabilidad y rendimiento.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.info.releaseNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppColors.accentEnergy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurface,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.spaceMd),
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: AppColors.accentRest.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentRest, width: 1),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.spaceLg),

            // Barra de progreso de descarga
            if (_downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.accentEnergy,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                'Descargando... ${(_progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
            ],

            // Botones de acción
            Row(
              children: [
                if (!_downloading) ...[
                  Expanded(
                    child: FlatButton(
                      label: 'AHORA NO',
                      variant: FlatButtonVariant.secondary,
                      height: 48,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceMd),
                ],
                Expanded(
                  child: FlatButton(
                    label: _downloading ? 'DESCARGANDO...' : 'ACTUALIZAR',
                    variant: FlatButtonVariant.primary,
                    height: 48,
                    isLoading: _downloading,
                    onPressed: _downloading ? null : _startDownload,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    try {
      final success = widget.onDownload != null
          ? await widget.onDownload!(widget.info, (p) {
              if (mounted) setState(() => _progress = p);
            })
          : await UpdateService.downloadAndInstall(
              widget.info,
              onProgress: (p) {
                if (mounted) setState(() => _progress = p);
              },
            );

      if (!success && mounted) {
        setState(() {
          _downloading = false;
          _errorMessage = 'No se pudo completar la descarga de la actualización.';
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }
}
