```markdown
# Plan de Acción — Ubicación en tiempo real en el mapa (VenHub)

Agente IA: ejecuta este plan de forma secuencial. No pidas confirmación al usuario entre fases salvo que encuentres un bloqueo real (permisos denegados en manifiesto inexistente, etc.). Aplica los cambios directamente en el código.

## Contexto
- App Flutter con `flutter_map` + `geolocator` ya en `pubspec.yaml`.
- Pantalla objetivo: `lib/screens/map/map_screen.dart`.
- Objetivo: mostrar la ubicación GPS del dispositivo en tiempo real (punto azul tipo Google Maps), botón “mi ubicación”, modo seguir, y rotación opcional por heading.

---

## Fase 1 — Permisos de plataforma

### 1.1 Android
Archivo: `android/app/src/main/AndroidManifest.xml`

Dentro de `<manifest>`, antes de `<application>`, asegúrate de que existan exactamente estas líneas (añádelas si faltan):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

No dupliques si ya están.

### 1.2 iOS
Archivo: `ios/Runner/Info.plist`

Añade (si no existen) las claves:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarla en el mapa de campo.</string>
```

---

## Fase 2 — Imports y estado en MapScreen

Archivo: `lib/screens/map/map_screen.dart`

### 2.1 Imports
Añade al inicio del archivo (sin duplicar):

```dart
import 'dart:async';
import 'dart:math' show pi;
import 'package:geolocator/geolocator.dart';
```

### 2.2 Estado en `_MapScreenState`
Dentro de la clase `_MapScreenState`, junto a las variables existentes (`_mapController`, `_searchQuery`, etc.), añade:

```dart
LatLng? _currentLocation;
double? _currentHeading;
StreamSubscription<Position>? _positionSub;
bool _followMe = false;
```

---

## Fase 3 — Ciclo de vida: init + dispose + lógica de ubicación

### 3.1 initState
Reemplaza o amplía `initState` para llamar a `_initLocation()`:

```dart
@override
void initState() {
  super.initState();
  _initLocation();
}
```

### 3.2 Método `_initLocation`
Añade este método completo dentro de `_MapScreenState`:

```dart
Future<void> _initLocation() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _currentHeading = pos.heading >= 0 ? pos.heading : null;
    });
  } catch (_) {}

  _positionSub?.cancel();
  _positionSub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  ).listen((pos) {
    if (!mounted) return;
    final latLng = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _currentLocation = latLng;
      _currentHeading = pos.heading >= 0 ? pos.heading : null;
    });
    if (_followMe) {
      _mapController.move(latLng, _mapController.camera.zoom);
    }
  });
}
```

### 3.3 dispose
Amplía `dispose` (si no existe, créalo) para cancelar el stream:

```dart
@override
void dispose() {
  _positionSub?.cancel();
  super.dispose();
}
```

Si ya hay un `dispose`, solo agrega `_positionSub?.cancel();` antes de `super.dispose()`.

---

## Fase 4 — Marker de ubicación actual en el mapa

En el método `build`, dentro de `FlutterMap` → `children`, **después** de los `MarkerLayer` existentes (puntos, propuestas, fibra), añade:

```dart
if (_currentLocation != null)
  MarkerLayer(
    markers: [
      Marker(
        width: 48,
        height: 48,
        point: _currentLocation!,
        child: Transform.rotate(
          angle: ((_currentHeading ?? 0) * pi / 180),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    ],
  ),
```

No elimines ni modifiques los MarkerLayer de puntos de cámara, propuestas o fibra.

---

## Fase 5 — Botón “Mi ubicación” (FAB)

En el `Column` de FABs que ya existe (abajo a la derecha: edición, refresh, recenter), **añade un FAB nuevo** (preferiblemente arriba del de recenter o entre refresh y recenter):

```dart
FloatingActionButton.small(
  heroTag: 'my_location_btn',
  backgroundColor: _followMe ? AppTheme.primaryBlue : Colors.white,
  onPressed: () {
    if (_currentLocation == null) return;
    setState(() => _followMe = !_followMe);
    _mapController.move(_currentLocation!, 16.0);
  },
  child: Icon(
    Icons.my_location,
    color: _followMe ? Colors.white : AppTheme.primaryBlue,
  ),
),
const SizedBox(height: 8),
```

Mantén los FABs existentes (`edit_mode_btn`, `refresh_btn`, `recenter_btn`) intactos. El de recenter actual puede seguir centrando en `_initialCenter` (Yaracuy); el nuevo es solo para la ubicación del usuario.

---

## Fase 6 — Detalle UX (opcional pero recomendado)

Cuando el usuario active el modo edición (`_isEditMode = true`), no desactives el stream de ubicación. El marker de “yo” debe seguir visible.

Si `_followMe` está activo y el usuario arrastra el mapa manualmente, puedes dejar el comportamiento actual (solo deja de seguir si vuelve a pulsar el FAB). No implementes detección de gesto de arrastre a menos que sea trivial con la API actual de `MapController`.

---

## Fase 7 — Verificación final

1. Confirma que `geolocator` sigue en `pubspec.yaml` (no hace falta cambiar versión).
2. No agregues dependencias nuevas.
3. No toques providers, modelos ni otras pantallas.
4. Asegura que el archivo compile: imports correctos, `pi` importado, `Position` de geolocator, `LatLng` de latlong2.
5. Si el análisis estático marca deprecations de geolocator (`locationSettings` vs parámetros antiguos), usa la API de `LocationSettings` como en el código de la Fase 3.

---

## Orden de ejecución obligatorio

1. Fase 1 (permisos)  
2. Fase 2 (imports + estado)  
3. Fase 3 (init / stream / dispose)  
4. Fase 4 (MarkerLayer)  
5. Fase 5 (FAB)  
6. Fase 6 (solo si no rompe nada)  
7. Fase 7 (revisión)

Al terminar, el mapa debe mostrar un punto azul con flecha que se actualiza con el GPS, un FAB de mi ubicación que centra y activa/desactiva seguimiento, y el resto de la funcionalidad del mapa intacta.
```