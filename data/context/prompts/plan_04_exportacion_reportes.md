# Plan de Acción — Feature 4: Exportación de Reportes (Excel / PDF)

**Parte de un set de 4 planes independientes:** `01_mapa_editable` · `02_fibra_optica_y_campos_camara` · `03_calculadora_altura` · `04_exportacion_reportes` (este).
**Archivos que esta feature comparte con las otras:** `pubspec.yaml`.
**No depende de** ninguna otra feature para funcionar — exporta con las columnas que existan en `puntos_camara` al momento del build. Si Feature 2 (fibra/campos nuevos) aún no está mergeada, simplemente esas columnas van vacías en el reporte; no rompe nada.

---

## 0. Ubicación del botón

`ReportsScreen` (`lib/screens/reports/reports_screen.dart`) ya lista todos los puntos con su estado — es la pantalla natural, no una nueva. Agregar acción en el `AppBar`:

```dart
AppBar(
  title: const Text('Reportes de Instalación'),
  automaticallyImplyLeading: false,
  actions: [
    IconButton(
      icon: const Icon(Icons.ios_share),
      tooltip: 'Exportar levantamiento (Excel / PDF)',
      onPressed: () => _showExportDialog(context),
    ),
  ],
),
```

`_showExportDialog` pregunta formato (Excel / PDF / ambos) con un `AlertDialog` de tres opciones — no hace falta un widget nuevo para esto.

---

## 1. Dependencias nuevas

```yaml
dependencies:
  pdf: ^3.11.0
  printing: ^5.13.0
  excel: ^4.0.6
```

`ponytail:` no agregues nada para "ver el archivo en la app". Ya tienes `open_file` y `path_provider` instalados — cubren guardar y abrir con el visor nativo del sistema, que es el 90% del valor. El matiz de vista previa embebida está en la sección 5.

---

## 2. Estructura de columnas — replicando `VEN911__LEVANTAMIENTO_DE_INFORMACIÓN.xlsx`

El archivo de referencia define 16 columnas agrupadas en 5 secciones (header combinado + subtítulo). Mapeo columna → origen de dato:

| Sección (header combinado, color de fondo en el Excel de referencia) | Columna | Origen |
|---|---|---|
| Ubicación y Contexto Estratégico | ID | `punto.id` |
| " | Coordenadas | `"${punto.latitud}, ${punto.longitud}"` |
| " | Tipo de zona | `punto.tipoZona` |
| " | Contexto Específico | `punto.contextoEspecifico` |
| Infraestructura y Energía — Azul `#0070C0` | Existencia de poste | `punto.existenciaPoste` |
| " | Altura | `punto.alturaPosteMetros` |
| " | Disponibilidad de energía | `punto.energiaElectrica` |
| " | Nivel de Tensión | `punto.nivelTension` |
| Conectividad y Red — Amarillo `#FFFF00` | Disponibilidad de fibra | `punto.fibraOptica` |
| " | Distancia al nodo más cercano | `punto.distanciaNodoMetros` |
| " | Medio de Transmisión Sugerido | **no existe en el schema actual — ver nota abajo** |
| Seguridad — Rojo `#FF0000` | Índice Delictivo | `punto.indiceDelictivo` |
| " | Flujo peatonal | `punto.flujoPeatonal` |
| " | Flujo vehicular | `punto.flujoVehicular` |
| " | Puntos Ciegos | `punto.puntosCiegos` |
| Hardware | Observaciones | `punto.observaciones` |

**Nota honesta, no la escondas:** "Medio de Transmisión Sugerido" está en la plantilla de referencia pero no existe como campo en `puntos_camara` ni fue especificado en ninguna de las otras 3 features. No lo inventes en silencio con un valor derivado — confirma con el equipo de campo si es (a) un campo nuevo de texto libre a agregar al schema, o (b) un valor derivado automáticamente (`fibraOptica ? 'Fibra Óptica' : 'Radioenlace / Por definir'`). Si no hay respuesta antes de implementar, usa la opción derivada y márcala en el reporte como *"(sugerido automáticamente)"* — que nadie la lea como dato de campo real.

También nota: la sección "Hardware" en la plantilla de referencia solo contiene "Observaciones", no columnas de modelo/tipo de cámara. Si se necesita eso más adelante, es un `ALTER` aparte — no lo agregues ahora sin que lo pidan (YAGNI).

Centraliza este mapeo en **una sola función**, reusada tanto por el generador de Excel como el de PDF — si el orden de columnas queda hardcodeado dos veces (una por formato), un cambio futuro solo actualiza uno de los dos sin que nadie lo note hasta producción:

```dart
List<String> columnasReporte = [
  'ID', 'Coordenadas', 'Tipo de zona', 'Contexto Específico',
  'Existencia de poste', 'Altura', 'Disponibilidad de energía', 'Nivel de Tensión',
  'Disponibilidad de fibra', 'Distancia al nodo más cercano', 'Medio de Transmisión Sugerido',
  'Índice Delictivo', 'Flujo peatonal', 'Flujo vehicular', 'Puntos Ciegos',
  'Observaciones',
];

List<String> filaDesdePunto(PuntoCamara p) => [
  p.id,
  '${p.latitud}, ${p.longitud}',
  p.tipoZona ?? '',
  p.contextoEspecifico ?? '',
  p.existenciaPoste ? 'Sí' : 'No',
  p.alturaPosteMetros?.toStringAsFixed(2) ?? '',
  p.energiaElectrica ? 'Sí' : 'No',
  p.nivelTension ?? '',
  p.fibraOptica ? 'Sí' : 'No',
  p.distanciaNodoMetros?.toStringAsFixed(2) ?? '',
  p.fibraOptica ? 'Fibra Óptica (sugerido automáticamente)' : 'Por definir',
  p.indiceDelictivo ?? '',
  p.flujoPeatonal ?? '',
  p.flujoVehicular ?? '',
  p.puntosCiegos ?? '',
  p.observaciones ?? '',
];
```

