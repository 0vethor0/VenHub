import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/work_site.dart';
import '../../../providers/map_layer_provider.dart';
import '../../../theme/app_theme.dart';

/// Lista los 16 sitios de trabajo y permite descargarlos para uso sin
/// conexión, mientras el técnico todavía tiene WiFi/datos (idealmente en
/// la oficina, antes de salir a campo). Los sitios sin coordenadas se
/// configuran con el GPS real del dispositivo, estando en el lugar.
class SiteManagerSheet extends StatelessWidget {
  const SiteManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<MapLayerProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sitios para uso sin conexión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.isOnline
                        ? 'Descarga cada sitio antes de salir a campo.'
                        : 'Sin conexión: no se pueden iniciar nuevas '
                              'descargas ahora.',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: provider.sitios.length,
                      itemBuilder: (context, index) {
                        return _SiteTile(site: provider.sitios[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SiteTile extends StatelessWidget {
  final WorkSite site;
  const _SiteTile({required this.site});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapLayerProvider>(context);
    final descargado = provider.isSiteDownloaded(site.id);
    final descargando = provider.isSiteDownloading(site.id);
    final progreso = provider.progressFor(site.id);

    return ListTile(
      title: Text(site.nombre),
      subtitle: !site.isConfigured
          ? const Text(
              'Sin ubicación — toca el ícono para definirla con el GPS',
              style: TextStyle(color: AppTheme.dangerRed, fontSize: 12),
            )
          : descargando
          ? LinearProgressIndicator(
              value: (progreso == null || progreso.total == 0)
                  ? null
                  : progreso.fraction,
            )
          : Text(
              descargado ? 'Disponible sin conexión' : 'No descargado',
              style: TextStyle(
                color: descargado ? AppTheme.successGreen : Colors.black54,
                fontSize: 12,
              ),
            ),
      trailing: !site.isConfigured
          ? IconButton(
              icon: const Icon(Icons.edit_location_alt),
              tooltip: 'Definir ubicación con el GPS actual',
              onPressed: () => _configurarConGPS(context, site),
            )
          : descargando
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: Icon(
                descargado ? Icons.refresh : Icons.download,
                color: AppTheme.primaryBlue,
              ),
              tooltip: descargado ? 'Actualizar' : 'Descargar',
              onPressed: provider.isOnline
                  ? () => provider.downloadSite(site)
                  : null,
            ),
    );
  }

  Future<void> _configurarConGPS(BuildContext context, WorkSite site) async {
    final provider = Provider.of<MapLayerProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Activa el GPS del dispositivo.')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación requerido.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      provider.setSiteCenter(
        site.id,
        site.copyWith(center: LatLng(pos.latitude, pos.longitude)),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('${site.nombre}: ubicación guardada.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo obtener el GPS: $e')),
      );
    }
  }
}
