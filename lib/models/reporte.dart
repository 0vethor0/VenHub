class Reporte {
  final String id;
  final String puntoId;
  final String autorId;
  final String observacion;
  final String? urlEvidenciaFoto;
  final DateTime creadoEn;
  final String? autorNombre;

  Reporte({
    required this.id,
    required this.puntoId,
    required this.autorId,
    required this.observacion,
    this.urlEvidenciaFoto,
    required this.creadoEn,
    this.autorNombre,
  });

  factory Reporte.fromMap(Map<String, dynamic> map) {
    String? autorName;
    if (map['perfiles'] != null && map['perfiles'] is Map) {
      autorName = map['perfiles']['nombre'];
    }

    return Reporte(
      id: map['id']?.toString() ?? '',
      puntoId: map['punto_id']?.toString() ?? '',
      autorId: map['autor_id']?.toString() ?? '',
      observacion: map['observacion'] ?? '',
      urlEvidenciaFoto: map['url_evidencia_foto'],
      creadoEn: DateTime.tryParse(map['creado_en'] ?? '') ?? DateTime.now(),
      autorNombre: autorName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'punto_id': puntoId,
      'autor_id': autorId,
      'observacion': observacion,
      'url_evidencia_foto': urlEvidenciaFoto,
    };
  }
}
