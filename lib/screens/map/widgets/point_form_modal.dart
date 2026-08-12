import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/punto_camara.dart';
import '../../../providers/points_provider.dart';
import '../../../providers/reports_provider.dart';

class PointFormModal extends StatefulWidget {
  final PuntoCamara punto;

  const PointFormModal({super.key, required this.punto});

  @override
  State<PointFormModal> createState() => _PointFormModalState();
}

class _PointFormModalState extends State<PointFormModal> with SingleTickerProviderStateMixin {
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

  final _reporteObservacionController = TextEditingController();
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _energiaElectrica = widget.punto.energiaElectrica;
    _nivelTension = widget.punto.nivelTension;
    _existenciaPoste = widget.punto.existenciaPoste;
    _alturaPosteController = TextEditingController(
        text: widget.punto.alturaPosteMetros?.toString() ?? '');
    _fibraOptica = widget.punto.fibraOptica;
    _distanciaNodoController = TextEditingController(
        text: widget.punto.distanciaNodoMetros?.toString() ?? '');
    _indiceDelictivo = widget.punto.indiceDelictivo;
    _tipoZona = widget.punto.tipoZona;
    _notasController = TextEditingController(
        text: widget.punto.optimizacionSitioNotas ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false)
          .fetchReportesPorPunto(widget.punto.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alturaPosteController.dispose();
    _distanciaNodoController.dispose();
    _notasController.dispose();
    _reporteObservacionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final pointsProvider = Provider.of<PointsProvider>(context, listen: false);

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
    };

    final ok = await pointsProvider.updatePunto(widget.punto.id, updates);
    setState(() => _isSaving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Punto de cámara actualizado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitReporte() async {
    if (_reporteObservacionController.text.trim().isEmpty) return;

    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    final ok = await reportsProvider.crearReporte(
      puntoId: widget.punto.id,
      observacion: _reporteObservacionController.text.trim(),
      fotoFile: _selectedImage,
    );

    if (ok && mounted) {
      _reporteObservacionController.clear();
      setState(() {
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observación registrada en el foro'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.videocam, color: Color(0xFF0284C7), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.punto.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Ubicación: ${widget.punto.latitud.toStringAsFixed(5)}, ${widget.punto.longitud.toStringAsFixed(5)} (${widget.punto.estado})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0284C7),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF94A3B8),
            tabs: const [
              Tab(icon: Icon(Icons.edit_note), text: 'Evaluación Campo'),
              Tab(icon: Icon(Icons.forum), text: 'Foro Reportes'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: FORMULARIO CAMPO
                SingleChildScrollView(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Energía Eléctrica disponible', style: TextStyle(color: Colors.white)),
                        value: _energiaElectrica,
                        onChanged: (val) => setState(() => _energiaElectrica = val),
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                      if (_energiaElectrica)
                        DropdownButtonFormField<String>(
                          initialValue: _nivelTension,
                          decoration: const InputDecoration(labelText: 'Nivel de Tensión'),
                          items: ['110V', '220V', 'Triphasic', 'OTRO']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _nivelTension = val),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Existencia de Poste', style: TextStyle(color: Colors.white)),
                        value: _existenciaPoste,
                        onChanged: (val) => setState(() => _existenciaPoste = val),
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                      if (_existenciaPoste)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: _alturaPosteController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Altura del Poste (Metros)',
                              suffixText: 'm',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Fibra Óptica cercana', style: TextStyle(color: Colors.white)),
                        value: _fibraOptica,
                        onChanged: (val) => setState(() => _fibraOptica = val),
                        activeThumbColor: const Color(0xFF10B981),
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
                      DropdownButtonFormField<String>(
                        initialValue: _indiceDelictivo,
                        decoration: const InputDecoration(labelText: 'Índice Delictivo del Sector'),
                        items: ['BAJO', 'MEDIO', 'ALTO', 'CRÍTICO']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => _indiceDelictivo = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tipoZona,
                        decoration: const InputDecoration(labelText: 'Tipo de Zona'),
                        items: ['COMERCIAL', 'RESIDENCIAL', 'INDUSTRIAL', 'VIALIDAD PRINCIPAL', 'RURAL']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => _tipoZona = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notasController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas de Optimización del Sitio',
                          hintText: 'Detalles adicionales, obstáculos, visibilidad...',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Guardar Evaluación'),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: FORO DE REPORTES
                Column(
                  children: [
                    Expanded(
                      child: reportsProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : reportsProvider.reportes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay reportes registrados para este punto',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: reportsProvider.reportes.length,
                                  itemBuilder: (ctx, i) {
                                    final rep = reportsProvider.reportes[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        title: Text(
                                          rep.observacion,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          'Por: ${rep.autorNombre ?? 'Inspector'} • ${rep.creadoEn.day}/${rep.creadoEn.month}/${rep.creadoEn.year} ${rep.creadoEn.hour}:${rep.creadoEn.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: rep.urlEvidenciaFoto != null
                                            ? const Icon(Icons.image, color: Color(0xFF0284C7))
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const Divider(color: Color(0xFF334155)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Color(0xFF0284C7)),
                          onPressed: _pickImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _reporteObservacionController,
                            decoration: const InputDecoration(
                              hintText: 'Escribir observación/reporte...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF0284C7)),
                          onPressed: _submitReporte,
                        ),
                      ],
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            const Text('Foto capturada', style: TextStyle(color: Colors.green, fontSize: 12)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
