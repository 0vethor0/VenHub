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
    double lat = 0.0;
    double lon = 0.0;

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
      distanciaACamaraMetros: (map['distancia_a_camara_metros'] as num?)
          ?.toDouble(),
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
