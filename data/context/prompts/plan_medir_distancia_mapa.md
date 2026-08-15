# Plan de Acción — Herramienta de medición de distancias en el mapa (VenHub)

Agente IA: ejecuta este plan de forma secuencial. No pidas confirmación al usuario entre fases salvo bloqueo real (archivo inexistente, error de compilación irrecuperable, etc.). Aplica los cambios directamente en el código.

## Contexto
- App Flutter con `flutter_map` + `latlong2` ya en `pubspec.yaml`.
- Pantalla objetivo: `lib/screens/map/map_screen.dart`.
- Objetivo: añadir herramienta tipo “regla” de Google Earth. El usuario activa un modo, coloca dos puntos en el mapa, se dibuja una línea recta entre ellos y se muestra la distancia (metros o kilómetros).
- También debe existir un botón explícito para limpiar la medición actual del mapa.
- No agregar dependencias nuevas. Usar solo `flutter_map` (`PolylineLayer`, `MarkerLayer`) y `latlong2` (`Distance`).

---

## Fase 1 — Imports

Archivo: `lib/screens/map/map_screen.dart`

Asegura estos imports al inicio del archivo (sin duplicar):

```dart
import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
```

Si falta `import 'dart:math' show pi;`, añádelo. El resto de imports del archivo se mantienen.

---

## Fase 2 — Estado de medición en `_MapScreenState`

Dentro de la clase `_MapScreenState`, junto a las variables existentes (`_isEditMode`, `_currentLocation`, etc.), añade:

```dart
// Modo medición de distancia (regla)
bool _isMeasuring = false;
final List<LatLng> _measurePoints = [];
double? _measureDistanceMeters;

static const _distanceCalc = Distance();
```

---

## Fase 3 — Métodos de medición y limpieza

Añade estos métodos completos dentro de `_MapScreenState` (por ejemplo después de `_getMarkerColor`):

```dart
String _formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(1)} m';
}

void _toggleMeasureMode() {
  setState(() {
    _isMeasuring = !_isMeasuring;
    if (_isMeasuring) {
      // Salir de modo edición al activar medición
      _isEditMode = false;
      _draggingPointId = null;
      _isDraggingPropuesta = false;
      _isDraggingFibra = false;
    }
    _measurePoints.clear();
    _measureDistanceMeters = null;
  });
  if (_isMeasuring) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Modo medición: toca el mapa para colocar el primer punto.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

void _clearMeasurement() {
  setState(() {
    _measurePoints.clear();
    _measureDistanceMeters = null;
  });
}
```

---

## Fase 4 — Ampliar `_handleMapTap` para el modo medición

Reemplaza el método `_handleMapTap` existente por esta versión (mantiene la lógica de edición y añade prioridad a medición):

```dart
void _handleMapTap(TapPosition _, LatLng point) {
  // Prioridad: modo medición
  if (_isMeasuring) {
    setState(() {
      if (_measurePoints.length >= 2) {
        // Reiniciar con nuevo primer punto
        _measurePoints
          ..clear()
          ..add(point);
        _measureDistanceMeters = null;
      } else {
        _measurePoints.add(point);
        if (_measurePoints.length == 2) {
          _measureDistanceMeters = _distanceCalc(
            _measurePoints[0],
            _measurePoints[1],
          );
        }
      }
    });
    if (_measurePoints.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toca el segundo punto para medir la distancia.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

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
```

---

## Fase 5 — Activar `onTap` también en modo medición

En el `build`, dentro de `FlutterMap` → `options` → `MapOptions`, cambia el `onTap` para que también se active con medición:

```dart
onTap: (_isEditMode || _isMeasuring) ? _handleMapTap : null,
```

---

## Fase 6 — Capas de línea y marcadores de medición

Dentro de `FlutterMap` → `children`, **después** del `TileLayer` y **antes** de los `MarkerLayer` de puntos de cámara / propuestas / fibra, inserta la línea de medición:

```dart
// Línea de medición
if (_measurePoints.length == 2)
  PolylineLayer(
    polylines: [
      Polyline(
        points: List<LatLng>.from(_measurePoints),
        strokeWidth: 3.0,
        color: Colors.deepOrange,
        borderStrokeWidth: 1.5,
        borderColor: Colors.white,
      ),
    ],
  ),
```

**Después** de los MarkerLayer de puntos existentes (cámaras, propuestas, fibra) y **antes** del MarkerLayer de ubicación GPS (`_currentLocation`), inserta el MarkerLayer de los puntos de medición y la etiqueta de distancia.

Antes del `return Scaffold` (o al inicio del `build` después de filtrar listas), calcula el punto medio:

```dart
// Midpoint for distance label
LatLng? measureMidpoint;
if (_measurePoints.length == 2) {
  measureMidpoint = LatLng(
    (_measurePoints[0].latitude + _measurePoints[1].latitude) / 2,
    (_measurePoints[0].longitude + _measurePoints[1].longitude) / 2,
  );
}
```

