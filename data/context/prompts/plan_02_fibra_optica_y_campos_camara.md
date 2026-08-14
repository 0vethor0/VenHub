# Plan de Acción — Feature 2: Nueva Entidad de Fibra Óptica + Campos Adicionales en Puntos de Cámara

**Parte de un set de 4 planes independientes:** `01_mapa_editable` · `02_fibra_optica_y_campos_camara` (este) · `03_calculadora_altura` · `04_exportacion_reportes`.
**Archivos que esta feature comparte con las otras 3:** `lib/models/punto_camara.dart`, `lib/screens/map/widgets/point_form_modal.dart`, `pubspec.yaml`.
**No depende de** Feature 1, 3 ni 4 para funcionar — se puede mergear y probar sola (la capa de mapa para fibra queda inerte hasta que Feature 1 esté también mergeada, pero el CRUD y el formulario funcionan solos).

---

## 0. Decisión tomada (revisar antes de ejecutar)

**Evidencia fotográfica de `puntos_camara`:** ya existe el bucket `reportes_media` para evidencia de reportes del foro. En vez de crear un bucket nuevo con sus propias policies, se reutiliza ese bucket con un prefijo de carpeta distinto (`puntos_camara/{id}/...`). Menos superficie de configuración, mismo patrón que ya usa `reports_provider.dart`.

**Advertencia real, no trámite:** las policies del bucket `reportes_media` **no están versionadas en el repo** (se crearon manualmente en el dashboard de Supabase). Antes de reutilizarlo con el prefijo nuevo, entra al dashboard y confirma que la policy de `INSERT`/`SELECT` no está limitada por prefijo de carpeta o por dueño del objeto. Si se asume sin verificar, el primer upload de evidencia de un punto falla en silencio o con un 403 sin diagnóstico rápido.

---

## 1. Base de datos

### 1.1 `ALTER TABLE puntos_camara`

```sql
ALTER TABLE puntos_camara
  ADD COLUMN estado_poste TEXT,
  ADD COLUMN presencia_luz_farol BOOLEAN,
  ADD COLUMN fluctuacion_electrica TEXT
    CHECK (fluctuacion_electrica IN ('Alto', 'Medio', 'Bajo')),
  ADD COLUMN url_evidencia TEXT;

COMMENT ON COLUMN puntos_camara.estado_poste IS
  'Condición física del poste donde está o iría la cámara (ej: Bueno, Regular, Dañado, Inexistente)';
COMMENT ON COLUMN puntos_camara.url_evidencia IS
  'Ruta/URL del objeto en Supabase Storage (bucket reportes_media, prefijo puntos_camara/{id}/) — imagen o video';
```

Si Feature 1 (mapa editable) ya corrió su `ALTER TABLE puntos_camara ADD tipo_punto, punto_referencia_id`, este es un `ALTER` adicional sobre la misma tabla — columnas distintas, sin conflicto. Si se ejecutan en paralelo, considera juntarlos en una sola migración para no tener dos migraciones el mismo día tocando la misma tabla.

### 1.2 `CREATE TABLE puntos_fibra_optica`

```sql
CREATE TABLE puntos_fibra_optica (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ubicacion GEOGRAPHY(POINT, 4326) NOT NULL,
    direccion TEXT,
    altura_poste_metros NUMERIC,
    estado_poste TEXT,
    distancia_a_camara_metros NUMERIC,
    punto_camara_id UUID REFERENCES puntos_camara(id) ON DELETE SET NULL,
    observaciones TEXT,
    creado_por UUID REFERENCES perfiles(id),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_puntos_fibra_ubicacion ON puntos_fibra_optica USING GIST (ubicacion);
CREATE INDEX idx_puntos_fibra_camara ON puntos_fibra_optica (punto_camara_id);

ALTER TABLE puntos_fibra_optica ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios autenticados pueden todo en puntos_fibra_optica"
  ON puntos_fibra_optica FOR ALL TO authenticated USING (true) WITH CHECK (true);
```

**Nota sobre `distancia_a_camara_metros`:** se pidió como campo explícito, pero es derivable de las dos geometrías (`ST_Distance`). Se deja como columna (no vista calculada) porque el usuario la mide en campo con cinta métrica y puede no coincidir con la línea recta del mapa (obstáculos, tendido real del cable). Si se prefiere 100% calculada, cambiar a `GENERATED ALWAYS AS (...) STORED` — pero ahí se pierde la medición real de campo.

### 1.3 RPC opcional (mismo patrón que `get_puntos_camara_geojson`)

```sql
CREATE OR REPLACE FUNCTION get_puntos_fibra_geojson()
RETURNS TABLE (
  id UUID, direccion TEXT, altura_poste_metros NUMERIC, estado_poste TEXT,
  distancia_a_camara_metros NUMERIC, punto_camara_id UUID, observaciones TEXT,
  ubicacion JSON
) LANGUAGE sql STABLE AS $$
  SELECT id, direccion, altura_poste_metros, estado_poste,
         distancia_a_camara_metros, punto_camara_id, observaciones,
         ST_AsGeoJSON(ubicacion)::json AS ubicacion
  FROM puntos_fibra_optica;
$$;
```

Solo si esa función RPC realmente existe para `puntos_camara` — `points_provider.dart` la llama y cae a `select('*')` si falla, confirmar el mismo patrón antes de asumir que hace falta.

---

## 2. Modelos y Provider Flutter

### 2.1 `lib/models/punto_camara.dart` — agregar campos

```dart
final String? estadoPoste;
final bool? presenciaLuzFarol;
final String? fluctuacionElectrica;
final String? urlEvidencia;
```

`fromMap`/`toMap`: mismo patrón snake_case que el resto del archivo.

