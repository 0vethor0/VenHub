import 'package:flutter/foundation.dart';
import '../models/map_layer_type.dart';
import '../models/work_site.dart';
import '../services/connectivity_service.dart';
import '../services/download_notification_service.dart';
import '../services/site_tile_prefetch_service.dart';

class MapLayerProvider extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final SiteTilePrefetchService _prefetch = SiteTilePrefetchService();
  final DownloadNotificationService _notifications =
      DownloadNotificationService();

  MapLayerType _selectedLayer = MapLayerType.calle;
  bool _isOnline = true;

  List<WorkSite> sitios = WorkSite.sitiosIniciales;
  final Map<String, bool> _sitiosDescargados = {};
  final Map<String, SiteDownloadProgress> _progresoPorSitio = {};
  final Set<String> _descargando = {};

  // Capas ya "calentadas" en esta sesión (FMTC/red ya inicializados para
  // ellas al menos una vez) — se usa para mostrar un overlay de carga
  // solo la primera vez que se selecciona cada capa, que es cuando
  // ocurre el costo de arranque de FMTC.
  final Set<MapLayerType> _warmedLayers = {MapLayerType.calle};

  MapLayerProvider(this._connectivity) {
    _isOnline = _connectivity.isOnline;
    _connectivity.onStatusChange.listen(_onConnectivityChanged);
    _cargarEstadoDescargas();
    _notifications.init();
  }

  MapLayerType get selectedLayer => _selectedLayer;
  bool get isOnline => _isOnline;
  bool get isDescargando => _descargando.isNotEmpty;

  bool isLayerWarm(MapLayerType layer) => _warmedLayers.contains(layer);

  void markLayerWarm(MapLayerType layer) {
    if (_warmedLayers.add(layer)) notifyListeners();
  }

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

    await _notifications.requestPermission();

    _descargando.add(site.id);
    notifyListeners();

    try {
      await _prefetch.downloadSite(
        site,
        onProgress: (p) {
          _progresoPorSitio[site.id] = p;
          notifyListeners();

          // Limitar las actualizaciones de la notificación a ~100 en
          // total (cada ~1% de avance), sin importar cuántos miles de
          // tiles tenga el sitio — evita saturar el sistema de
          // notificaciones con miles de llamadas.
          final step = (p.total / 100).ceil().clamp(1, 1 << 30);
          if (p.completed % step == 0 || p.completed == p.total) {
            _notifications.showProgress(
              siteName: site.nombre,
              completed: p.completed,
              total: p.total,
            );
          }
        },
      );
      _sitiosDescargados[site.id] = true;
      await _notifications.showDone(site.nombre);
    } finally {
      _descargando.remove(site.id);
      notifyListeners();
    }
  }
}
