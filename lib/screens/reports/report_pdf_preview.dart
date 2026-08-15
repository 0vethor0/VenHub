import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/punto_camara.dart';
import '../../utils/reporte_export.dart';

class ReportPdfPreview extends StatelessWidget {
  final List<PuntoCamara> puntos;
  const ReportPdfPreview({super.key, required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa - PDF')),
      body: PdfPreview(
        build: (format) async {
          final doc = generarPdfLevantamiento(puntos);
          return doc.save();
        },
      ),
    );
  }
}
