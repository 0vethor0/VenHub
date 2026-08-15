import 'package:flutter/material.dart';
import '../../models/punto_camara.dart';
import '../../utils/reporte_export.dart';

class ReportExcelPreview extends StatelessWidget {
  final List<PuntoCamara> puntos;
  const ReportExcelPreview({super.key, required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa - Excel')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: columnasReporte
                      .map((c) => DataColumn(label: Text(c)))
                      .toList(),
                  rows: puntos.map((p) {
                    final fila = filaDesdePunto(p);
                    return DataRow(
                      cells: fila.map((v) => DataCell(Text(v))).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en Excel (guardar + abrir)'),
              onPressed: () async {
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
            ),
          ),
        ],
      ),
    );
  }
}
