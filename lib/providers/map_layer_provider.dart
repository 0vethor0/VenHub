import 'package:flutter/foundation.dart';
import '../models/map_layer_type.dart';
import '../models/work_site.dart';
import '../services/connectivity_service.dart';
import '../services/site_tile_prefetch_service.dart';

class MapLayerProvider extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final SiteTilePrefetchService _prefetch = SiteTilePrefetchService();

  MapLayerType _selectedLayer = MapLayerType.calle;
  bool _isOnline = true;

  List<WorkSite> sitios = WorkSite.sitiosIniciales;
  final Map<String, bool> _sitiosDescargados = {};
  final Map<String, SiteDownloadProgress> _progresoPorSitio = {};
  final Set<String> _descargando = {};

  MapLayerProvider(this._connectivity) {
    _isOnline = _connectivity.isOnline;
    _connectivity.onStatusChange.listen(_onConnectivityChanged);
    _cargarEstadoDescargas();
  }

  MapLayerType get selectedLayer => _selectedLayer;
  bool get isOnline => _isOnline;
  bool get isDescargando => _descargando.isNotEmpty;

  /// Capa que realmente se debe pintar, considerando conectividad.
  ///
  /// Heurística simple para esta primera versión: si el usuario eligió
  /// satelital/híbrido, no hay red, Y no hay NINGÚN sitio descargado,
  /// se cae a calle (para no mostrar un mapa satelital roto/en blanco).
  /// Si sí hay al menos un sitio descargado, se deja la capa elegida —
  /// FMTC sirve los tiles guardados donde existan y no carga nada donde
  /// no. Una versión más avanzada podría comprobar si el viewport
  /// actual cae dentro del radio de un sitio descargado específico; se
  /// deja como mejora futura para no sobre-construir la primera versión.
  MapLayerType get effectiveLayer {
    if (_selectedLayer == MapLayerType.calle) return MapLayerType.calle;
    if (!_isOnline && !_sitiosDescargados.values.any((v) => v)) {
      return MapLayerType.calle;
    }
    return _selectedLayer;
  }

  void selectLayer(MapLayerType layer) {
    _selectedLayer = layer;
    notifyListeners();
  }

  bool isSiteDownloaded(String siteId) => _sitiosDescargados[siteId] ?? false;

  SiteDownloadProgress? progressFor(String siteId) => _progresoPorSitio[siteId];

  bool isSiteDownloading(String siteId) => _descargando.contains(siteId);

  Future<void> _cargarEstadoDescargas() async {
    for (final site in sitios) {
      _sitiosDescargados[site.id] = await _prefetch.isSiteDownloaded(site.id);
    }
    notifyListeners();
  }

  void _onConnectivityChanged(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  void setSiteCenter(String siteId, WorkSite updated) {
    sitios = sitios
        .map((s) => s.id == siteId ? updated : s)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> downloadSite(WorkSite site) async {
    if (!site.isConfigured) return;
    if (_descargando.contains(site.id)) return;

    _descargando.add(site.id);
    notifyListeners();

    try {
      await _prefetch.downloadSite(
        site,
        onProgress: (p) {
          _progresoPorSitio[site.id] = p;
          notifyListeners();
        },
      );
      _sitiosDescargados[site.id] = true;
    } finally {
      _descargando.remove(site.id);
      notifyListeners();
    }
  }
}
