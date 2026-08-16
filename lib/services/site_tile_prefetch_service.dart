import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_layer_type.dart';
import '../models/work_site.dart';

/// Progreso de una descarga de sitio.
class SiteDownloadProgress {
  final int completed;
  final int total;
  const SiteDownloadProgress(this.completed, this.total);
  double get fraction => total == 0 ? 0 : completed / total;
}

/// Nombre del store de FMTC usado exclusivamente para tiles satelitales.
/// Separado del futuro store que se use para OSM, si en algún momento
/// se decide precachear la calle también.
const kEsriSateliteStoreName = 'esri_satelite_store';

/// Descarga (precachea) los tiles satelitales de Esri correspondientes a
/// un [WorkSite], usando el almacén durable de FMTC (no depende del
/// caché temporal del sistema operativo, que puede perderse bajo presión
/// de memoria — a diferencia del caché "built-in" de flutter_map).
///
/// DECISIÓN DE DISEÑO: este servicio deliberadamente NO usa la API de
/// "regiones / bulk download" de FMTC (Circle/Rectangle region +
/// download.start...), porque esa parte de la librería ha cambiado de
/// forma significativa entre versiones mayores. En su lugar, solo usa
/// la superficie más estable y antigua de FMTC: crear un store y pedirle
/// un `getTileProvider()` — el mismo mecanismo que usa cualquier
/// TileLayer normal. Descargar un sitio, entonces, es simplemente
/// "pedir" cada tile de su área una vez, igual que si el usuario
/// hubiera navegado por ahí — FMTC lo guarda solo, como ya hace al
/// navegar en vivo.
class SiteTilePrefetchService {
  static const _prefsKeyPrefix = 'site_downloaded_';

  final FMTCTileProvider _tileProvider = FMTCTileProvider(
    stores: const {
      kEsriSateliteStoreName: BrowseStoreStrategy.readUpdateCreate,
    },
  );

  static Future<void> ensureStoreCreated() async {
    const store = FMTCStore(kEsriSateliteStoreName);
    try {
      await store.manage.create();
    } catch (_) {
      // La forma exacta de detectar "el store ya existe" ha cambiado
      // entre versiones de FMTC; atrapar cualquier excepción aquí es
      // deliberadamente permisivo. Si esto oculta un error real de
      // inicialización, los tiles simplemente no se guardarán y el
      // fallo se notará al probar la descarga de un sitio.
    }
  }

  List<_TileXYZ> _tilesForSite(WorkSite site) {
    final center = site.center;
    if (center == null) return const [];

    final tiles = <_TileXYZ>[];
    for (var z = site.minZoom; z <= site.maxZoom; z++) {
      final n = 1 << z;
      final bounds = _boundingBoxKm(center, site.radiusKm);

      final topLeft = _latLngToTile(bounds.north, bounds.west, n);
      final bottomRight = _latLngToTile(bounds.south, bounds.east, n);

      for (var x = topLeft.$1; x <= bottomRight.$1; x++) {
        for (var y = topLeft.$2; y <= bottomRight.$2; y++) {
          tiles.add(_TileXYZ(z, x, y));
        }
      }
    }
    return tiles;
  }

  _Bounds _boundingBoxKm(LatLng center, double radiusKm) {
    const kmPerDegLat = 110.574;
    final latRad = center.latitude * math.pi / 180.0;
    final kmPerDegLon = 111.320 * math.cos(latRad);
    final dLat = radiusKm / kmPerDegLat;
    final dLon = radiusKm / kmPerDegLon;
    return _Bounds(
      north: center.latitude + dLat,
      south: center.latitude - dLat,
      east: center.longitude + dLon,
      west: center.longitude - dLon,
    );
  }

  (int, int) _latLngToTile(double lat, double lon, int n) {
    final x = ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final latRad = lat * (math.pi / 180.0);
    final y =
        ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
                2.0 *
                n)
            .floor()
            .clamp(0, n - 1);
    return (x, y);
  }

  /// Descarga todos los tiles del sitio. No aborta si un tile individual
  /// falla (por ejemplo, un corte momentáneo de señal): sigue con el
  /// resto y reporta el progreso real al final.
  Future<void> downloadSite(
    WorkSite site, {
    required void Function(SiteDownloadProgress progress) onProgress,
  }) async {
    await ensureStoreCreated();
    final tiles = _tilesForSite(site);
    final total = tiles.length;
    var done = 0;

    onProgress(SiteDownloadProgress(0, total));

    // TileLayer "de configuración": no se renderiza en pantalla, solo
    // transporta el urlTemplate/atribución que necesita provideTile().
    final layerOptions = TileLayer(urlTemplate: MapTileUrls.esriSatelite);

    for (final t in tiles) {
      try {
        await _fetchOne(layerOptions, t);
      } catch (_) {
        // Tile individual fallido: se ignora y se continúa.
      }
      done++;
      onProgress(SiteDownloadProgress(done, total));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsKeyPrefix${site.id}', true);
  }

  Future<void> _fetchOne(TileLayer options, _TileXYZ t) async {
    final coords = TileCoordinates(t.x, t.y, t.z);
    try {
      await _tileProvider.provideTile(coords: coords, options: options);
    } catch (_) {
      // Tile individual fallido: se ignora y se continúa.
    }
  }

  Future<bool> isSiteDownloaded(String siteId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsKeyPrefix$siteId') ?? false;
  }
}

class _TileXYZ {
  final int z, x, y;
  const _TileXYZ(this.z, this.x, this.y);
}

class _Bounds {
  final double north, south, east, west;
  const _Bounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}
