import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/punto_fibra_optica.dart';
import '../../../providers/fibra_provider.dart';
import '../../../providers/points_provider.dart';
import '../../../theme/app_theme.dart';

class FibraFormModal extends StatefulWidget {
  final PuntoFibraOptica punto;

  const FibraFormModal({super.key, required this.punto});

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
      text: widget.punto.distanciaACamaraMetros?.toString() ?? '',
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
          const Text(
            'Punto de Fibra Óptica',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
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
                    decoration: const InputDecoration(
                      labelText: 'Altura del poste (m)',
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
                  TextField(
                    controller: _distanciaCamaraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Distancia a cámara (m)',
                    ),
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
