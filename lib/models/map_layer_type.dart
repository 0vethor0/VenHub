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
        // Nombre honesto: por ahora esta capa NO incluye líneas de
        // carreteras/calles (ver nota en MapTileUrls.esriReferenciaHibrida).
        // Si decides no arreglarlo todavía, considera cambiar este label
        // a "Satelital + nombres" para no prometer algo que no se ve.
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
  /// Esri usa la convención level/row/col => {z}/{y}/{x}.
  static const String esriSatelite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// AVISO — LEER ANTES DE USAR:
  /// Este servicio SOLO trae nombres de lugares y límites administrativos.
  /// Nunca incluyó líneas de carreteras/calles — ese es un servicio
  /// distinto ("Hybrid Reference Layer"), que hoy Esri sirve como tiles
  /// VECTORIALES (no raster), requiere una librería de renderizado
  /// vectorial aparte y cuenta/token de ArcGIS Developer. Además, Esri
  /// está retirando activamente sus capas raster heredadas — verifica
  /// que esta URL siga respondiendo antes de confiar en ella en
  /// producción. Ver INSTRUCCIONES.md para el diagnóstico y las opciones.
  static const String esriReferenciaHibrida =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

  static const String esriAtribucion =
      'Esri, Maxar, Earthstar Geographics, and the GIS User Community';

  /// comprobaste en https://www.arcgis.com/apps/mapviewer/index.html
  /// para las zonas de Yaracuy. Se usa como tope duro (MapOptions.maxZoom)
  /// para que el usuario no pueda seguir haciendo zoom más allá del
  /// límite donde Esri ya no tiene imagen, evitando el fondo gris.
  static const int esriMaxZoom = 19;

  /// Zoom máximo para el mapa de calle (OSM soporta hasta 19 de forma
  /// confiable en la mayoría de zonas).
  static const int calleMaxZoom = 19;
}
