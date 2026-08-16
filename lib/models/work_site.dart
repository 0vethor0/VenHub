import 'package:latlong2/latlong.dart';

/// Representa un sitio de trabajo (pueblo/zona) donde el equipo de campo
/// coloca cámaras y fibra, y sobre el cual se puede precachear la capa
/// satelital para uso sin conexión.
///
/// [center] se deja en null a propósito para los caseríos pequeños: se
/// configura desde la app (con el GPS real del técnico en el sitio) en
/// vez de usar una coordenada escrita a mano que nadie puede validar.
class WorkSite {
  final String id;
  final String nombre;
  final LatLng? center;
  final double radiusKm;
  final int minZoom;
  final int maxZoom;

  const WorkSite({
    required this.id,
    required this.nombre,
    this.center,
    this.radiusKm = 3.0,
    this.minZoom = 15,
    this.maxZoom = 19,
  });

  bool get isConfigured => center != null;

  WorkSite copyWith({
    LatLng? center,
    double? radiusKm,
    int? minZoom,
    int? maxZoom,
  }) {
    return WorkSite(
      id: id,
      nombre: nombre,
      center: center ?? this.center,
      radiusKm: radiusKm ?? this.radiusKm,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }

  /// Lista inicial de los 16 sitios definidos para el levantamiento de
  /// Yaracuy. El radio es un punto de partida razonable (más grande para
  /// capitales de municipio, más chico para caseríos) y se puede ajustar
  /// desde la app antes de descargar. Sin coordenadas: se completan
  /// en campo con el botón "Definir ubicación con GPS actual".
  static List<WorkSite> get sitiosIniciales => const [
    WorkSite(id: 'urachiche', nombre: 'Urachiche'),
    WorkSite(id: 'yaritagua', nombre: 'Yaritagua', radiusKm: 4),
    WorkSite(id: 'guama', nombre: 'Guama'),
    WorkSite(id: 'palito_blanco', nombre: 'Palito Blanco', radiusKm: 2),
    WorkSite(id: 'boraure', nombre: 'Boraure', radiusKm: 2),
    WorkSite(id: 'san_pablo', nombre: 'San Pablo', radiusKm: 2),
    WorkSite(id: 'chivacoa', nombre: 'Chivacoa', radiusKm: 4),
    WorkSite(id: 'nirgua', nombre: 'Nirgua', radiusKm: 4),
    WorkSite(id: 'cocorote', nombre: 'Cocorote', radiusKm: 3),
    WorkSite(id: 'san_geronimo', nombre: 'San Gerónimo', radiusKm: 2),
    WorkSite(id: 'independencia', nombre: 'Independencia'),
    WorkSite(id: 'san_felipe', nombre: 'San Felipe', radiusKm: 5),
    WorkSite(id: 'el_penon', nombre: 'El Peñón', radiusKm: 2),
    WorkSite(id: 'albarico', nombre: 'Albarico', radiusKm: 2),
    WorkSite(id: 'marin', nombre: 'Marín', radiusKm: 2),
    WorkSite(id: 'el_corozo', nombre: 'El Corozo', radiusKm: 2),
  ];
}
