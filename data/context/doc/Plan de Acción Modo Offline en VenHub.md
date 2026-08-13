# Plan de Acción: Modo Offline en VenHub (PowerSync + SQLite + Offline Maps)

## Contexto
La aplicación actualmente depende de conexión a internet para cargar datos (puntos de cámaras, reportes, etc.) y mostrar el mapa. El objetivo es permitir el uso **100% offline** mediante:

1. **Base de datos local SQLite** sincronizada con Supabase a través de **PowerSync** (sincronización bidireccional en tiempo real).
2. **Mapas offline**: uso de `flutter_map` con caché automático y descarga masiva de tiles (región de Yaracuy) mediante `flutter_map_tile_caching_plus`.

---

## 📦 Dependencias a añadir en `pubspec.yaml`

```yaml
dependencies:
  # Offline data
  powersync: ^1.0.0
  sqlite3_flutter_libs: ^0.5.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  # Offline maps
  flutter_map_tile_caching: ^8.0.0
  flutter_map_tile_caching_plus: ^8.0.0
  # Utilities
  connectivity_plus: ^6.0.0
```

---

## 🗂️ Estructura de la Base de Datos Local

PowerSync gestiona una base de datos SQLite con tablas que reflejan las de Supabase, pero añade metadatos de sincronización. Crearemos las siguientes tablas (ya existen en Supabase, pero necesitan columnas adicionales para PowerSync):

### Tabla `puntos_camara`
- Añadir columna `_sync_status` (text) para controlar el estado de sincronización.
- Añadir columna `_last_modified` (timestamp) para conflictos.

### Tabla `reportes`
- Similar: `_sync_status`, `_last_modified`.

### Tabla `perfiles`
- Similar: `_sync_status`, `_last_modified`.

PowerSync automáticamente añade sus propias tablas de metadatos.

---

## ⚙️ Configuración de PowerSync (Backend)

PowerSync requiere un endpoint en Supabase para la sincronización. Se debe implementar un **servidor de sincronización** (puede ser una función Edge de Supabase o un servidor Node.js). Pero PowerSync ofrece un **conector oficial para Supabase** que simplifica la configuración.

### Pasos en Supabase:

1. **Crear el bucket de PowerSync** (para almacenar los cambios locales).
2. **Crear las funciones RPC** necesarias para la sincronización:
   - `sync_rules` → define qué datos se sincronizan.
   - `sync_data` → para enviar y recibir cambios.
3. **Configurar las políticas RLS** para permitir que PowerSync acceda a los datos del usuario autenticado.

### Opción más sencilla: usar el `PowerSync Supabase Connector` (paquete `powersync_supabase`)

```yaml
dependencies:
  powersync_supabase: ^1.0.0
```

Este paquete simplifica la conexión entre PowerSync y Supabase, manejando la autenticación y las credenciales.

---

## 🚀 Implementación en Flutter

### Fase 1: Inicializar PowerSync

Crea un singleton `PowerSyncService` que gestione la instancia de PowerSync.

#### 1.1. Crear el archivo `lib/services/power_sync_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:power_sync/power_sync.dart';
import 'package:power_sync_supabase/power_sync_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

class PowerSyncService {
  static final PowerSyncService _instance = PowerSyncService._internal();
  factory PowerSyncService() => _instance;
  PowerSyncService._internal();

  PowerSync? _powerSync;
  bool get isInitialized => _powerSync != null;

  Future<void> initialize() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = '${dbPath.path}/venhub.db';

    final supabase = Supabase.instance.client;
    final credentials = SupabaseCredentials(
      supabaseUrl: supabase.supabaseUrl,
      supabaseKey: supabase.supabaseKey!,
    );

