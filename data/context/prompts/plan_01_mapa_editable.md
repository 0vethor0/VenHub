# Plan de Acción — Feature 1: Mapa Interactivo Editable

**Parte de un set de 4 planes independientes:** `01_mapa_editable` (este) · `02_fibra_optica_y_campos_camara` · `03_calculadora_altura` · `04_exportacion_reportes`.
**Archivos que esta feature comparte con las otras 3** (coordina merges si se trabajan en paralelo): `lib/models/punto_camara.dart`, `pubspec.yaml`.
**No depende de** Feature 2, 3 ni 4 para funcionar — se puede mergear y probar sola.

---

## 0. Decisiones tomadas (revisar antes de ejecutar)

1. **El mapa hoy ya usa color para "estado"** (rojo/amarillo/verde según energía+fibra, en `map_screen.dart`). Pediste rojo = "punto existente" — eso pisa esa señal. Decisión: color sigue siendo estado en cámaras existentes; el **tipo** de punto se distingue por forma+ícono, no por color. Es también requisito de accesibilidad (no comunicar info solo con color).
2. **El punto "propuesta de mejora" (amarillo) no tenía modelo de datos.** Se resuelve como fila nueva en `puntos_camara` con `tipo_punto='propuesta_mejora'` y FK a sí misma (`punto_referencia_id`) apuntando al punto que mejora. Reutiliza modal, provider y stream existentes — no crea tabla nueva. Si la intención era otra (1 propuesta máx. por punto, o que reemplace en vez de coexistir), es un ajuste de una línea en el `CHECK`/lógica, avisar antes de implementar.
3. **A qué cámara se enlaza cada propuesta:** se sugiere automáticamente la más cercana (Haversine con `latlong2`, ya es dependencia del proyecto) y el usuario la puede cambiar en un dropdown — nunca se asigna en silencio.
4. **Nombre del toggle:** nada de "anclar/desanclar" — `puntos_camara` ya se llaman "puntos anclados" en el dominio, y reusar la palabra para bloquear el mapa genera ambigüedad real en campo. Se usa **"Modo edición"** ON/OFF, un solo control (no dos acciones separadas, para no tener un estado intermedio ambiguo).

---

## 1. Base de datos — único cambio de esquema que requiere esta feature

```sql
ALTER TABLE puntos_camara
  ADD COLUMN tipo_punto TEXT NOT NULL DEFAULT 'existente'
    CHECK (tipo_punto IN ('existente', 'propuesta_mejora')),
  ADD COLUMN punto_referencia_id UUID REFERENCES puntos_camara(id) ON DELETE SET NULL;

COMMENT ON COLUMN puntos_camara.punto_referencia_id IS
  'Si tipo_punto = propuesta_mejora, apunta al punto original que esta propuesta busca mejorar o reemplazar';
```

Los 181 puntos existentes quedan `tipo_punto='existente'` por el `DEFAULT`, sin migración de datos adicional.

Si Feature 2 (fibra óptica) ya corrió su propio `ALTER TABLE puntos_camara` primero, este es un `ALTER` adicional sobre la misma tabla — no hay conflicto, son columnas distintas. Si se ejecutan en paralelo, correr ambos `ALTER` en la misma migración evita dos migraciones separadas tocando la misma tabla el mismo día.

---

## 2. Modelo Flutter — `lib/models/punto_camara.dart`

Agregar:

```dart
final String tipoPunto; // 'existente' | 'propuesta_mejora'
final String? puntoReferenciaId;
```

`fromMap`: `tipoPunto: map['tipo_punto'] ?? 'existente'`, `puntoReferenciaId: map['punto_referencia_id']`.
`toMap`: agregar `'tipo_punto': tipoPunto, 'punto_referencia_id': puntoReferenciaId`.

`ponytail:` no crees una clase `PuntoPropuesta` separada. Es un `PuntoCamara` con `tipoPunto` distinto — un string discrimina, no una clase nueva.

---

## 3. Provider — `lib/providers/points_provider.dart`

`fetchPuntos()` ya trae `tipo_punto` con el `select('*')` existente — sin cambios de query.

Agregar:

```dart
List<PuntoCamara> get puntosExistentes =>
    _puntos.where((p) => p.tipoPunto == 'existente').toList();

List<PuntoCamara> get puntosPropuesta =>
    _puntos.where((p) => p.tipoPunto == 'propuesta_mejora').toList();

Future<bool> crearPuntoPropuesta({
  required double lat,
  required double lon,
  required String puntoReferenciaId,
  required Map<String, dynamic> datosAdicionales,
}) async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('puntos_camara').insert({
      'ubicacion': 'POINT($lon $lat)',
      'tipo_punto': 'propuesta_mejora',
      'punto_referencia_id': puntoReferenciaId,
      'actualizado_por': userId,
      ...datosAdicionales,
    });
    await fetchPuntos();
    return true;
  } catch (e) {
    _errorMessage = e.toString();
    notifyListeners();
    return false;
  }
}
```

---

## 4. Toggle de modo edición — `lib/screens/map/map_screen.dart`

```dart
bool _isEditMode = false;

FloatingActionButton.small(
  heroTag: 'edit_mode_btn',
  backgroundColor: _isEditMode ? AppTheme.warningYellow : Colors.white,
  child: Icon(
    _isEditMode ? Icons.edit_off : Icons.edit_location_alt,
    color: _isEditMode ? Colors.white : AppTheme.primaryBlue,
  ),
  onPressed: () => setState(() => _isEditMode = !_isEditMode),
),
```

