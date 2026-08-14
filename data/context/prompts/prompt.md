# Plan de acción: Corregir visualización de propuestas y arrastre de iconos en el mapa

Copia el bloque de abajo y pégalo como prompt al agente de tu IDE (Cursor, etc.).

---

## Prompt para el agente IA

```
# Tarea: Corregir 2 bugs del mapa en VenHub (Flutter)

## Contexto
App Flutter (ven911_app) con mapa en `lib/screens/map/map_screen.dart`.
Hay dos fallos reportados:

1. **Propuestas de cámara no se ven en el mapa**  
   Se crean bien en `propuesta_puntos_camara`, pero el icono verde no aparece.

2. **Arrastrar iconos para cambiar coordenadas no funciona**  
   En modo edición, long-press + mover debería actualizar `ubicacion`; actualmente no hace nada.

## Causa raíz (no reinventar)

### Bug 1
- `PointsProvider.fetchPropuestas()` hace solo `select('*')`.
- La columna `ubicacion` es PostGIS `geography`. Sin `ST_AsGeoJSON`, el parseo en `PropuestaPuntoCamara.fromMap` deja `latitud/longitud = 0` → marcador fuera de Yaracuy.
- Cámaras y fibra ya usan RPC con GeoJSON; propuestas no.

### Bug 2
- El flujo actual: long-press en marcador → long-press en mapa.
- `onLongPressEnd` del marcador **borra** `_draggingPointId` al soltar el dedo, así que al tocar el mapa el ID ya es null.

## Cambios a aplicar (archivos exactos)

### 1. `lib/models/propuesta_punto_camara.dart`

- Añadir `import 'dart:convert';` al inicio.
- Reemplazar el bloque de parseo de `ubicacion` en `fromMap` para soportar:
  - GeoJSON como `Map` con `coordinates: [lon, lat]`
  - WKT `POINT(lon lat)`
  - GeoJSON como `String` que empiece por `{`
  - Fallback a columnas `latitud`/`longitud`/`lat`/`lon` si tras parsear siguen en 0
- Añadir al final del archivo (fuera de la clase):

```dart
(double, double)? _tryDecodeGeoJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is Map && decoded['coordinates'] is List) {
    final coords = decoded['coordinates'] as List;
    if (coords.length >= 2) {
      return ((coords[0] as num).toDouble(), (coords[1] as num).toDouble());
    }
  }
  return null;
}
```

### 2. `lib/providers/points_provider.dart`

#### 2.1 `fetchPropuestas`
Sustituir el cuerpo para:
1. Intentar `rpc('get_propuesta_puntos_camara_geojson')`.
2. Si falla, fallback a `from('propuesta_puntos_camara').select('*')`.
3. Mapear con `PropuestaPuntoCamara.fromMap(item as Map<String, dynamic>)`.
4. Segundo try/catch de fallback igual que en `fetchPuntos` / FibraProvider.

#### 2.2 `crearPuntoPropuesta`
Tras el insert:
- Usar `.insert(insertData).select().maybeSingle()`.
- Si hay fila devuelta, copiar a un `Map`, forzar `map['latitud'] = lat` y `map['longitud'] = lon`, crear `PropuestaPuntoCamara.fromMap(map)` y añadirla a `_propuestas` + `notifyListeners()`.
- Después seguir llamando a `fetchPropuestas()` para sincronizar.

No cambiar la firma del método ni el resto de campos del insert.

### 3. `lib/screens/map/map_screen.dart`

#### 3.1 Sustituir handlers de mapa
Eliminar `_handleMapTapForNewPoint` y `_handleMapLongPress`.

Añadir:

```dart
void _handleMapTap(TapPosition _, LatLng point) {
  if (_isEditMode && _draggingPointId != null) {
    _placeDraggingPoint(point);
    return;
  }
  if (_isEditMode) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _NewPointTypeSheet(point: point),
    );
  }
}

