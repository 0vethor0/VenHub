# Plan de Acción v2 — Herramienta de medición de distancias en el mapa (VenHub)

Agente IA: ejecuta este plan **por fases, pero NO de forma autónoma continua**.
Después de cada fase marcada con 🛑 (CHECKPOINT), detente, muestra el diff y
espera confirmación explícita antes de continuar. El resto de las fases
pueden encadenarse sin pedir confirmación salvo bloqueo real
(archivo inexistente, error de compilación irrecuperable).

## Actualización (v3, nueva info de gerencia)

Cambio de premisa: campo YA NO tiene cinta métrica ni instrumento preciso.
Solo tantean, tipo regla de Google Earth. "Distancia al Nodo" y "Distancia a
cámara" pasan a ser aproximados por diseño — la advertencia de la v2 sobre
"no sobrescribir medición real" queda sin objeto: ya no hay medición real que
proteger. El ruler pasa a ser el método oficial de captura, no un atajo
opcional con fricción.

Consecuencia: Parte B se simplifica — sin chip de sugerencia, sin paso extra
de confirmación. Auto-rellena el campo, editable, listo. Ver Parte B
reescrita más abajo.

Nota que se mantiene, no se negocia: distancia en línea recta ≠ longitud real
de cable (el cable no cruza manzanas en diagonal). Sigue siendo la mejor
aproximación disponible dado que no hay otra herramienta — pero si algún
reporte usa este campo para presupuestar metros de fibra, that gap no
desaparece solo porque ahora es "oficial". Bandera puesta, decisión es de
gerencia, no mía.

`Medio de Transmisión Sugerido` queda fuera de este plan — ya no es campo
prioritario, ningún fase lo toca.

## Contexto y por qué esta v2 existe

La v1 de este plan tenía dos problemas encontrados en revisión:

1. **Conflicto de gestos no resuelto**: los `Marker` de cámaras, propuestas y
   fibra tienen su propio `GestureDetector.onTap`, que consume el toque antes
   de que llegue a `MapOptions.onTap`. En modo medición, tocar cerca de un
   punto existente abría su modal de edición en vez de colocar un punto de
   medición — rompiendo el caso de uso principal (medir entre puntos ya
   cargados).
2. **Los campos "Distancia al Nodo (Metros)" (`propuesta_form_modal.dart`) y
   "Distancia a cámara (m)" (`fibra_form_modal.dart`) NO son distancias en
   línea recta.** Vienen del levantamiento de campo original
   (`VEN911__LEVANTAMIENTO_DE_INFORMACIÓN.xlsx`) y el propio diseño del
   schema de `puntos_fibra_optica` documenta explícitamente que se dejan como
   campo manual (no calculado) porque el usuario los mide en terreno con
   cinta métrica, y la ruta real del cable no coincide con la línea recta del
   mapa (postes, obstáculos, esquinas). **Esta v2 nunca escribe en esos
   campos automáticamente.**

## Contexto técnico (igual que v1)

- App Flutter con `flutter_map` + `latlong2` ya en `pubspec.yaml`.
- Pantalla objetivo: `lib/screens/map/map_screen.dart`.
- Modales relacionados: `lib/screens/map/widgets/propuesta_form_modal.dart`,
  `lib/screens/map/widgets/fibra_form_modal.dart`.
- No agregar dependencias nuevas. Usar solo `flutter_map`
  (`PolylineLayer`, `MarkerLayer`) y `latlong2` (`Distance`).

---

## PARTE A — Ruler genérico (uso libre, no toca ningún modelo de datos)

### Fase A1 — Imports

Archivo: `lib/screens/map/map_screen.dart`

Confirma estos imports (sin duplicar); si falta `dart:math`, agrégalo —
el archivo actual usa `pi` en el marcador de rotación GPS sin importarlo,
así que esto corrige una fuga preexistente de paso:

```dart
import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
```

### Fase A2 — Estado de medición en `_MapScreenState`

Junto a las variables existentes (`_isEditMode`, `_currentLocation`, etc.):

```dart
// Modo medición de distancia (regla)
bool _isMeasuring = false;
final List<LatLng> _measurePoints = [];
double? _measureDistanceMeters;

static const _distanceCalc = Distance();
```

**Verificación previa obligatoria:** antes de escribir esta línea, confirma
con `dart doc` o el código fuente de `latlong2` que `Distance()` tiene
constructor `const`. Si no lo tiene, quita `const` de la declaración.

### Fase A3 — Métodos de medición