### 2.2 `lib/models/punto_fibra_optica.dart` (nuevo)

Mismo patrón exacto que `punto_camara.dart` para parseo de `ubicacion` (GeoJSON o WKT `POINT(lon lat)`). Clonar esa lógica línea por línea — es la parte que más falla si se reescribe desde cero.

```dart
class PuntoFibraOptica {
  final String id;
  final double latitud;
  final double longitud;
  final String? direccion;
  final double? alturaPosteMetros;
  final String? estadoPoste;
  final double? distanciaACamaraMetros;
  final String? puntoCamaraId;
  final String? observaciones;
  final DateTime? actualizadoEn;

  PuntoFibraOptica({
    required this.id,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.alturaPosteMetros,
    this.estadoPoste,
    this.distanciaACamaraMetros,
    this.puntoCamaraId,
    this.observaciones,
    this.actualizadoEn,
  });

  factory PuntoFibraOptica.fromMap(Map<String, dynamic> map) {
    double lat = 0.0, lon = 0.0;
    if (map['ubicacion'] != null) {
      final u = map['ubicacion'];
      if (u is Map<String, dynamic> && u['coordinates'] != null) {
        final coords = u['coordinates'] as List;
        lon = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      } else if (u is String && u.startsWith('POINT')) {
        final clean = u.replaceAll('POINT(', '').replaceAll(')', '').trim();
        final parts = clean.split(' ');
        if (parts.length >= 2) {
          lon = double.tryParse(parts[0]) ?? 0.0;
          lat = double.tryParse(parts[1]) ?? 0.0;
        }
      }
    }
    return PuntoFibraOptica(
      id: map['id']?.toString() ?? '',
      latitud: lat,
      longitud: lon,
      direccion: map['direccion'],
      alturaPosteMetros: (map['altura_poste_metros'] as num?)?.toDouble(),
      estadoPoste: map['estado_poste'],
      distanciaACamaraMetros: (map['distancia_a_camara_metros'] as num?)?.toDouble(),
      puntoCamaraId: map['punto_camara_id']?.toString(),
      observaciones: map['observaciones'],
      actualizadoEn: map['actualizado_en'] != null
          ? DateTime.tryParse(map['actualizado_en'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'direccion': direccion,
        'altura_poste_metros': alturaPosteMetros,
        'estado_poste': estadoPoste,
        'distancia_a_camara_metros': distanciaACamaraMetros,
        'punto_camara_id': puntoCamaraId,
        'observaciones': observaciones,
        'actualizado_en': DateTime.now().toIso8601String(),
      };
}
```

### 2.3 `lib/providers/fibra_provider.dart` (nuevo)

Mismo esqueleto que `points_provider.dart` (fetch, stream realtime atado a auth, update). No lo dupliques desde cero sin mirar ese archivo — el manejo de `_bindRealtimeToAuth` ya resuelve el caso de sesión nula, cópialo tal cual.

Registrar en `main.dart`:

```dart
ChangeNotifierProvider(create: (_) => FibraProvider()),
```

---

## 3. Formulario — `lib/screens/map/widgets/fibra_form_modal.dart` (nuevo)

No reutiliza `PointFormModal` (campos distintos) — clona su estructura general (bottom sheet, `AppTheme`, patrón de guardado) con los campos propios de 1.2: dirección, altura (con el mismo botón de calculadora que Feature 3 agrega — ver esa feature), distancia a cámara, punto de cámara relacionado (dropdown), estado del poste, observaciones.

Campos nuevos en el modal existente `point_form_modal.dart` (Tab 1, junto a los campos actuales):

```dart
TextField(
  controller: _estadoPosteController,
  decoration: const InputDecoration(
    labelText: 'Estado del poste',
    hintText: 'Ej: Poste de concreto en buen estado, sin fisuras ni inclinación',
  ),
),
SwitchListTile(
  title: const Text('Presencia de luz en el farol'),
  value: _presenciaLuzFarol ?? false,
  onChanged: (v) => setState(() => _presenciaLuzFarol = v),
),
DropdownButtonFormField<String>(
  initialValue: _fluctuacionElectrica,
  decoration: const InputDecoration(labelText: 'Fluctuación del sistema eléctrico'),
  items: ['Alto', 'Medio', 'Bajo']
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (v) => setState(() => _fluctuacionElectrica = v),
),
```

Evidencia (`url_evidencia`): reutiliza el `image_picker` que ya existe en este archivo para el foro de reportes (`_pickImage` / `_selectedImage`) — solo cambia el bucket/prefijo de subida (`puntos_camara/{id}/`) y el campo de destino. No construyas un segundo flujo de captura de foto.

---

## 4. Fase de Validación

1. **`flutter test`**
   - Test mínimo sugerido — round-trip de parseo, es lo que más silenciosamente se rompe si cambia el formato de `ubicacion` que devuelve Supabase:
     ```dart
     // test/punto_fibra_optica_test.dart
     import 'package:flutter_test/flutter_test.dart';
     import 'package:ven911_app/models/punto_fibra_optica.dart';

     void main() {
       test('fromMap parsea ubicacion en formato GeoJSON', () {
         final map = {
           'id': 'abc',
           'ubicacion': {'coordinates': [-68.735, 10.339]},
           'altura_poste_metros': 7.5,
         };
         final p = PuntoFibraOptica.fromMap(map);
         expect(p.latitud, 10.339);
         expect(p.longitud, -68.735);
         expect(p.alturaPosteMetros, 7.5);
       });

       test('fromMap parsea ubicacion en formato WKT', () {
         final map = {'id': 'abc', 'ubicacion': 'POINT(-68.735 10.339)'};
         final p = PuntoFibraOptica.fromMap(map);
         expect(p.latitud, 10.339);
         expect(p.longitud, -68.735);
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
