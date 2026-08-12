# Plan de Acción: Desarrollo de App "VEN911 - Levantamiento de Campo"

**Instrucción para el Agente IA en Cursor**  
Este plan está diseñado para que el agente ejecute paso a paso la construcción de la aplicación. **Ya se ha realizado la extracción de los 181 puntos iniciales** a partir del KML, generando el archivo `puntos_iniciales.json` (con campos `name`, `lat`, `lon`). El agente **no debe** volver a leer el KML ni rehacer esa extracción. Debe comenzar utilizando ese JSON para poblar la base de datos y luego continuar con el desarrollo completo.

---

## Fase 0: Migración Inicial de Datos (Seed a Supabase)

**Objetivo:** Cargar los 181 puntos desde `puntos_iniciales.json` hacia la tabla `puntos_camara` en Supabase, utilizando una carga masiva (bulk insert) para no saturar la base de datos.

**Tareas para el Agente:**

1. **Crear un script de migración** en Python (o Dart) llamado `seed_database.py` (o `.dart`) que:
  - Lea `puntos_iniciales.json`.
  - Se conecte a Supabase usando la `SERVICE_ROLE_KEY` (obtenida de variables de entorno o de un archivo `.env`).
  - Construya un array de objetos con los campos: `nombre`, `latitud`, `longitud`, `estado` (default 'Yaracuy'), y las demás columnas de evaluación en `null`.
  - Realice un **bulk insert** (insert into ... values ...) o utilice la función `supabase.from('puntos_camara').insert()` con el array completo.
2. **Crear la tabla en Supabase** (si no existe) usando el SQL definido en la Fase 2. El script puede verificar la existencia de la tabla y crearla si es necesario.
3. **Ejecutar el script** localmente (o desde GitHub Actions) para poblar la base de datos inicial. Se debe verificar que los 181 registros se hayan insertado correctamente.

---



## Fase 1: Configuración del Proyecto Flutter y UI/UX

**Objetivo:** Inicializar el proyecto y generar las pantallas principales siguiendo los wireframes proporcionados.

**Tareas para el Agente:**

1. **Crear proyecto Flutter** con `flutter create ven911_app`.
2. **Editar** `pubspec.yaml` añadiendo dependencias:
  ```yaml
   dependencies:
     flutter:
       sdk: flutter
     supabase_flutter: 
     flutter_map: 
     latlong2: 
     geolocator: 
     image_picker: 
     provider: 
     # otras según necesidad
  ```
3. **Extraer estilos de los wireframes** ubicados en `data/Wireframes UI Kit/` (paleta de colores, tipografía, tamaños) y crear un archivo `lib/theme/app_theme.dart` con los estilos definidos.
4. **Generar las pantallas** (solo estructura y navegación básica):
  - `SplashScreen`
  - `LoginScreen` / `RegisterScreen`
  - `MapScreen` (pantalla principal)
  - `PointFormModal` (modal para editar punto)
  - `ReportsScreen` (foro por punto o general)
  - `ProfileScreen`

---



## Fase 2: Backend y Base de Datos (Supabase)

**Objetivo:** Diseñar el esquema completo, incluyendo tablas de equipos, perfiles, puntos, reportes y versiones, además de habilitar PostGIS para consultas geoespaciales.

**Tareas para el Agente:**

1. **Ejecutar el siguiente SQL en el SQL Editor de Supabase** (o mediante la CLI de Supabase) para crear todas las tablas y políticas RLS:
  ```sql
   -- Habilitar PostGIS (necesario para consultas espaciales)
   CREATE EXTENSION IF NOT EXISTS postgis;

   -- Tabla de Equipos
   CREATE TABLE equipos (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       nombre VARCHAR(255) NOT NULL,
       creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabla de Perfiles (extiende auth.users)
   CREATE TABLE perfiles (
       id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
       email VARCHAR(255),
       nombre VARCHAR(255),
       equipo_id UUID REFERENCES equipos(id) ON DELETE SET NULL,
       creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabla de Puntos de Cámara (con soporte geográfico)
   CREATE TABLE puntos_camara (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       nombre VARCHAR(255) NOT NULL,
       -- Usamos tipo geography para consultas espaciales nativas
       ubicacion GEOGRAPHY(POINT, 4326) NOT NULL,
       direccion TEXT,
       municipio VARCHAR(100),
       estado VARCHAR(100) DEFAULT 'Yaracuy',
       -- Variables de campo
       energia_electrica BOOLEAN,
       nivel_tension VARCHAR(50),
       existencia_poste BOOLEAN,
       altura_poste_metros NUMERIC,
       fibra_optica BOOLEAN,
       distancia_nodo_metros NUMERIC,
       indice_delictivo VARCHAR(50),
       tipo_zona VARCHAR(100),
       optimizacion_sitio_notas TEXT,
       actualizado_por UUID REFERENCES perfiles(id),
       actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Índice espacial para acelerar consultas de cercanía
   CREATE INDEX idx_puntos_camara_ubicacion ON puntos_camara USING GIST (ubicacion);

   -- Tabla de Reportes (Foro)
   CREATE TABLE reportes (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       punto_id UUID REFERENCES puntos_camara(id) ON DELETE CASCADE,
       autor_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
       equipo_id UUID REFERENCES equipos(id) ON DELETE CASCADE,
       observacion TEXT NOT NULL,
       url_evidencia_foto TEXT,
       creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabla de Registro de Versiones (CD)
   CREATE TABLE app_releases (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       version VARCHAR(50) NOT NULL,
       url_apk TEXT NOT NULL,
       notas_lanzamiento TEXT,
       creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- RLS (Row Level Security)
   ALTER TABLE equipos ENABLE ROW LEVEL SECURITY;
   ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE puntos_camara ENABLE ROW LEVEL SECURITY;
   ALTER TABLE reportes ENABLE ROW LEVEL SECURITY;

   -- Políticas básicas (usuario autenticado puede todo)
   CREATE POLICY "Usuarios autenticados pueden leer equipos" ON equipos FOR SELECT TO authenticated USING (true);
   CREATE POLICY "Usuarios autenticados pueden leer perfiles" ON perfiles FOR SELECT TO authenticated USING (true);
   CREATE POLICY "Usuarios autenticados pueden todo en puntos_camara" ON puntos_camara FOR ALL TO authenticated USING (true) WITH CHECK (true);
   CREATE POLICY "Usuarios autenticados pueden todo en reportes" ON reportes FOR ALL TO authenticated USING (true) WITH CHECK (true);
  ```