Añade dentro de `_MapScreenState` (después de `_getMarkerColor`):

```dart
String _formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(1)} m';
}

void _addMeasurePoint(LatLng point) {
  setState(() {
    if (_measurePoints.length >= 2) {
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
}

void _toggleMeasureMode() {
  setState(() {
    _isMeasuring = !_isMeasuring;
    if (_isMeasuring) {
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
        content: Text('Modo medición: toca el mapa o un punto existente.'),
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

Nota: `_addMeasurePoint` centraliza la lógica que en la v1 estaba duplicada
dentro de `_handleMapTap`. Esto es intencional — la misma función se usa
tanto para toques en el mapa vacío (Fase A4) como para toques sobre
marcadores existentes (Fase A5), evitando dos implementaciones que puedan
desincronizarse.

### Fase A4 — `_handleMapTap` (toques en área vacía del mapa)

Reemplaza el método existente:

```dart
void _handleMapTap(TapPosition _, LatLng point) {
  if (_isMeasuring) {
    _addMeasurePoint(point);
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

Y en `MapOptions`:

```dart
onTap: (_isEditMode || _isMeasuring) ? _handleMapTap : null,
```

### 🛑 Fase A5 — CHECKPOINT: guardas de medición en los tres `MarkerLayer` existentes

**Esta es la fase que corrige el bug real encontrado en revisión.** Sin esto,
el resto del plan produce una herramienta que no funciona sobre los puntos
que el usuario más quiere medir.

En el `onTap` del `GestureDetector` de los marcadores de **cámaras**
(`filteredExistentes`), antepón la guarda de medición:

```dart
onTap: () {
  if (_isMeasuring) {
    _addMeasurePoint(LatLng(punto.latitud, punto.longitud));
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PointFormModal(punto: punto),
  );
},
```

En el `onTap` de los marcadores de **propuestas**:

```dart
onTap: () {
  if (_isMeasuring) {
    _addMeasurePoint(LatLng(propuesta.latitud, propuesta.longitud));
    return;
  }
  if (_draggingPointId == propuesta.id) {
    _cancelDragging();
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PropuestaFormModal(propuesta: propuesta),
  );
},
```

En el `onTap` de los marcadores de **fibra**:

```dart
onTap: () {
  if (_isMeasuring) {
    _addMeasurePoint(LatLng(punto.latitud, punto.longitud));
    return;
  }
  if (_draggingPointId == punto.id) {
    _cancelDragging();
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => FibraFormModal(punto: punto),
  );
},
```

No es necesario tocar los `onLongPress` — ya son `null` cuando `_isEditMode`
es `false`, y `_toggleMeasureMode` garantiza que `_isEditMode` esté en
`false` mientras se mide.

**Detente aquí y muestra el diff completo de esta fase.** Es la parte con
más riesgo de romper la lógica de arrastre existente (`_draggingPointId`).

### Fase A6 — Capas visuales de medición

Igual que v1: `PolylineLayer` después del `TileLayer` y antes de los
`MarkerLayer` de puntos; `MarkerLayer` de puntos de medición + etiqueta de
distancia después de los marcadores existentes y antes del de ubicación GPS.
(Sin cambios respecto al plan original — omito repetir el snippet completo
por espacio; usar el de la Fase 6 de v1 tal cual, ya verificado contra el
archivo real.)

### Fase A7 — UI simplificada (reducida respecto a v1)

La v1 proponía 4 elementos para 2 acciones (FAB toggle, chip de texto,
banner, FAB de limpiar). Se recorta a 2:

- **FAB toggle** (`measure_btn`), con color de estado — como v1.
- **Banner inferior** con el texto de distancia y un botón "✕" que llama a
  `_clearMeasurement`. Este botón `✕` es el único punto de limpieza; no se
  agrega un FAB de limpiar separado ni un chip de texto adicional.

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
const SizedBox(height: 8),
```

Banner (dentro del `Stack` del `body`, antes del `Positioned` de FABs):

```dart
if (_measureDistanceMeters != null)
  Positioned(
    bottom: 100,
    left: 16,
    right: 80,
    child: Card(
      color: Colors.deepOrange.shade700,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

En el `onPressed` del FAB de modo edición existente, desactivar medición al
activar edición (igual que v1):

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

### 🛑 Fase A8 — CHECKPOINT: verificación de Parte A

1. `flutter analyze` (o `dart analyze`) sin errores nuevos.
2. No se agregaron dependencias en `pubspec.yaml`.
3. **Prueba manual obligatoria y explícita**: activar modo medición y tocar
   directamente sobre un marcador de cámara, propuesta y fibra existentes.
   Confirmar que NO se abre ningún modal y que SÍ se coloca un punto de
   medición en cada caso. Esta prueba no existía en el checklist de v1 y es
   la que valida el fix del bug principal.
4. Modo edición y modo medición siguen siendo mutuamente excluyentes.
5. Desactivar medición o tocar "✕" limpia línea, marcadores y banner.

Detente aquí. La Parte A es un entregable completo y usable por sí sola
(ruler genérico). La Parte B es una segunda iteración opcional — no la
inicies sin confirmación explícita, porque toca los modales de
propuesta/fibra y coordina estado entre dos widgets distintos.

---

## PARTE B (v3 — sin fricción) — Medir directo hacia el campo

**Objetivo:** botón "Medir en el mapa" junto al campo → medir → campo
queda relleno con el resultado, editable. Sin chip, sin paso de
confirmación extra — la aproximación ya es el estándar aceptado.

### Fase B1 — Botón en el modal

En `propuesta_form_modal.dart`, junto a `_distanciaNodoController`:

```dart
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _distanciaNodoController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Distancia al Nodo (Metros)',
          suffixText: 'm',
          helperText: 'Aproximado (mapa), no requiere cinta métrica',
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.straighten),
      tooltip: 'Medir en el mapa',
      onPressed: () => Navigator.of(context).pop(
        LatLng(widget.propuesta.latitud, widget.propuesta.longitud),
      ),
    ),
  ],
),
```

Mismo patrón en `fibra_form_modal.dart` junto a `_distanciaCamaraController`
(helper text: `'Aproximado (mapa), no requiere cinta métrica'`).

Sin clase wrapper — un `LatLng` de vuelta alcanza. No hay nada más que
transportar.

### Fase B2 — Capturar y medir en `map_screen.dart`

```dart
final result = await showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => PropuestaFormModal(propuesta: propuesta),
);
if (result is LatLng && mounted) _startGuidedMeasure(result);
```

```dart
void _startGuidedMeasure(LatLng from) {
  setState(() {
    _isMeasuring = true;
    _isEditMode = false;
    _measurePoints
      ..clear()
      ..add(from);
    _measureDistanceMeters = null;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Toca el punto de destino para medir la distancia.'),
      duration: Duration(seconds: 3),
    ),
  );
}
```

Repetir la captura de `result` en el `showModalBottomSheet` de
`FibraFormModal`.

### Fase B3 — Reabrir modal con el campo ya relleno

Banner (Fase A7) gana un botón cuando la medición viene de
`_startGuidedMeasure` (guarda de dónde vino con un campo simple, p. ej.
`String? _guidedMeasureTarget` con el id/tipo del punto de origen):

```dart
TextButton(
  onPressed: () {
    setState(() => _isMeasuring = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PropuestaFormModal(
        propuesta: propuesta,
        distanciaInicialMetros: _measureDistanceMeters,
      ),
    );
  },
  child: const Text('Rellenar campo', style: TextStyle(color: Colors.white)),
),
```

En el modal, un parámetro opcional pisa el valor inicial del controller
(sigue editable después):

```dart
_distanciaNodoController = TextEditingController(
  text: (widget.distanciaInicialMetros ?? widget.propuesta.distanciaNodoMetros)
      ?.toStringAsFixed(2) ?? '',
);
```

Mismo patrón en `FibraFormModal` con `distanciaInicialMetros` →
`_distanciaCamaraController`.

### 🛑 Fase B4 — CHECKPOINT: verificación de Parte B

1. Campo queda relleno al reabrir el modal, sigue editable.
2. Helper text actualizado en ambos modales (aproximado, no cinta métrica).
3. Prueba manual: medir guiado desde una propuesta hacia un punto de fibra,
   confirmar que el modal se reabre con el valor ya en el campo.
4. `flutter analyze` sin errores nuevos.

---

## Orden de ejecución

1. A1 → A2 → A3 → A4 → **A5 (checkpoint)** → A6 → A7 → **A8 (checkpoint, fin de entregable mínimo)**
2. Solo con confirmación explícita: B1 → B2 → B3 → **B4 (checkpoint)**

A y B siguen separados por el checkpoint, no por desconfianza en B (ya no
toca semántica protegida) — sino porque B cruza 3 archivos (map_screen +
2 modales) vía valor de retorno de `Navigator`, y eso quiere un par de ojos
antes de mergear.
