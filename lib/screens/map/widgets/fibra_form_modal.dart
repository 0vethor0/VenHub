import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/punto_fibra_optica.dart';
import '../../../providers/fibra_provider.dart';
import '../../../providers/points_provider.dart';
import '../../../theme/app_theme.dart';
import 'height_calculator_sheet.dart';

class FibraFormModal extends StatefulWidget {
  final PuntoFibraOptica punto;
  final double? distanciaInicialMetros;

  const FibraFormModal({
    super.key,
    required this.punto,
    this.distanciaInicialMetros,
  });

  @override
  State<FibraFormModal> createState() => _FibraFormModalState();
}

class _FibraFormModalState extends State<FibraFormModal> {
  late TextEditingController _direccionController;
  late TextEditingController _alturaPosteController;
  late TextEditingController _distanciaCamaraController;
  late TextEditingController _observacionesController;
  late String? _estadoPoste;
  late String? _puntoCamaraId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _direccionController = TextEditingController(text: widget.punto.direccion);
    _alturaPosteController = TextEditingController(
      text: widget.punto.alturaPosteMetros?.toString() ?? '',
    );
    _distanciaCamaraController = TextEditingController(
      text:
          (widget.distanciaInicialMetros ?? widget.punto.distanciaACamaraMetros)
              ?.toStringAsFixed(2) ??
          '',
    );
    _observacionesController = TextEditingController(
      text: widget.punto.observaciones,
    );
    _estadoPoste = widget.punto.estadoPoste;
    _puntoCamaraId = widget.punto.puntoCamaraId;
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _alturaPosteController.dispose();
    _distanciaCamaraController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<FibraProvider>(context, listen: false);

    final data = {
      'direccion': _direccionController.text,
      'altura_poste_metros': double.tryParse(_alturaPosteController.text),
      'estado_poste': _estadoPoste,
      'distancia_a_camara_metros': double.tryParse(
        _distanciaCamaraController.text,
      ),
      'punto_camara_id': _puntoCamaraId,
      'observaciones': _observacionesController.text,
    };

    final bool ok;
    if (widget.punto.id.isEmpty) {
      ok = await provider.crearPuntoFibra(
        lat: widget.punto.latitud,
        lon: widget.punto.longitud,
        data: data,
      );
    } else {
      ok = await provider.updatePuntoFibra(widget.punto.id, data);
    }

    setState(() => _isSaving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Punto de fibra guardado con éxito'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deletePunto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Punto de Fibra'),
        content: const Text(
          '¿Está seguro de que desea eliminar este punto de fibra? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<FibraProvider>(context, listen: false);

      final success = await provider.deletePuntoFibra(widget.punto.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punto de fibra eliminado correctamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar: ${provider.errorMessage ?? "Desconocido"}',
            ),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_input_component,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Punto de Fibra Óptica',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              if (widget.punto.id.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
                  onPressed: _deletePunto,
                  tooltip: 'Eliminar punto de fibra',
                ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alturaPosteController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Altura del poste (m)',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.straighten,
                          color: AppTheme.primaryBlue,
                        ),
                        tooltip: 'Calcular altura con el teléfono',
                        onPressed: () async {
                          final resultado = await showModalBottomSheet<double>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const HeightCalculatorSheet(),
                          );
                          if (resultado != null) {
                            _alturaPosteController.text = resultado
                                .toStringAsFixed(2);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _estadoPoste,
                    decoration: const InputDecoration(
                      labelText: 'Estado del poste',
                    ),
                    items: ['Bueno', 'Regular', 'Dañado', 'Inexistente']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _estadoPoste = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _distanciaCamaraController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Distancia a cámara (m)',
                            helperText:
                                'Aproximado (mapa), no requiere cinta métrica',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.straighten),
                        tooltip: 'Medir en el mapa',
                        onPressed: () => Navigator.of(context).pop(
                          LatLng(widget.punto.latitud, widget.punto.longitud),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _puntoCamaraId,
                    decoration: const InputDecoration(
                      labelText: 'Cámara relacionada',
                    ),
                    items: Provider.of<PointsProvider>(context).puntosExistentes
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _puntoCamaraId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Punto de Fibra'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
