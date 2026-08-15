import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/points_provider.dart';
import '../../theme/app_theme.dart';
import '../map/widgets/point_form_modal.dart';
import '../../utils/reporte_export.dart';
import '../../models/punto_camara.dart';
import 'report_table_preview.dart';
import 'report_pdf_preview.dart';
import 'report_excel_preview.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static String _timeAgo(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'ahora';
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Instalación'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar levantamiento (Excel / PDF)',
            onPressed: () => _showExportDialog(context, pointsProvider.puntos),
          ),
        ],
      ),
      body: pointsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pointsProvider.puntos.length,
              itemBuilder: (ctx, i) {
                final punto = pointsProvider.puntos[i];
                String estado = 'RECOMENDADO';
                Color estadoColor = AppTheme.successGreen;
                if (!punto.energiaElectrica && !punto.fibraOptica) {
                  estado = 'INTERFERENCIA';
                  estadoColor = AppTheme.dangerRed;
                } else if (!punto.energiaElectrica || !punto.fibraOptica) {
                  estado = 'TÉCNICO';
                  estadoColor = AppTheme.warningYellow;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      punto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${punto.id.length >= 8 ? punto.id.substring(0, 8) : punto.id} • ${_timeAgo(punto.actualizadoEn)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: estadoColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Domo IP 4K',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => PointFormModal(punto: punto),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showExportDialog(BuildContext context, List<PuntoCamara> puntos) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar / Vista previa'),
        content: const Text('Seleccione una acción'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final excel = generarExcelLevantamiento(puntos);
              final filename =
                  'levantamiento_${DateTime.now().millisecondsSinceEpoch}.xlsx';
              final path = await saveExcelFile(excel, filename);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    path != null
                        ? 'Excel guardado en: $path'
                        : 'Error al guardar Excel',
                  ),
                ),
              );
            },
            child: const Text('Exportar Excel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final doc = generarPdfLevantamiento(puntos);
              final filename =
                  'levantamiento_${DateTime.now().millisecondsSinceEpoch}.pdf';
              final path = await savePdfDocument(doc, filename);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    path != null
                        ? 'PDF guardado en: $path'
                        : 'Error al guardar PDF',
                  ),
                ),
              );
            },
            child: const Text('Exportar PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportTablePreview(puntos: puntos),
                ),
              );
            },
            child: const Text('Vista previa (Tabla)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportPdfPreview(puntos: puntos),
                ),
              );
            },
            child: const Text('Vista previa (PDF)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportExcelPreview(puntos: puntos),
                ),
              );
            },
            child: const Text('Vista previa (Excel)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
