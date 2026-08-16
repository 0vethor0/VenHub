import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/map_layer_type.dart';
import '../../../providers/map_layer_provider.dart';
import '../../../theme/app_theme.dart';

class MapLayerSheet extends StatelessWidget {
  const MapLayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapLayerProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tipo de mapa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            if (!provider.isOnline) ...[
              const SizedBox(height: 8),
              const Text(
                'Sin conexión: solo verás detalle satelital en las zonas '
                'que hayas descargado previamente. El resto se muestra '
                'con el mapa de calle.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 4),
            for (final layer in MapLayerType.values)
              // ignore: deprecated_member_use
              RadioListTile<MapLayerType>(
                value: layer,
                // ignore: deprecated_member_use
                groupValue: provider.selectedLayer,
                title: Text(layer.label),
                activeColor: AppTheme.primaryBlue,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) provider.selectLayer(value);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