Luego el MarkerLayer:

```dart
// Marcadores de los puntos de medición
if (_measurePoints.isNotEmpty)
  MarkerLayer(
    markers: [
      for (var i = 0; i < _measurePoints.length; i++)
        Marker(
          width: 20,
          height: 20,
          point: _measurePoints[i],
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      // Etiqueta de distancia en el punto medio
      if (measureMidpoint != null && _measureDistanceMeters != null)
        Marker(
          width: 110,
          height: 32,
          point: measureMidpoint,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade700,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              _formatDistance(_measureDistanceMeters!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
```

No elimines ni modifiques los MarkerLayer de puntos de cámara, propuestas, fibra ni el de ubicación actual.

---

## Fase 7 — Chip “Modo Medición” en la barra de filtros

En el `Row` horizontal de chips (junto a “Con Energía”, “Con Fibra Óptica”, contador de puntos y chip de modo edición), añade:

```dart
if (_isMeasuring)
  Chip(
    label: const Text(
      'Modo Medición',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    backgroundColor: Colors.deepOrange,
  ),
```

---

## Fase 8 — Banner inferior de distancia + botón limpiar en el banner

Dentro del `Stack` del `body`, añade (por ejemplo antes del `Positioned` de los FABs):

```dart
// Banner de distancia cuando hay medición completa
if (_measureDistanceMeters != null)
  Positioned(
    bottom: 100,
    left: 16,
    right: 80,
    child: Card(
      color: Colors.deepOrange.shade700,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(Icons.straighten, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Distancia: ${_formatDistance(_measureDistanceMeters!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Limpiar medición',
              onPressed: _clearMeasurement,
            ),
          ],
        ),
      ),
    ),
  ),
```

---

## Fase 9 — FABs: botón regla + botón limpiar medición

En el `Column` de FABs (abajo a la derecha), **añade al inicio** (antes del FAB de modo edición) el botón de medición y el de limpiar:

```dart
FloatingActionButton.small(
  heroTag: 'measure_btn',
  backgroundColor: _isMeasuring ? Colors.deepOrange : Colors.white,
  onPressed: _toggleMeasureMode,
  tooltip: _isMeasuring ? 'Salir de medición' : 'Medir distancia',
  child: Icon(
    Icons.straighten,
    color: _isMeasuring ? Colors.white : AppTheme.primaryBlue,
  ),
),
if (_measurePoints.isNotEmpty) ...[
  const SizedBox(height: 8),
  FloatingActionButton.small(
    heroTag: 'clear_measure_btn',
    backgroundColor: Colors.white,
    onPressed: _clearMeasurement,
    tooltip: 'Limpiar medición',
    child: const Icon(
      Icons.clear,
      color: Colors.deepOrange,
    ),
  ),
],
const SizedBox(height: 8),
```

Además, en el `onPressed` del FAB de modo edición existente, al activar edición desactiva medición y limpia puntos:

```dart
onPressed: () {
  setState(() {
    _isEditMode = !_isEditMode;
    if (_isEditMode) {
      _isMeasuring = false;
      _measurePoints.clear();
      _measureDistanceMeters = null;
    }
    if (!_isEditMode) {
      _draggingPointId = null;
      _isDraggingPropuesta = false;
      _isDraggingFibra = false;
    }
  });
},
```

Mantén el resto de FABs (`refresh`, `my_location`, `recenter`) intactos.

---

## Fase 10 — Verificación final

1. Confirma que no se agregaron dependencias nuevas en `pubspec.yaml`.
2. Confirma que `import 'dart:math' show pi;` está presente (usado por el marcador de ubicación GPS).
3. El archivo debe compilar: `Polyline`, `PolylineLayer`, `Distance`, `LatLng` resueltos.
4. No toques providers, modelos ni otras pantallas.
5. Comportamiento esperado:
   - Activar FAB regla → modo medición, SnackBar de instrucción.
   - Primer toque → marcador “1”.
   - Segundo toque → marcador “2”, línea, etiqueta de distancia y banner.
   - FAB limpiar (`Icons.clear`) visible cuando hay puntos; también el botón X del banner.
   - Desactivar FAB regla o limpiar → se quitan línea, marcadores y banner.
   - Modo edición y modo medición son mutuamente excluyentes.

---

## Orden de ejecución obligatorio

1. Fase 1 (imports)  
2. Fase 2 (estado)  
3. Fase 3 (métodos)  
4. Fase 4 (`_handleMapTap`)  
5. Fase 5 (`onTap` en MapOptions)  
6. Fase 6 (Polyline + MarkerLayer medición)  
7. Fase 7 (chip Modo Medición)  
8. Fase 8 (banner distancia)  
9. Fase 9 (FABs regla + limpiar)  
10. Fase 10 (verificación)

Al terminar, el mapa debe permitir medir distancias entre dos puntos, mostrar la línea y la distancia, y limpiar la medición con un botón dedicado sin afectar el resto de la funcionalidad del mapa.
