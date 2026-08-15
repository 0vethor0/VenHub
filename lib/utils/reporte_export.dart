import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/punto_camara.dart';

final List<String> columnasReporte = [
  'ID',
  'Coordenadas',
  'Tipo de zona',
  'Contexto Específico',
  'Existencia de poste',
  'Altura',
  'Disponibilidad de energía',
  'Nivel de Tensión',
  'Disponibilidad de fibra',
  'Distancia al nodo más cercano',
  'Medio de Transmisión Sugerido',
  'Índice Delictivo',
  'Flujo peatonal',
  'Flujo vehicular',
  'Puntos Ciegos',
  'Observaciones',
];

List<String> filaDesdePunto(PuntoCamara p) => [
  p.id,
  '${p.latitud}, ${p.longitud}',
  p.tipoZona ?? '',
  p.contextoEspecifico ?? '',
  p.existenciaPoste ? 'Sí' : 'No',
  p.alturaPosteMetros != null ? p.alturaPosteMetros!.toStringAsFixed(2) : '',
  p.energiaElectrica ? 'Sí' : 'No',
  p.nivelTension ?? '',
  p.fibraOptica ? 'Sí' : 'No',
  p.distanciaNodoMetros != null
      ? p.distanciaNodoMetros!.toStringAsFixed(2)
      : '',
  p.fibraOptica ? 'Fibra Óptica (sugerido automáticamente)' : 'Por definir',
  p.indiceDelictivo ?? '',
  p.flujoPeatonal ?? '',
  p.flujoVehicular ?? '',
  p.puntosCiegos ?? '',
  p.observaciones ?? '',
];

Excel generarExcelLevantamiento(List<PuntoCamara> puntos) {
  final excel = Excel.createExcel();
  final sheet = excel['Levantamiento'];

  // Header row (subtitles)
  // Use appendRow which accepts a List<dynamic>
  sheet.appendRow(columnasReporte.map((s) => TextCellValue(s)).toList());
  for (var r = 0; r < puntos.length; r++) {
    final fila = filaDesdePunto(puntos[r]);
    sheet.appendRow(fila.map((s) => TextCellValue(s)).toList());
  }

  return excel;
}

pw.Document generarPdfLevantamiento(List<PuntoCamara> puntos) {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headers: columnasReporte,
          data: puntos.map(filaDesdePunto).toList(),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerStyle: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  return doc;
}

Future<String?> _getDefaultDir() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  } catch (e) {
    return null;
  }
}

Future<String?> saveBytesToFile(Uint8List bytes, String filename) async {
  final dirPath = await _getDefaultDir();
  if (dirPath == null) return null;
  final file = File('$dirPath/$filename');
  await file.writeAsBytes(bytes, flush: true);
  try {
    await OpenFile.open(file.path);
  } catch (_) {}
  return file.path;
}

Future<String?> saveExcelFile(Excel excel, String filename) async {
  final enc = excel.encode();
  if (enc == null) return null;
  final bytes = Uint8List.fromList(enc);
  return saveBytesToFile(bytes, filename);
}

Future<String?> savePdfDocument(pw.Document doc, String filename) async {
  final bytes = await doc.save();
  return saveBytesToFile(Uint8List.fromList(bytes), filename);
}
