import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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
  final int failed;
  const SiteDownloadProgress(this.completed, this.total, {this.failed = 0});
  double get fraction => total == 0 ? 0 : completed / total;
}

const kEsriSateliteStoreName = 'esri_satelite_store';

/// Cuántas descargas de tiles corren en paralelo. Antes esto era
/// secuencial (1 a la vez) y para un sitio de radio 5km podía tardar más
/// de una hora sin dar ninguna señal de progreso real. 10 en paralelo
/// baja eso a minutos y hace que el progreso avance de forma visible.
const _kConcurrentDownloads = 10;

/// Cuánto se espera como máximo por un tile individual antes de darlo
/// por fallido y seguir con el siguiente. Sin esto, un solo tile con
/// problemas de red podía congelar toda la descarga indefinidamente
/// (eso era la causa más probable del "proceso fantasma").
const _kTileTimeout = Duration(seconds: 12);

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
      debugPrint('[SiteDownload] store "$kEsriSateliteStoreName" listo.');
    } catch (e) {
      debugPrint('[SiteDownload] store ya existía o falló create(): $e');
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

  /// Descarga todos los tiles del sitio con [_kConcurrentDownloads]
  /// descargas simultáneas. Un tile fallido o colgado (timeout) no
  /// bloquea el resto — se cuenta como fallo y se sigue.
  Future<void> downloadSite(
    WorkSite site, {
    required void Function(SiteDownloadProgress progress) onProgress,
  }) async {
    await ensureStoreCreated();
    final tiles = _tilesForSite(site);
    final total = tiles.length;

    debugPrint(
      '[SiteDownload] ${site.nombre}: iniciando, $total tiles '
      '(zoom ${site.minZoom}-${site.maxZoom}, radio ${site.radiusKm}km)',
    );

    if (total == 0) {
      onProgress(const SiteDownloadProgress(0, 0));
      debugPrint(
        '[SiteDownload] ${site.nombre}: sin ubicación configurada, '
        'se aborta.',
      );
      return;
    }

    var done = 0;
    var failed = 0;
    onProgress(SiteDownloadProgress(0, total));

    final layerOptions = TileLayer(urlTemplate: MapTileUrls.esriSatelite);
    final queue = List<_TileXYZ>.from(tiles);

    Future<void> worker(int workerId) async {
      while (queue.isNotEmpty) {
        final t = queue.removeLast();
        try {
          await _fetchOne(layerOptions, t).timeout(_kTileTimeout);
        } catch (e) {
          failed++;
          debugPrint('[SiteDownload] tile ${t.z}/${t.x}/${t.y} falló: $e');
        }
        done++;
        onProgress(SiteDownloadProgress(done, total, failed: failed));
      }
    }

    await Future.wait(List.generate(_kConcurrentDownloads, (i) => worker(i)));

    debugPrint(
      '[SiteDownload] ${site.nombre}: terminado. '
      '$done/$total procesados, $failed fallidos.',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsKeyPrefix${site.id}', true);
  }

  Future<void> _fetchOne(TileLayer options, _TileXYZ t) {
    final coords = TileCoordinates(t.x, t.y, t.z);
    final imageProvider = _tileProvider.getImage(coords, options);
    final completer = Completer<void>();
    final stream = imageProvider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace? stack) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    stream.addListener(listener);
    return completer.future;
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
