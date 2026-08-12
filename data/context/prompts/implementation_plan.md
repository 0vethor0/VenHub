# Plan de Acción: Desarrollo de App "VEN911 - Levantamiento de Campo"

Este plan cubre el desarrollo end-to-end de la aplicación móvil **VEN911 - Levantamiento de Campo** en Flutter, la infraestructura de backend en Supabase (con PostGIS, RLS e índices geoespaciales), los flujos de automatización CI/CD en GitHub Actions y la carga masiva de los 181 puntos iniciales de cámaras.

## User Review Required

> [!IMPORTANT]
> - **Supabase URL y Keys:** Para probar la app y ejecutar las migraciones se requerirá un archivo `.env` o la configuración de variables de entorno (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`).
> - **Flujo de Ejecución:** Siguiendo la instrucción explícita, realizaremos en orden **Fase 1 a 4** y **Fase 0** (Sembrado de datos).

## Proposed Changes

---

### Fase 1: Configuración del Proyecto Flutter y UI/UX

#### [NEW] [pubspec.yaml](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/pubspec.yaml)
- Crear el proyecto Flutter `ven911_app`.
- Configurar dependencias: `supabase_flutter`, `flutter_map`, `latlong2`, `geolocator`, `image_picker`, `provider`, `flutter_dotenv`.

#### [NEW] [app_theme.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/theme/app_theme.dart)
- Definir el sistema de diseño visual (colores primarios/secundarios, tipografía moderna, bordes redondeados, modo oscuro/claro y componentes estilizados basados en la guía visual `Wireframes UI Kit`).

#### [NEW] Pantallas base UI (Navegación y Estructura):
- [splash_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/splash_screen.dart): Pantalla de carga inicial con verificación de sesión.
- [login_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/auth/login_screen.dart) / [register_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/auth/register_screen.dart): Autenticación de usuarios.
- [map_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/map/map_screen.dart): Mapa interactivo principal con FlutterMap.
- [point_form_modal.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/map/widgets/point_form_modal.dart): BottomSheet modal para visualización y edición del punto.
- [reports_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/reports/reports_screen.dart): Foro de reportes/observaciones por punto.
- [profile_screen.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/screens/profile/profile_screen.dart): Perfil de usuario y selección de equipo.

---

### Fase 2: Backend y Base de Datos (Supabase)

#### [NEW] [schema.sql](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/supabase/schema.sql)
- Habilitación de la extensión `postgis`.
- Tablas: `equipos`, `perfiles`, `puntos_camara` (con columna `ubicacion GEOGRAPHY(POINT, 4326)`), `reportes`, `app_releases`.
- Índice geoespacial `idx_puntos_camara_ubicacion` usando `GIST`.
- Activación de Row Level Security (RLS) en todas las tablas y políticas de acceso para usuarios autenticados.

---

### Fase 3: Desarrollo Core de la App (Lógica Flutter)

#### [NEW] Proveedores de Estado y Servicios:
- [auth_provider.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/providers/auth_provider.dart): Gestión de autenticación con `SupabaseAuth` y sincronización del perfil del usuario.
- [points_provider.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/providers/points_provider.dart): Carga y actualización en tiempo real de puntos usando `.stream()` de Supabase.
- [reports_provider.dart](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/ven911_app/lib/providers/reports_provider.dart): Gestión del foro de observaciones e integración con Supabase Storage para fotografías.

#### [NEW] Componentes interactivos:
- Map Markers personalizados según estado (energía, fibra óptica, tipo de zona).
- Formulario dinámico con switches, dropdowns y campos numéricos para las variables de campo.

---

### Fase 4: CI/CD con GitHub Actions

#### [NEW] [.github/workflows/ci.yml](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/.github/workflows/ci.yml)
- Pipeline de integración continua: instala Flutter, resuelve dependencias (`flutter pub get`), ejecuta linters (`flutter analyze`) y pruebas.

#### [NEW] [.github/workflows/cd.yml](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/.github/workflows/cd.yml)
- Pipeline de despliegue continuo al publicar un tag `v*`: compila APK Release, crea un GitHub Release con el ejecutable y registra la nueva versión en la tabla `app_releases` de Supabase.

---

### Fase 0: Migración Inicial de Datos (Seed a Supabase)

#### [NEW] [seed_database.py](file:///c:/Users/Vincent/Documents/Codigo/VEN911-Hub/scripts/seed_database.py)
- Script en Python para leer `data/context/doc/puntos_iniciales.json` (soporte de codificación UTF-16LE / UTF-8).
- Convierte latitud y longitud al formato WKT `POINT(longitud latitud)` para PostGIS (`ST_GeomFromText('POINT(lon lat)', 4326)`).
- Realiza insert masivo (bulk insert) a Supabase mediante API REST / SDK Python o sentencia SQL estructurada de 181 registros.

---

## Verification Plan

### Automated Tests
- `flutter analyze` para verificar la calidad y ausencia de errores estáticos.
- Script de prueba de sintaxis de migración SQL y prueba unitaria de parsing de `puntos_iniciales.json`.

### Manual Verification
- Verificación del árbol de archivos e interfaz de usuario en Flutter.
- Comprobación de que las 181 coordenadas son procesadas correctamente con el formato PostGIS `POINT(lon lat)`.
- Revisión de esquemas SQL, índices GIST y políticas RLS.
