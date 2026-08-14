import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/propuesta_punto_camara.dart';
import '../../../providers/points_provider.dart';
import '../../../theme/app_theme.dart';
import 'height_calculator_sheet.dart';

class PropuestaFormModal extends StatefulWidget {
  final PropuestaPuntoCamara propuesta;

  const PropuestaFormModal({super.key, required this.propuesta});

  @override
  State<PropuestaFormModal> createState() => _PropuestaFormModalState();
}

class _PropuestaFormModalState extends State<PropuestaFormModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _energiaElectrica;
  late String? _nivelTension;
  late bool _existenciaPoste;
  late TextEditingController _alturaPosteController;
  late bool _fibraOptica;
  late TextEditingController _distanciaNodoController;
  late String? _indiceDelictivo;
  late String? _tipoZona;
  late TextEditingController _notasController;
  late TextEditingController _contextoEspecificoController;
  late String? _flujoPeatonal;
  late String? _flujoVehicular;
  late TextEditingController _puntosCiegosController;
  late TextEditingController _observacionesController;
  late String? _estadoPropuesta;
  late String? _puntoCamaraReferenciaId;
  late TextEditingController _estadoPosteController;
  late bool? _presenciaLuzFarol;
  late String? _fluctuacionElectrica;
  late String? _urlEvidencia;

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _energiaElectrica = widget.propuesta.energiaElectrica;
    _nivelTension = widget.propuesta.nivelTension;
    _existenciaPoste = widget.propuesta.existenciaPoste;
    _alturaPosteController = TextEditingController(
      text: widget.propuesta.alturaPosteMetros?.toString() ?? '',
    );
    _fibraOptica = widget.propuesta.fibraOptica;
    _distanciaNodoController = TextEditingController(
      text: widget.propuesta.distanciaNodoMetros?.toString() ?? '',
    );
    _indiceDelictivo = widget.propuesta.indiceDelictivo;
    _tipoZona = widget.propuesta.tipoZona;
    _notasController = TextEditingController(
      text: widget.propuesta.optimizacionSitioNotas ?? '',
    );
    _contextoEspecificoController = TextEditingController(
      text: widget.propuesta.contextoEspecifico ?? '',
    );
    _flujoPeatonal = widget.propuesta.flujoPeatonal;
    _flujoVehicular = widget.propuesta.flujoVehicular;
    _puntosCiegosController = TextEditingController(
      text: widget.propuesta.puntosCiegos ?? '',
    );
    _observacionesController = TextEditingController(
      text: widget.propuesta.observaciones ?? '',
    );
    _estadoPropuesta = widget.propuesta.estadoPropuesta;
    _puntoCamaraReferenciaId = widget.propuesta.puntoCamaraReferenciaId;
    _estadoPosteController = TextEditingController(
      text: widget.propuesta.estadoPoste ?? '',
    );
    _presenciaLuzFarol = widget.propuesta.presenciaLuzFarol;
    _fluctuacionElectrica = widget.propuesta.fluctuacionElectrica;
    _urlEvidencia = widget.propuesta.urlEvidencia;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alturaPosteController.dispose();
    _distanciaNodoController.dispose();
    _notasController.dispose();
    _contextoEspecificoController.dispose();
    _puntosCiegosController.dispose();
    _observacionesController.dispose();
    _estadoPosteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final pointsProvider = Provider.of<PointsProvider>(context, listen: false);

    String? evidenceUrl = _urlEvidencia;
    if (_selectedImage != null) {
      try {
        final fileExt = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final path = 'propuestas_camara/${widget.propuesta.id}/$fileName';

        await Supabase.instance.client.storage
            .from('reportes_media')
            .upload(path, _selectedImage!);

        evidenceUrl = path;
      } catch (e) {
        debugPrint('Error uploading proposal evidence: $e');
      }
    }

    final updates = {
      'energia_electrica': _energiaElectrica,
      'nivel_tension': _nivelTension,
      'existencia_poste': _existenciaPoste,
      'altura_poste_metros': double.tryParse(_alturaPosteController.text),
      'fibra_optica': _fibraOptica,
      'distancia_nodo_metros': double.tryParse(_distanciaNodoController.text),
      'indice_delictivo': _indiceDelictivo,
      'tipo_zona': _tipoZona,
      'optimizacion_sitio_notas': _notasController.text,
      'contexto_especifico': _contextoEspecificoController.text,
      'flujo_peatonal': _flujoPeatonal,
      'flujo_vehicular': _flujoVehicular,
      'puntos_ciegos': _puntosCiegosController.text,
      'observaciones': _observacionesController.text,
      'estado_propuesta': _estadoPropuesta,
      'punto_camara_referencia_id': _puntoCamaraReferenciaId,
      'estado_poste': _estadoPosteController.text,
      'presencia_luz_farol': _presenciaLuzFarol,
      'fluctuacion_electrica': _fluctuacionElectrica,
      'url_evidencia': evidenceUrl,
    };

    final bool ok;
    if (widget.propuesta.id.isEmpty) {
      ok = await pointsProvider.crearPuntoPropuesta(
        nombre: widget.propuesta.nombre,
        lat: widget.propuesta.latitud,
        lon: widget.propuesta.longitud,
        puntoCamaraReferenciaId: _puntoCamaraReferenciaId,
        datosAdicionales: updates,
      );
    } else {
      // Update existing proposal
      ok = await pointsProvider.updatePropuesta(widget.propuesta.id, updates);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.propuesta.id.isEmpty
                  ? 'Propuesta creada con éxito'
                  : 'Propuesta actualizada con éxito',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: ${pointsProvider.errorMessage ?? 'Desconocido'}',
            ),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _deletePropuesta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Propuesta'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta propuesta? Esta acción no se puede deshacer.',
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
      final pointsProvider = Provider.of<PointsProvider>(
        context,
        listen: false,
      );

      final success = await pointsProvider.deletePunto(
        widget.propuesta.id,
        isPropuesta: true,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propuesta eliminada correctamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar: ${pointsProvider.errorMessage ?? "Desconocido"}',
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
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.add_location,
                color: AppTheme.successGreen,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.propuesta.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.propuesta.id.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
                  onPressed: _deletePropuesta,
                  tooltip: 'Eliminar propuesta',
                ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Ubicación: ${widget.propuesta.latitud.toStringAsFixed(5)}, ${widget.propuesta.longitud.toStringAsFixed(5)} (${widget.propuesta.estado})',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(icon: Icon(Icons.edit_note), text: 'Detalles Propuesta'),
              Tab(icon: Icon(Icons.info), text: 'Estado'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: DETALLES
                SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _puntoCamaraReferenciaId,
                        decoration: const InputDecoration(
                          labelText: 'Cámara de referencia',
                          helperText:
                              'Seleccione la cámara existente relacionada',
                          prefixIcon: Icon(Icons.link),
                        ),
                        items: Provider.of<PointsProvider>(context)
                            .puntosExistentes
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _puntoCamaraReferenciaId = val),
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Energía Eléctrica disponible',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        value: _energiaElectrica,
                        onChanged: (val) =>
                            setState(() => _energiaElectrica = val),
                        activeTrackColor: AppTheme.primaryBlue,
                      ),
                      if (_energiaElectrica)
                        DropdownButtonFormField<String>(
                          initialValue: _nivelTension,
                          decoration: const InputDecoration(
                            labelText: 'Nivel de Tensión',
                          ),
                          items: ['110V', '220V', 'Triphasic', 'OTRO']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _nivelTension = val),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text(
                          'Existencia de Poste',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        value: _existenciaPoste,
                        onChanged: (val) =>
                            setState(() => _existenciaPoste = val),
                        activeTrackColor: AppTheme.primaryBlue,
                      ),
                      if (_existenciaPoste)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: _alturaPosteController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Altura del Poste (Metros)',
                              suffixText: 'm',
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.straighten,
                                  color: AppTheme.primaryBlue,
                                ),
                                tooltip: 'Calcular altura con el teléfono',
                                onPressed: () async {
                                  final resultado =
                                      await showModalBottomSheet<double>(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) =>
                                            const HeightCalculatorSheet(),
                                      );
                                  if (resultado != null) {
                                    _alturaPosteController.text = resultado
                                        .toStringAsFixed(2);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text(
                          'Fibra Óptica cercana',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        value: _fibraOptica,
                        onChanged: (val) => setState(() => _fibraOptica = val),
                        activeTrackColor: AppTheme.primaryBlue,
                      ),
                      if (_fibraOptica)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: _distanciaNodoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Distancia al Nodo (Metros)',
                              suffixText: 'm',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _estadoPosteController,
                        decoration: const InputDecoration(
                          labelText: 'Estado del poste',
                          hintText:
                              'Ej: Poste de concreto en buen estado, sin fisuras ni inclinación',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text(
                          'Presencia de luz en el farol',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        value: _presenciaLuzFarol ?? false,
                        onChanged: (v) =>
                            setState(() => _presenciaLuzFarol = v),
                        activeTrackColor: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _fluctuacionElectrica,
                        decoration: const InputDecoration(
                          labelText: 'Fluctuación del sistema eléctrico',
                        ),
                        items: ['Alto', 'Medio', 'Bajo']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _fluctuacionElectrica = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _indiceDelictivo,
                        decoration: const InputDecoration(
                          labelText: 'Índice Delictivo del Sector',
                        ),
                        items: ['BAJO', 'MEDIO', 'ALTO', 'CRÍTICO']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _indiceDelictivo = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tipoZona,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Zona',
                        ),
                        items:
                            [
                                  'COMERCIAL',
                                  'RESIDENCIAL',
                                  'INDUSTRIAL',
                                  'VIALIDAD PRINCIPAL',
                                  'RURAL',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _tipoZona = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notasController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas de Optimización del Sitio',
                          hintText:
                              'Detalles adicionales, obstáculos, visibilidad...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contextoEspecificoController,
                        decoration: const InputDecoration(
                          labelText: 'Contexto Específico',
                          hintText:
                              'Entrada/salida municipio, intersecciones, etc.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _flujoPeatonal,
                        decoration: const InputDecoration(
                          labelText: 'Flujo Peatonal',
                        ),
                        items: ['Alto', 'Medio', 'Bajo']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _flujoPeatonal = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _flujoVehicular,
                        decoration: const InputDecoration(
                          labelText: 'Flujo Vehicular',
                        ),
                        items: ['Alto', 'Medio', 'Bajo']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _flujoVehicular = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _puntosCiegosController,
                        decoration: const InputDecoration(
                          labelText: 'Puntos Ciegos',
                          hintText: 'Describa puntos ciegos en la ubicación',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _observacionesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          hintText: 'Observaciones adicionales...',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Guardar Propuesta'),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: ESTADO
                SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _estadoPropuesta,
                        decoration: const InputDecoration(
                          labelText: 'Estado de la Propuesta',
                          helperText:
                              'Estado actual de la propuesta de nueva cámara',
                        ),
                        items:
                            [
                                  'pendiente',
                                  'en_revision',
                                  'aprobada',
                                  'rechazada',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.toUpperCase()),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setState(() => _estadoPropuesta = val),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImage != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(height: 8),
                                const Text('Evidencia capturada'),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      setState(() => _selectedImage = null),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.dangerRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.camera_alt,
                              color: AppTheme.primaryBlue,
                            ),
                            title: const Text('Agregar evidencia fotográfica'),
                            subtitle: const Text('Foto del sitio propuesto'),
                            onTap: _pickImage,
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Guardar Propuesta'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
