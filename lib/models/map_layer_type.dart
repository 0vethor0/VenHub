/// Tipos de capa base disponibles para el mapa.
enum MapLayerType {
  calle,
  satelite,
  hibrido;

  String get label {
    switch (this) {
      case MapLayerType.calle:
        return 'Calle';
      case MapLayerType.satelite:
        return 'Satelital';
      case MapLayerType.hibrido:
        return 'Híbrido';
    }
  }
}

/// URLs de los proveedores de tiles usados por el mapa.
class MapTileUrls {
  MapTileUrls._();

  static const String openStreetMap =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Esri World Imagery: imagen satelital/aérea pura, sin etiquetas.
  /// IMPORTANTE: Esri usa la convención level/row/col => {z}/{y}/{x},
  /// NO {z}/{x}/{y} como la mayoría de proveedores XYZ estándar.
  static const String esriSatelite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// Capa de referencia (calles, nombres, límites) con fondo transparente,
  /// pensada para superponerse sobre [esriSatelite] y lograr el efecto
  /// "híbrido". Verifica que cargue correctamente en tu prueba inicial;
  /// si Esri cambia o retira este servicio, se puede omitir el modo
  /// híbrido y quedarte solo con calle/satelital sin romper nada más.
  static const String esriReferenciaHibrida =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

  static const String esriAtribucion =
      'Esri, Maxar, Earthstar Geographics, and the GIS User Community';
}
