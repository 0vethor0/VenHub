# Plan de Acción: Sistema de Versionado Automático en VenHub

## Contexto
- **App**: VenHub (antes VEN911)
- **Backend**: Supabase con tabla `versiones_app` ya creada (ver estructura abajo)
- **CI/CD**: Workflows de GitHub Actions (`flutter_ci.yml`, `release.yml`) que notifican a Supabase cada nuevo release
- **Objetivo**: Implementar en el frontend Flutter un sistema que detecte automáticamente nuevas versiones (usando Realtime) y permita descargar/instalar actualizaciones de forma fluida.

---

## 📋 Estructura de la Tabla en Supabase (YA EXISTE)
```sql
CREATE TABLE public.versiones_app (
  id BIGSERIAL PRIMARY KEY,
  version_codigo INTEGER NOT NULL,       -- Ej: 10203 (major*10000 + minor*100 + patch)
  version_nombre TEXT NOT NULL,           -- Ej: "v1.2.3"
  url_descarga TEXT NOT NULL,            -- URL del APK en GitHub Releases
  obligatoria BOOLEAN DEFAULT true,      -- Forzar actualización
  fecha_publicacion TIMESTAMPTZ DEFAULT NOW()
);
```
**RLS**: La tabla tiene políticas que permiten SELECT público (sin autenticación) e INSERT solo con `service_role` (para CI/CD).

---

## 🚀 Plan de Acción para el Agente IA 

### Fase 1: Crear el Provider de Versionado
- **Archivo**: `lib/presentation/providers/version_update_provider.dart`
- **Responsabilidades**:
  - Obtener la versión actual de la app usando `package_info_plus`.
  - Conectarse a Supabase Realtime para escuchar inserciones en `versiones_app`.
  - Consultar la última versión al iniciar (para detectar si ya hay una actualización pendiente).
  - Comparar versiones usando `version_codigo` (entero) en lugar de semver (más fiable).
  - Notificar a la UI mediante `ChangeNotifier` y/o `showDialog` cuando haya actualización.
  - Manejar la descarga del APK desde la URL y su instalación (usando `open_file` y permisos).

**Detalles técnicos**:
- Usar `Supabase.instance.client` para acceso a la base de datos.
- Escuchar en el canal `realtime:public:versiones_app` (o un canal dedicado).
- En el callback de `onPostgresChanges`, verificar `event == 'INSERT'` y comparar `version_codigo` con el actual (obtenido de `PackageInfo.buildNumber`).
- Si la nueva versión es mayor, actualizar estado y mostrar diálogo.

### Fase 2: Implementar el Diálogo de Actualización
- Crear un widget `UpdateDialog` que:
  - Muestre la versión disponible y las notas (si existen, aunque la tabla no tiene campo de notas, se puede omitir o agregar luego).
  - Ofrezca dos botones: "Descargar" y "Omitir" (si `obligatoria == false`).
  - Si `obligatoria == true`, el botón "Omitir" se deshabilita o desaparece, forzando la actualización para continuar.

### Fase 3: Integrar en la App
- **Llamar al provider** desde el `main.dart` o desde un widget raíz (`MaterialApp` o `Consumer`).
- Al iniciar la app, ejecutar `checkForUpdates()` y, si hay una actualización disponible, mostrar el diálogo de forma **no bloqueante** (para no ralentizar el arranque).
- Si la actualización es obligatoria, se debe impedir el acceso a la pantalla principal hasta que se complete (o se descargue).

### Fase 4: Manejo de Descarga e Instalación
- Solicitar permisos de almacenamiento (Android) y/o notificaciones.
- Descargar el APK con `http` a un directorio temporal (`getTemporaryDirectory`).
- Abrir el archivo con `OpenFile.open` (tipo MIME `application/vnd.android.package-archive`).
- Mostrar progreso de descarga (opcional, pero recomendado).

### Fase 5: Registro de la Versión Actual (Opcional)
- Guardar localmente la versión instalada para comparar en futuros inicios (evitar mostrar el diálogo si ya se actualizó).
- Usar `shared_preferences` o `hive` para persistir el `version_codigo` actual.

---

## 📦 Dependencias Requeridas (añadir a `pubspec.yaml`)
```yaml
dependencies:
  supabase_flutter: 
  package_info_plus: 
  open_file: 
  permission_handler: 
  http: 
  path_provider: 
  fluttertoast: 
```

---

## 🧪 Flujo de Prueba
1. Ejecutar el flutter analyze.
2. Ejecutar dart format.
3. ejectar flutter test
4. corregir los issue encontrados

---
