import 'package:flutter/material.dart';
import '../../models/punto_camara.dart';
import '../../utils/reporte_export.dart';

class ReportTablePreview extends StatelessWidget {
  final List<PuntoCamara> puntos;
  const ReportTablePreview({super.key, required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa - Tabla')),
      body: SingleChildScrollView(
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
    );
  }
}