Comportamiento:
- **OFF (default):** idéntico al actual — pan, zoom, tap en marcador abre el modal. Nada nuevo se crea por accidente.
- **ON:** tap en el mapa vacío abre el selector de tipo de punto nuevo. Los marcadores existentes se siguen pudiendo tocar para editarlos.

---

## 5. Tap en mapa vacío → selector de tipo de punto

```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: _initialCenter,
    initialZoom: 13.0,
    onTap: _isEditMode ? _handleMapTapForNewPoint : null,
  ),
  ...
)

void _handleMapTapForNewPoint(TapPosition _, LatLng point) {
  showModalBottomSheet(
    context: context,
    builder: (_) => _NewPointTypeSheet(point: point),
  );
}
```

`_NewPointTypeSheet` ofrece **una sola opción de este feature**: "Amarillo — Propuesta de mejora de cámara" (la opción "Azul — Fibra óptica" la agrega Feature 2, en el mismo sheet, cuando esa feature esté mergeada; si Feature 2 no está lista aún, el sheet de este PR solo muestra la opción amarilla). Rojo no es seleccionable — es el estado de un punto que ya existe, no un tipo que el usuario crea.

Cálculo de cámara más cercana antes de abrir el formulario:

```dart
import 'package:latlong2/latlong.dart';

PuntoCamara? nearestCamara(LatLng point, List<PuntoCamara> puntos) {
  const dist = Distance();
  PuntoCamara? nearest;
  double best = double.infinity;
  for (final p in puntos) {
    final d = dist(point, LatLng(p.latitud, p.longitud));
    if (d < best) { best = d; nearest = p; }
  }
  return nearest;
}
```

Se muestra como sugerencia preseleccionada en un dropdown editable dentro del formulario — nunca se asigna en silencio.

---

## 6. Capas del mapa — forma + color + ícono

| Capa | Forma | Color | Ícono |
|---|---|---|---|
| Cámara existente (estado ya calculado) | Círculo (como hoy) | Rojo/Amarillo/Verde según energía+fibra — **sin cambios** | `videocam` |
| Propuesta de mejora (`tipo_punto='propuesta_mejora'`) | Diamante (`Transform.rotate` 45°) | Amarillo (`AppTheme.warningYellow`) | `videocam` + badge `arrow_upward` pequeño |

(La capa de fibra óptica —cuadrado azul— la agrega Feature 2 sobre esta misma estructura de `MarkerLayer`.)

Dos `MarkerLayer` dentro del mismo `FlutterMap`, cada uno filtrado desde `pointsProvider.puntosExistentes` / `pointsProvider.puntosPropuesta`. Agregar `FilterChip` en la barra de búsqueda existente para mostrar/ocultar cada capa — extiende la lista de chips que ya existe (`_filterEnergiaOnly`, `_filterFibraOnly`), no un widget nuevo.

---

## 7. Reutilización del modal — `point_form_modal.dart`

`PointFormModal` ya recibe un `PuntoCamara`. Para un punto nuevo (no guardado aún), constrúyelo con `id: ''` y valores por defecto; en `_saveChanges()` distingue `insert` (llama a `crearPuntoPropuesta`) vs `update` (flujo actual) según `widget.punto.id.isEmpty`. No dupliques el modal para "punto nuevo" — es el mismo formulario con un branch en el guardado.

---

## 8. Fase de Validación

Ejecutar en este orden, corrigiendo antes de avanzar al siguiente paso:

1. **`flutter test`**
   - Test mínimo sugerido para esta feature (lógica pura, fácil de romper en silencio si alguien reordena `latlong2.Distance`):
     ```dart
     // test/nearest_camara_test.dart
     import 'package:flutter_test/flutter_test.dart';
     import 'package:latlong2/latlong.dart';
     import 'package:ven911_app/screens/map/map_screen.dart'; // ajustar export si nearestCamara se mueve a un helper

     void main() {
       test('nearestCamara devuelve el punto más cercano, no el primero de la lista', () {
         final tap = LatLng(10.0, -68.0);
         final lejano = PuntoCamara(id: '1', nombre: 'A', latitud: 10.5, longitud: -68.5);
         final cercano = PuntoCamara(id: '2', nombre: 'B', latitud: 10.001, longitud: -68.001);
         final resultado = nearestCamara(tap, [lejano, cercano]);
         expect(resultado?.id, '2');
       });
     }
     ```
   - Si algún test existente falla por este cambio, corrige el código o el test — nunca borres un test para que pase.
2. **`flutter analyze`**
   - Cero errores antes de continuar. Corrige los warnings que introduce este cambio; no arrastres limpieza de warnings preexistentes ajenos a este PR.
   - Si aparece un error, corrígelo y vuelve a correr `flutter test` antes de seguir.
3. **`dart format .`**
   - Sobre todo el repo, no solo los archivos tocados.
   - Si formatea archivos que esta feature no tocó, sepáralos en un commit aparte (`chore: dart format`) para no inflar el diff de revisión.

Orden importa: test → analyze → format. Formatear antes de que el análisis esté limpio puede enmascarar errores reales bajo cambios cosméticos de diff.
