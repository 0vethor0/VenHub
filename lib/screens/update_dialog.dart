import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/version_update_provider.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VersionUpdateProvider>(
      builder: (context, provider, child) {
        final bool isRequired = provider.isRequired;
        final bool isDownloading = provider.isDownloading;
        final String? errorMsg = provider.errorMessage;
        final bool isSignatureConflict = provider.isSignatureConflict;
        final int? apkSize = provider.apkSizeBytes;

        return PopScope(
          canPop: !isRequired,
          onPopInvokedWithResult: (didPop, result) {
            if (isRequired && !didPop) {
              // Absorb pop
            }
          },
          child: Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isRequired
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF334155),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isRequired
                                ? [
                                    const Color(0xFFDC2626),
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    const Color(0xFF0284C7),
                                    const Color(0xFF0F172A),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isRequired
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF0284C7))
                                      .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      if (isRequired)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OBLIGATORIA',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Actualización Disponible',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nueva Versión: v${provider.latestVersion}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isRequired
                          ? const Color(0xFFF87171)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                  if (provider.currentVersionName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Versión actual: v${provider.currentVersionName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  if (apkSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tamaño: ${VersionUpdateProvider.formatBytes(apkSize)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  if (isDownloading) ...[
                    const Text(
                      'Descargando actualización...',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: provider.downloadProgress > 0
                            ? provider.downloadProgress
                            : null,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isRequired
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.downloadProgress > 0
                          ? '${(provider.downloadProgress * 100).toStringAsFixed(0)}%'
                          : 'Preparando...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ] else if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            errorMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 13,
                            ),
                          ),
                          if (isSignatureConflict) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Ve a Ajustes → Aplicaciones → VenHub → Desinstalar, '
                              'luego instala la versión de release.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isSignatureConflict) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.openAppSettingsForUninstall,
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('Abrir configuración'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        if (!isRequired) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF334155),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                provider.downloadAndInstallUpdate(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    if (provider.isDebugBuild) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Estás en versión de desarrollo. Si la instalación falla, '
                          'desinstala esta app e instala la versión release.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      isRequired
                          ? 'Esta actualización es obligatoria para seguir utilizando la aplicación de forma segura.'
                          : 'Hay una nueva versión de VenHub disponible con mejoras importantes. ¿Deseas descargarla ahora?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.downloadAndInstallUpdate,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Actualizar Ahora'),
                          ),
                        ),
                        if (!isRequired) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Omitir por ahora',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