    _powerSync = PowerSync(
      database: await openDatabase(path),
      schema: _buildSchema(),
      connector: SupabaseConnector(
        supabase: supabase,
        credentials: credentials,
        syncRules: _syncRules(),
      ),
    );
    await _powerSync!.initialize();
  }

  DatabaseSchema _buildSchema() {
    return DatabaseSchema(
      tables: [
        TableSchema(
          name: 'puntos_camara',
          columns: [
            ColumnSchema(name: 'id', type: ColumnType.text, isPrimaryKey: true),
            ColumnSchema(name: 'nombre', type: ColumnType.text),
            ColumnSchema(name: 'latitud', type: ColumnType.real),
            ColumnSchema(name: 'longitud', type: ColumnType.real),
            ColumnSchema(name: 'direccion', type: ColumnType.text),
            ColumnSchema(name: 'municipio', type: ColumnType.text),
            ColumnSchema(name: 'estado', type: ColumnType.text),
            ColumnSchema(name: 'energia_electrica', type: ColumnType.integer),
            ColumnSchema(name: 'nivel_tension', type: ColumnType.text),
            ColumnSchema(name: 'existencia_poste', type: ColumnType.integer),
            ColumnSchema(name: 'altura_poste_metros', type: ColumnType.real),
            ColumnSchema(name: 'fibra_optica', type: ColumnType.integer),
            ColumnSchema(name: 'distancia_nodo_metros', type: ColumnType.real),
            ColumnSchema(name: 'indice_delictivo', type: ColumnType.text),
            ColumnSchema(name: 'tipo_zona', type: ColumnType.text),
            ColumnSchema(name: 'optimizacion_sitio_notas', type: ColumnType.text),
            ColumnSchema(name: 'contexto_especifico', type: ColumnType.text),
            ColumnSchema(name: 'flujo_peatonal', type: ColumnType.text),
            ColumnSchema(name: 'flujo_vehicular', type: ColumnType.text),
            ColumnSchema(name: 'puntos_ciegos', type: ColumnType.text),
            ColumnSchema(name: 'observaciones', type: ColumnType.text),
            ColumnSchema(name: 'actualizado_por', type: ColumnType.text),
            ColumnSchema(name: 'actualizado_en', type: ColumnType.text),
            // Campos de sincronización
            ColumnSchema(name: '_sync_status', type: ColumnType.text),
            ColumnSchema(name: '_last_modified', type: ColumnType.integer),
          ],
        ),
        TableSchema(
          name: 'reportes',
          columns: [
            ColumnSchema(name: 'id', type: ColumnType.text, isPrimaryKey: true),
            ColumnSchema(name: 'punto_id', type: ColumnType.text),
            ColumnSchema(name: 'autor_id', type: ColumnType.text),
            ColumnSchema(name: 'observacion', type: ColumnType.text),
            ColumnSchema(name: 'url_evidencia_foto', type: ColumnType.text),
            ColumnSchema(name: 'creado_en', type: ColumnType.text),
            ColumnSchema(name: '_sync_status', type: ColumnType.text),
            ColumnSchema(name: '_last_modified', type: ColumnType.integer),
          ],
        ),
        TableSchema(
          name: 'perfiles',
          columns: [
            ColumnSchema(name: 'id', type: ColumnType.text, isPrimaryKey: true),
            ColumnSchema(name: 'email', type: ColumnType.text),
            ColumnSchema(name: 'nombre', type: ColumnType.text),
            ColumnSchema(name: '_sync_status', type: ColumnType.text),
            ColumnSchema(name: '_last_modified', type: ColumnType.integer),
          ],
        ),
      ],
    );
  }

  Map<String, String> _syncRules() {
    return {
      // Sincronizar todos los puntos del estado Yaracuy (se puede filtrar por usuario si se requiere)
      'puntos_camara': "SELECT * FROM puntos_camara WHERE estado = 'Yaracuy'",
      // Sincronizar reportes de los puntos que el usuario ha auditado (o todos)
      'reportes': "SELECT * FROM reportes",
      // Sincronizar el perfil del usuario actual
      'perfiles': "SELECT * FROM perfiles WHERE id = (SELECT auth.uid())",
    };
  }

  PowerSync get powerSync => _powerSync!;

  // Método para cerrar la conexión
  void dispose() {
    _powerSync?.close();
  }
}
```

#### 1.2. Inicializar en `main.dart`

Después de `Supabase.initialize`, llamar a `PowerSyncService().initialize()`.

### Fase 2: Adaptar los Providers para usar PowerSync

#### 2.1. Crear un repositorio base que interactúe con PowerSync

```dart
class PuntosRepository {
  final PowerSync _powerSync = PowerSyncService().powerSync;

  Future<List<PuntoCamara>> getPuntos() async {
    final results = await _powerSync.execute(
      'SELECT * FROM puntos_camara ORDER BY nombre',
    );
    return results.map((row) => PuntoCamara.fromMap(row)).toList();
  }

