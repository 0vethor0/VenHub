-- Migration Initial Schema VEN911
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


CREATE TABLE IF NOT EXISTS perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255),
    nombre VARCHAR(255),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS puntos_camara (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(255) NOT NULL,
    ubicacion GEOGRAPHY(POINT, 4326) NOT NULL,
    direccion TEXT,
    municipio VARCHAR(100),
    estado VARCHAR(100) DEFAULT 'Yaracuy',
    energia_electrica BOOLEAN DEFAULT FALSE,
    nivel_tension VARCHAR(50),
    existencia_poste BOOLEAN DEFAULT FALSE,
    altura_poste_metros NUMERIC,
    fibra_optica BOOLEAN DEFAULT FALSE,
    distancia_nodo_metros NUMERIC,
    indice_delictivo VARCHAR(50),
    tipo_zona VARCHAR(100),
    optimizacion_sitio_notas TEXT,
    actualizado_por UUID REFERENCES perfiles(id),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_puntos_camara_ubicacion ON puntos_camara USING GIST (ubicacion);

CREATE TABLE IF NOT EXISTS reportes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    punto_id UUID REFERENCES puntos_camara(id) ON DELETE CASCADE,
    autor_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    observacion TEXT NOT NULL,
    url_evidencia_foto TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_releases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version VARCHAR(50) NOT NULL,
    url_apk TEXT NOT NULL,
    notas_lanzamiento TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE puntos_camara ENABLE ROW LEVEL SECURITY;
ALTER TABLE reportes ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_releases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autenticados pueden leer perfiles" ON perfiles;
CREATE POLICY "Usuarios autenticados pueden leer perfiles" ON perfiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar su perfil" ON perfiles;
CREATE POLICY "Usuarios autenticados pueden actualizar su perfil" ON perfiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Usuarios autenticados pueden todo en puntos_camara" ON puntos_camara;
CREATE POLICY "Usuarios autenticados pueden todo en puntos_camara" ON puntos_camara FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Usuarios autenticados pueden todo en reportes" ON reportes;
CREATE POLICY "Usuarios autenticados pueden todo en reportes" ON reportes FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Cualquiera puede leer releases" ON app_releases;
CREATE POLICY "Cualquiera puede leer releases" ON app_releases FOR SELECT USING (true);

CREATE OR REPLACE FUNCTION get_puntos_camara_geojson()
RETURNS TABLE (
    id UUID,
    nombre VARCHAR(255),
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION,
    direccion TEXT,
    municipio VARCHAR(100),
    estado VARCHAR(100),
    energia_electrica BOOLEAN,
    nivel_tension VARCHAR(50),
    existencia_poste BOOLEAN,
    altura_poste_metros NUMERIC,
    fibra_optica BOOLEAN,
    distancia_nodo_metros NUMERIC,
    indice_delictivo VARCHAR(50),
    tipo_zona VARCHAR(100),
    optimizacion_sitio_notas TEXT,
    actualizado_por UUID,
    actualizado_en TIMESTAMP WITH TIME ZONE
) 
LANGUAGE sql
AS $$
    SELECT 
        p.id,
        p.nombre,
        ST_Y(p.ubicacion::geometry) as latitud,
        ST_X(p.ubicacion::geometry) as longitud,
        p.direccion,
        p.municipio,
        p.estado,
        p.energia_electrica,
        p.nivel_tension,
        p.existencia_poste,
        p.altura_poste_metros,
        p.fibra_optica,
        p.distancia_nodo_metros,
        p.indice_delictivo,
        p.tipo_zona,
        p.optimizacion_sitio_notas,
        p.actualizado_por,
        p.actualizado_en
    FROM puntos_camara p;
$$;

-- Trigger para manejar creación automática de perfil tras registro en Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.perfiles (id, email, nombre)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1))
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    nombre = EXCLUDED.nombre;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

