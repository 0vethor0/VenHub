class PuntoCamara {
  final String id;
  final String nombre;
  final double latitud;
  final double longitud;
  final String? direccion;
  final String? municipio;
  final String estado;
  final bool energiaElectrica;
  final String? nivelTension;
  final bool existenciaPoste;
  final double? alturaPosteMetros;
  final bool fibraOptica;
  final double? distanciaNodoMetros;
  final String? indiceDelictivo;
  final String? tipoZona;
  final String? optimizacionSitioNotas;
  final String? contextoEspecifico;
  final String? flujoPeatonal;
  final String? flujoVehicular;
  final String? puntosCiegos;
  final String? observaciones;
  final String? actualizadoPor;
  final DateTime? actualizadoEn;

  PuntoCamara({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.municipio,
    this.estado = 'Yaracuy',
    this.energiaElectrica = false,
    this.nivelTension,
    this.existenciaPoste = false,
    this.alturaPosteMetros,
    this.fibraOptica = false,
    this.distanciaNodoMetros,
    this.indiceDelictivo,
    this.tipoZona,
    this.optimizacionSitioNotas,
    this.contextoEspecifico,
    this.flujoPeatonal,
    this.flujoVehicular,
    this.puntosCiegos,
    this.observaciones,
    this.actualizadoPor,
    this.actualizadoEn,
  });

  factory PuntoCamara.fromMap(Map<String, dynamic> map) {
    double lat = 0.0;
    double lon = 0.0;

    // Parse location if returned from PostGIS geography / GeoJSON or custom query
    if (map['ubicacion'] != null) {
      final u = map['ubicacion'];
      if (u is Map<String, dynamic> && u['coordinates'] != null) {
        final coords = u['coordinates'] as List;
        lon = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      } else if (u is String && u.startsWith('POINT')) {
        // WKT parse format POINT(lon lat)
        final clean = u.replaceAll('POINT(', '').replaceAll(')', '').trim();
        final parts = clean.split(' ');
        if (parts.length >= 2) {
          lon = double.tryParse(parts[0]) ?? 0.0;
          lat = double.tryParse(parts[1]) ?? 0.0;
        }
      }
    } else {
      lat =
          (map['latitud'] as num?)?.toDouble() ??
          (map['lat'] as num?)?.toDouble() ??
          0.0;
      lon =
          (map['longitud'] as num?)?.toDouble() ??
          (map['lon'] as num?)?.toDouble() ??
          0.0;
    }

    return PuntoCamara(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] ?? map['name'] ?? 'Punto sin nombre',
      latitud: lat,
      longitud: lon,
      direccion: map['direccion'],
      municipio: map['municipio'],
      estado: map['estado'] ?? 'Yaracuy',
      energiaElectrica: map['energia_electrica'] ?? false,
      nivelTension: map['nivel_tension'],
      existenciaPoste: map['existencia_poste'] ?? false,
      alturaPosteMetros: (map['altura_poste_metros'] as num?)?.toDouble(),
      fibraOptica: map['fibra_optica'] ?? false,
      distanciaNodoMetros: (map['distancia_nodo_metros'] as num?)?.toDouble(),
      indiceDelictivo: map['indice_delictivo'],
      tipoZona: map['tipo_zona'],
      optimizacionSitioNotas: map['optimizacion_sitio_notas'],
      contextoEspecifico: map['contexto_especifico'],
      flujoPeatonal: map['flujo_peatonal'],
      flujoVehicular: map['flujo_vehicular'],
      puntosCiegos: map['puntos_ciegos'],
      observaciones: map['observaciones'],
      actualizadoPor: map['actualizado_por'],
      actualizadoEn: map['actualizado_en'] != null
          ? DateTime.tryParse(map['actualizado_en'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'municipio': municipio,
      'estado': estado,
      'energia_electrica': energiaElectrica,
      'nivel_tension': nivelTension,
      'existencia_poste': existenciaPoste,
      'altura_poste_metros': alturaPosteMetros,
      'fibra_optica': fibraOptica,
      'distancia_nodo_metros': distanciaNodoMetros,
      'indice_delictivo': indiceDelictivo,
      'tipo_zona': tipoZona,
      'optimizacion_sitio_notas': optimizacionSitioNotas,
      'contexto_especifico': contextoEspecifico,
      'flujo_peatonal': flujoPeatonal,
      'flujo_vehicular': flujoVehicular,
      'puntos_ciegos': puntosCiegos,
      'observaciones': observaciones,
      'actualizado_por': actualizadoPor,
      'actualizado_en': DateTime.now().toIso8601String(),
    };
  }
}