void _startDragging({
  required String id,
  required bool isPropuesta,
  required bool isFibra,
}) {
  setState(() {
    _draggingPointId = id;
    _isDraggingPropuesta = isPropuesta;
    _isDraggingFibra = isFibra;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Mantén el modo edición. Toca el mapa para colocar el punto en la nueva ubicación.',
      ),
      duration: Duration(seconds: 3),
    ),
  );
}

void _cancelDragging() {
  if (_draggingPointId == null) return;
  setState(() {
    _draggingPointId = null;
    _isDraggingPropuesta = false;
    _isDraggingFibra = false;
  });
}

Future<void> _placeDraggingPoint(LatLng point) async {
  // Misma lógica que el antiguo _handleMapLongPress:
  // updateUbicacion según _isDraggingPropuesta / _isDraggingFibra
  // snackbar de éxito/error y limpiar estado
}
```

#### 3.2 `MapOptions`
```dart
onTap: _isEditMode ? _handleMapTap : null,
// quitar onLongPress del mapa
```

#### 3.3 Marcadores de propuestas
- Quitar `onLongPressStart` / `onLongPressEnd`.
- `onLongPress` (solo si `_isEditMode`): llamar `_startDragging(id: propuesta.id, isPropuesta: true, isFibra: false)`.
- En `onTap`: si `_draggingPointId == propuesta.id` → `_cancelDragging()` y return; si no, abrir `PropuestaFormModal` como ahora.

#### 3.4 Marcadores de fibra
Igual que propuestas, con `_startDragging(id: punto.id, isPropuesta: false, isFibra: true)` y cancel en tap del mismo icono.

#### 3.5 Filtro de propuestas
En `filteredPropuestas`, excluir puntos con `latitud == 0.0 && longitud == 0.0`.

#### 3.6 Botón modo edición
Al desactivar `_isEditMode`, también limpiar `_draggingPointId`, `_isDraggingPropuesta` y `_isDraggingFibra`.

### 4. SQL a documentar (no ejecutar desde Flutter)

Crear o dejar documentado en un comentario / archivo de notas el RPC:

```sql
CREATE OR REPLACE FUNCTION get_propuesta_puntos_camara_geojson()
RETURNS TABLE (
  id UUID,
  nombre TEXT,
  -- ... resto de columnas de propuesta_puntos_camara ...
  ubicacion JSON
) LANGUAGE sql STABLE AS $$
  SELECT
    id, nombre, /* columnas */,
    ST_AsGeoJSON(ubicacion)::json AS ubicacion
  FROM propuesta_puntos_camara;
$$;

GRANT EXECUTE ON FUNCTION get_propuesta_puntos_camara_geojson() TO authenticated;
GRANT EXECUTE ON FUNCTION get_propuesta_puntos_camara_geojson() TO anon;
```

Ajustar la lista de columnas al esquema real de la tabla (mismo patrón que `get_puntos_fibra_geojson`).

El cliente ya hace fallback a `select('*')` si el RPC no existe; el RPC es la solución robusta a largo plazo.

## Qué NO hacer
- No tocar PowerSync / offline en esta tarea.
- No añadir drag a puntos de cámara **existentes** (solo propuestas y fibra).
- No cambiar colores ni forma de los iconos.
- No refactorizar providers ni arquitectura en general.
- No inventar dependencias nuevas.

## Criterios de aceptación
1. Crear propuesta de mejora en modo edición → icono verde visible en el mapa al cerrar el modal.
2. Recargar / volver a entrar al mapa → las propuestas existentes siguen visibles (tras RPC o parseo mejorado).
3. Modo edición ON → long-press en propuesta o fibra → snackbar → tap en otra zona del mapa → coordenadas actualizadas en DB y marcador se mueve.
4. Tap de nuevo en el mismo icono o salir de modo edición → cancela el movimiento sin error.
5. `flutter analyze` sin errores nuevos en los archivos tocados.

## Orden de implementación
1. Modelo `propuesta_punto_camara.dart`
2. `points_provider.dart` (fetch + crear)
3. `map_screen.dart` (handlers + marcadores + filtro + toggle edición)
4. Dejar el SQL del RPC documentado para el equipo

Aplica los cambios archivo por archivo. No escribas ensayos: código primero.
```

---