---

## 3. Generación de Excel

```dart
import 'package:excel/excel.dart';

Excel generarExcelLevantamiento(List<PuntoCamara> puntos) {
  final excel = Excel.createExcel();
  final sheet = excel['Levantamiento'];

  // fila 0: título fusionado
  // fila 1: headers de sección con color de fondo (tabla arriba)
  // fila 2: columnasReporte como subtítulos
  // filas 3+: filaDesdePunto(p) por cada punto

  for (var i = 0; i < columnasReporte.length; i++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2))
        .value = TextCellValue(columnasReporte[i]);
  }
  for (var r = 0; r < puntos.length; r++) {
    final fila = filaDesdePunto(puntos[r]);
    for (var c = 0; c < fila.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 3))
          .value = TextCellValue(fila[c]);
    }
  }
  return excel;
}
```

El merge de celdas y el fill de color de sección (usando los hex de la tabla de la sección 2) se completan con `CellStyle` del paquete `excel` — mecánico una vez que el orden de columnas está fijo, no aporta detallar cada llamada aquí.

---

## 4. Generación de PDF

```dart
import 'package:pdf/widgets.dart' as pw;

pw.Document generarPdfLevantamiento(List<PuntoCamara> puntos) {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, // 16 columnas no caben en portrait
      build: (context) => [
        pw.Table.fromTextArray(
          headers: columnasReporte,
          data: puntos.map(filaDesdePunto).toList(),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
  return doc;
}
```

---

## 5. Guardar, abrir, y el costo real de "verlo dentro de la app"

Guardar con `path_provider` y abrir con `open_file` (ambos ya instalados) es gratis en dependencias nuevas y cubre el 90% del valor con un visor nativo (Excel/Sheets/Adobe, según lo que tenga el celular):

```dart
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/levantamiento_${DateTime.now().millisecondsSinceEpoch}.xlsx');
await file.writeAsBytes(excel.encode()!);
await OpenFile.open(file.path);
```

**Sobre "verlo directamente dentro de la app", sin endulzarlo:**
- **PDF:** barato y vale la pena. `printing` (ya en la lista de deps de esta feature) trae `PdfPreview`, un widget que renderiza el PDF dentro de tu propia UI de Flutter sin depender del visor del sistema. Es la pareja natural de `pdf`, agrégalo.
- **Excel:** no hay equivalente gratuito real para un grid de Excel embebido en Flutter. Las opciones son Syncfusion (licencia community con condiciones que hay que leer, no es "gratis sin restricciones") o construir una tabla propia. Como ya tienes los datos en memoria antes de exportar, la opción barata es mostrar un `DataTable` de Flutter con los mismos datos en una pantalla de "vista previa" — no le pidas a la app que abra y parsee el `.xlsx` que ella misma generó, es trabajo duplicado para un resultado que ya tenías. Se recomienda esto último, dejando el `.xlsx` real solo para exportar/compartir.

```dart
DataTable(
  columns: columnasReporte.map((c) => DataColumn(label: Text(c))).toList(),
  rows: puntos.map((p) => DataRow(
    cells: filaDesdePunto(p).map((v) => DataCell(Text(v))).toList(),
  )).toList(),
)
```

Envuelto en `SingleChildScrollView` horizontal y vertical — 16 columnas no caben en una pantalla de teléfono sin scroll horizontal, no lo omitas.

---

## 6. Fase de Validación

1. **`flutter test`**
   - `filaDesdePunto` es la función que más silenciosamente se rompe (alguien reordena una columna en `columnasReporte` sin actualizar el mapeo, y el reporte queda desalineado sin que nada truene en tiempo de compilación):
     ```dart
     // test/reporte_columnas_test.dart
     import 'package:flutter_test/flutter_test.dart';
     import 'package:ven911_app/models/punto_camara.dart';
     import 'package:ven911_app/utils/reporte_export.dart'; // ajustar import según dónde queden columnasReporte/filaDesdePunto

     void main() {
       test('filaDesdePunto respeta el orden de columnasReporte', () {
         final punto = PuntoCamara(
           id: 'xyz',
           nombre: 'Test',
           latitud: 10.0,
           longitud: -68.0,
           tipoZona: 'Comercial',
           existenciaPoste: true,
         );
         final fila = filaDesdePunto(punto);
         expect(fila.length, columnasReporte.length);
         expect(fila[0], 'xyz');           // ID
         expect(fila[2], 'Comercial');     // Tipo de zona
         expect(fila[4], 'Sí');            // Existencia de poste
       });
     }
     ```
   - Si algún test existente falla por este cambio, corrige el código o el test — nunca borres un test para que pase.
2. **`flutter analyze`**
   - Cero errores antes de continuar. Corrige los warnings que introduce este cambio; no arrastres limpieza de warnings preexistentes ajenos a este PR.
   - Si aparece un error, corrígelo y vuelve a correr `flutter test` antes de seguir.
3. **`dart format .`**
   - Sobre todo el repo, no solo los archivos tocados.
   - Si formatea archivos que esta feature no tocó, sepáralos en un commit aparte (`chore: dart format`).

Orden importa: test → analyze → format.