  Future<void> updatePunto(String id, Map<String, dynamic> updates) async {
    // Actualizar localmente, PowerSync se encargará de sincronizar
    await _powerSync.execute(
      '''UPDATE puntos_camara 
         SET ${updates.keys.map((k) => '$k = ?').join(', ')}, 
             _sync_status = 'pending', 
             _last_modified = strftime('%s', 'now')
         WHERE id = ?''',
      [...updates.values, id],
    );
  }

  // Otros métodos (insert, delete, etc.)
}
```

#### 2.2. Modificar `PointsProvider` para usar el repositorio local primero

```dart
class PointsProvider extends ChangeNotifier {
  final PuntosRepository _repository = PuntosRepository();
  List<PuntoCamara> _puntos = [];
  bool _isLoading = false;

  Future<void> fetchPuntos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _puntos = await _repository.getPuntos();
    } catch (e) {
      // Si falla, intentar con Supabase directamente (modo online)
      // ...
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePunto(String id, Map<String, dynamic> updates) async {
    try {
      await _repository.updatePunto(id, updates);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### 2.3. Adaptar `ReportsProvider` y `AuthProvider` de manera similar.

### Fase 3: Sincronización en segundo plano

PowerSync sincroniza automáticamente cuando la app recupera conectividad. Sin embargo, se debe iniciar la sincronización después del login y al recibir cambios de conectividad.

```dart
// En AuthProvider, después de login exitoso:
await PowerSyncService().powerSync.sync();

// En el listener de conectividad:
connectivity.onConnectivityChanged.listen((event) {
  if (event != ConnectivityResult.none) {
    PowerSyncService().powerSync.sync();
  }
});
```

---

## 🗺️ Mapas Offline con `flutter_map_tile_caching`

### Fase 4: Configurar caché de tiles

#### 4.1. Habilitar caché en `TileLayer`

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.ven911.app',
  tileProvider: CachedTileProvider(
    // Usar el proveedor con caché
    CachedTileProviderOptions(
      maxCacheSize: 200 * 1024 * 1024, // 200 MB
    ),
  ),
)
```

#### 4.2. Implementar descarga masiva de la región de Yaracuy

Crear una pantalla donde el usuario pueda descargar el mapa de Yaracuy antes de salir al campo.

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future<void> downloadMapArea() async {
  // Definir bounding box de Yaracuy (aprox)
  final bounds = LatLngBounds(
    const LatLng(10.0, -69.5),
    const LatLng(10.7, -68.2),
  );
  // Niveles de zoom (0-18, pero 12-16 es suficiente para campo)
  final zoomRange = 12..16;

  await MapCachingManager.instance.downloadRegion(
    regionName: 'yaracuy',
    bounds: bounds,
    zoomRange: zoomRange,
    onProgress: (progress) {
      // Actualizar UI
    },
  );
}
```

#### 4.3. Usar la región descargada en el mapa

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  tileProvider: CachedTileProvider(
    CachedTileProviderOptions(
      cacheStore: MapCachingManager.instance.getStore(),
    ),
  ),
)
```

---

## 📱 Interfaz de usuario para modo offline

### Pantalla de descarga de mapa

Crear una pantalla en `SettingsScreen` donde el usuario pueda descargar el mapa de Yaracuy (mostrar progreso y tamaño estimado).

### Indicador de estado de sincronización

Mostrar un badge o icono en la AppBar que indique si la app está en modo offline o en línea, y el estado de sincronización.

### Manejo de conflictos

PowerSync maneja conflictos automáticamente, pero se puede personalizar. Por defecto, "last write wins".

---

## 🔧 Configuraciones adicionales en Supabase

### 1. Crear las funciones RPC para PowerSync

PowerSync necesita funciones SQL que expongan los datos a sincronizar. Se pueden agregar como migraciones.

```sql
-- Ejemplo: función para sincronizar puntos_camara
CREATE OR REPLACE FUNCTION sync_puntos_camara(since timestamptz)
RETURNS TABLE(id uuid, nombre text, latitud float8, ...)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM puntos_camara 
    WHERE actualizado_en > since OR _last_modified > since;
END;
$$;
```

Pero PowerSync ofrece una manera más sencilla usando `powersync_supabase` que maneja esto internamente.

---

## 📝 Prompt para el Agente IA en Cursor

> **Agente, tu tarea es implementar el modo offline completo en la app VenHub (Flutter) usando PowerSync para sincronización de datos (SQLite local ↔ Supabase) y flutter_map_tile_caching para mapas offline.**
>
> ### Contexto actual
> - La app usa Supabase con tablas: `puntos_camara`, `reportes`, `perfiles`.
> - Los proveedores actuales (`PointsProvider`, `ReportsProvider`, `AuthProvider`) hacen consultas directas a Supabase.
> - El mapa usa `flutter_map` con `TileLayer` desde OSM.
>
> ### Tareas a realizar
>
> #### 1. Configurar PowerSync
> - Agregar dependencias: `powersync`, `powersync_supabase`, `sqlite3_flutter_libs`, `sqflite`, `path_provider`.
> - Crear `PowerSyncService` (singleton) que inicialice la base de datos SQLite y el conector Supabase.
> - Definir el esquema de tablas locales (incluyendo campos `_sync_status` y `_last_modified`).
> - Configurar reglas de sincronización para cada tabla (filtradas por usuario y/o estado).
> - Inicializar PowerSync en `main.dart` después de Supabase.
>
> #### 2. Crear repositorios locales
> - Crear `PuntosRepository`, `ReportesRepository`, `PerfilRepository` que usen PowerSync (métodos `get`, `update`, `insert`).
> - Usar `execute` de PowerSync para ejecutar SQL localmente.
>
> #### 3. Refactorizar providers
> - Modificar `PointsProvider` para leer primero de `PuntosRepository` y no directamente de Supabase.
> - Hacer lo mismo con `ReportsProvider` y `AuthProvider`.
> - Cuando se hagan cambios locales, marcarlos como `_sync_status = 'pending'`.
>
> #### 4. Sincronización automática
> - Después del login y al reconectarse a internet, llamar a `PowerSyncService().powerSync.sync()`.
> - Usar `connectivity_plus` para escuchar cambios de conectividad y disparar sincronización.
>
> #### 5. Mapas offline
> - Configurar `TileLayer` con `CachedTileProvider` (caché automático con `maxCacheSize` de 200 MB).
> - Implementar descarga masiva de la región de Yaracuy (usando `flutter_map_tile_caching`).
> - Crear una pantalla en Settings para mostrar progreso de descarga y administrar regiones descargadas.
> - Al iniciar el mapa, usar el caché de la región descargada.
>
> #### 6. UI/UX offline
> - Agregar un indicador de estado de sincronización (icono en AppBar).
> - Mostrar mensaje de "Sin conexión" cuando no haya internet, pero permitir acceso a datos locales.
> - Manejar errores de sincronización con mensajes claros.
>
> ### Dependencias
>
> ```yaml
> powersync: ^1.0.0
> powersync_supabase: ^1.0.0
> sqlite3_flutter_libs: ^0.5.0
> sqflite: ^2.3.0
> path_provider: ^2.1.0
> flutter_map_tile_caching: ^8.0.0
> flutter_map_tile_caching_plus: ^8.0.0
> connectivity_plus: ^6.0.0
> ```
>
> ### Pasos específicos de implementación
>
> 1. **Crear `PowerSyncService`** siguiendo el ejemplo del plan.
> 2. **Crear repositorios**.
> 3. **Modificar providers**.
> 4. **Integrar caché de tiles en el mapa**.
> 5. **Crear interfaz de descarga de mapa offline**.
> 6. **Pruebas**:
>    - Desconectar internet, verificar que los datos y el mapa se cargan desde caché.
>    - Modificar un punto offline, reconectar y verificar sincronización.
>    - Descargar la región de Yaracuy, desconectar y desplazarse por el mapa sin tiles faltantes.
>
> ### Entregables
> - Código funcional con las nuevas capacidades offline.
> - Documentación breve de uso para el equipo.
> - Configuración de Supabase (funciones RPC si son necesarias).

---

## 🧪 Flujo de prueba offline

1. **Primera vez con internet**: La app se sincroniza y guarda los datos localmente.
2. **Desconectar internet**: La app muestra datos del caché.
3. **Modificar un punto offline**: El cambio se guarda localmente con `_sync_status = 'pending'`.
4. **Reconectar internet**: Se dispara la sincronización y los cambios suben a Supabase.
5. **Mapa offline**: Descargar la región de Yaracuy, desconectar y navegar por el mapa sin conexión.

---

Con este plan, la app será completamente funcional sin internet, brindando una experiencia de "offline-first" sólida y robusta. 🚀