2. **Modificar el script de migración** (Fase 0) para que inserte los puntos utilizando el tipo `geography`:
  - Convertir `lat` y `lon` a formato WKT: `POINT(lon lat)` (atención al orden: longitud primero, luego latitud).
  - El script debe ejecutar una sentencia `INSERT` masiva con `ST_GeomFromText('POINT(lon lat)', 4326)`.

---



## Fase 3: Desarrollo Core de la App (Flutter Logic)

**Objetivo:** Implementar las funcionalidades principales: autenticación, mapa interactivo, formulario de actualización de puntos, y foro de reportes.

**Tareas para el Agente:**

1. **Autenticación:**
  - Usar `SupabaseAuth` para login/registro.
  - Almacenar el `equipo_id` del usuario en el perfil (se actualiza en tabla `perfiles`).
  - Mantener el estado del usuario con `Provider` o `Riverpod`.
2. **Mapa Interactivo:**
  - Usar `FlutterMap` con capa de `MarkerLayer`.
  - Obtener los puntos desde Supabase mediante `supabase.from('puntos_camara').select('id, nombre, ubicacion, energia_electrica, fibra_optica, ...')`.
  - Convertir `ubicacion` (tipo `geography`) a `LatLng` (extraer `st_x(ubicacion::geometry)` y `st_y(...)` o confiar en que Supabase devuelve coordenadas en el objeto JSON).
  - Al hacer `onTap` en un marcador, abrir un `showModalBottomSheet` mostrando los datos del punto y permitir editar las variables de campo.
3. **Formulario Dinámico (Actualización en Tiempo Real):**
  - El modal debe contener campos para cada variable (checks, dropdowns, texto).
  - Al guardar, realizar un `update` en `puntos_camara` con los nuevos valores.
  - Utilizar `.stream` de Supabase para escuchar cambios en tiempo real y actualizar el mapa automáticamente.
4. **Foro de Reportes:**
  - Dentro del modal de cada punto, añadir una pestaña "Reportes" que muestre la lista de observaciones.
  - Permitir al usuario agregar un nuevo reporte (texto + opción de subir foto a Storage).
  - Insertar en `reportes` y actualizar la lista mediante `stream`.
5. **Perfil y Ajustes:**
  - Mostrar datos del usuario y permitir cambiar de equipo (si corresponde).

---



## Fase 4: Integración y Despliegue Continuo (CI/CD) con GitHub Actions

**Objetivo:** Automatizar pruebas, construcción de APK y registro de versiones en Supabase.

**Tareas para el Agente:**

1. **Crear el directorio** `.github/workflows/` y dentro dos archivos:
  - `ci.yml` (Integración Continua):
    - Se ejecuta en cada `push` y `pull_request` a `main`.
    - Pasos:
      - Configurar Flutter.
      - `flutter pub get`.
      - `flutter analyze` (si falla, el workflow falla).
      - (Opcional) `flutter test`.
  - `cd.yml` (Despliegue Continuo):
    - Se ejecuta cuando se crea un tag en el repositorio (ej. `v1.2.0`).
    - Pasos:
      - Extraer la versión del tag.
      - Configurar Flutter y compilar `flutter build apk --release`.
      - Crear un Release en GitHub con el APK adjunto.
      - Insertar un registro en `app_releases` con la versión y la URL de descarga (usando `curl` a la API REST de Supabase o un script).
      - Utilizar los secrets de GitHub: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
  - Asegurarse de que el `cd.yml` solo se ejecute si el `ci.yml` pasa en la rama `main` (se puede configurar con protección de rama o con condiciones en el workflow).
2. **Configurar variables de entorno** en el repositorio (Settings -> Secrets and variables) con las claves de Supabase.

---



## Instrucciones Finales para el Agente

- **Comienza ejecutando el script de migración** (Fase 0) para asegurar que los datos estén en Supabase.
- **No modifiques el JSON original**; trabaja siempre con una copia o con la conexión directa a la base.
- **Documenta cada paso** con comentarios en el código y actualiza el `README.md` conforme avances.
- **Prueba cada funcionalidad** en el emulador o en un dispositivo físico antes de pasar a la siguiente fase.

---

