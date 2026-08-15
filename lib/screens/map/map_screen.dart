import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/punto_camara.dart';
import '../../models/punto_fibra_optica.dart';
import '../../models/propuesta_punto_camara.dart';
import '../../providers/fibra_provider.dart';
import '../../providers/points_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/fibra_form_modal.dart';
import 'widgets/point_form_modal.dart';
import 'widgets/propuesta_form_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String _searchQuery = '';
  bool _filterEnergiaOnly = false;
  bool _filterFibraOnly = false;
  bool _isEditMode = false;
  String? _draggingPointId;
  bool _isDraggingPropuesta = false;
  bool _isDraggingFibra = false;
  bool _isMeasuring = false;
  final List<LatLng> _measurePoints = [];
  double? _measureDistanceMeters;
  String? _guidedMeasureTargetId;
  String? _guidedMeasureTargetType;
  LatLng? _currentLocation;
  double? _currentHeading;
  StreamSubscription<Position>? _positionSub;
  bool _followMe = false;

  static const _distanceCalc = Distance();
  final LatLng _initialCenter = const LatLng(10.339, -68.735);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _currentHeading = pos.heading >= 0 ? pos.heading : null;
      });
    } catch (_) {}

    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          if (!mounted) return;
          final latLng = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentLocation = latLng;
            _currentHeading = pos.heading >= 0 ? pos.heading : null;
          });
          if (_followMe) {
            _mapController.move(latLng, _mapController.camera.zoom);
          }
        });
  }

  Color _getMarkerColor(PuntoCamara punto) {
    if (punto.energiaElectrica && punto.fibraOptica) {
      return AppTheme.successGreen;
    } else if (punto.energiaElectrica || punto.fibraOptica) {
      return AppTheme.warningYellow;
    }
    return AppTheme.dangerRed;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(1)} m';
  }

  void _addMeasurePoint(LatLng point) {
    setState(() {
      if (_measurePoints.length >= 2) {
        _measurePoints
          ..clear()
          ..add(point);
        _measureDistanceMeters = null;
      } else {
        _measurePoints.add(point);
        if (_measurePoints.length == 2) {
          _measureDistanceMeters = _distanceCalc(
            _measurePoints[0],
            _measurePoints[1],
          );
        }
      }
    });

    if (_measurePoints.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toca el segundo punto para medir la distancia.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleMeasureMode() {
    setState(() {
      _isMeasuring = !_isMeasuring;
      if (_isMeasuring) {
        _isEditMode = false;
        _draggingPointId = null;
        _isDraggingPropuesta = false;
        _isDraggingFibra = false;
      }
      _measurePoints.clear();
      _measureDistanceMeters = null;
      _guidedMeasureTargetId = null;
      _guidedMeasureTargetType = null;
    });

    if (_isMeasuring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo medición: toca el mapa o un punto existente.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearMeasurement() {
    setState(() {
      _measurePoints.clear();
      _measureDistanceMeters = null;
      _guidedMeasureTargetId = null;
      _guidedMeasureTargetType = null;
    });
  }

  void _startGuidedMeasure(
    LatLng from, {
    String? targetId,
    String? targetType,
  }) {
    setState(() {
      _isMeasuring = true;
      _isEditMode = false;
      _measurePoints
        ..clear()
        ..add(from);
      _measureDistanceMeters = null;
      _guidedMeasureTargetId = targetId;
      _guidedMeasureTargetType = targetType;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca el punto de destino para medir la distancia.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleMapTap(TapPosition _, LatLng point) {
    if (_isMeasuring) {
      _addMeasurePoint(point);
      return;
    }
    if (_isEditMode && _draggingPointId != null) {
      _placeDraggingPoint(point);
      return;
    }
    if (_isEditMode) {
      showModalBottomSheet(
        context: context,
        builder: (_) => _NewPointTypeSheet(point: point),
      );
    }
  }

  void _startDragging({
    required String id,
    required bool isPropuesta,
    required bool isFibra,
  }) {
    setState(() {
      _draggingPointId = id;
      _isDraggingPropuesta = isPropuesta;
      _isDraggingFibra = isFibra;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mantén el modo edición. Toca el mapa para colocar el punto en la nueva ubicación.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelDragging() {
    if (_draggingPointId == null) return;
    setState(() {
      _draggingPointId = null;
      _isDraggingPropuesta = false;
      _isDraggingFibra = false;
    });
  }

  Future<void> _placeDraggingPoint(LatLng point) async {
    if (_draggingPointId == null) return;

    if (!mounted) return;

    final pointsProvider = Provider.of<PointsProvider>(context, listen: false);
    final fibraProvider = Provider.of<FibraProvider>(context, listen: false);

    bool success = false;

    if (_isDraggingPropuesta) {
      success = await pointsProvider.updateUbicacion(
        _draggingPointId!,
        point.latitude,
        point.longitude,
        isPropuesta: true,
      );
    } else if (_isDraggingFibra) {
      success = await fibraProvider.updateUbicacion(
        _draggingPointId!,
        point.latitude,
        point.longitude,
      );
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _draggingPointId = null;
        _isDraggingPropuesta = false;
        _isDraggingFibra = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación actualizada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar ubicación')),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

    final filteredExistentes = pointsProvider.puntosExistentes.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesEnergia = !_filterEnergiaOnly || p.energiaElectrica;
      final matchesFibra = !_filterFibraOnly || p.fibraOptica;
      return matchesSearch && matchesEnergia && matchesFibra;
    }).toList();

    final filteredPropuestas = pointsProvider.propuestas.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      final validCoordinates = !(p.latitud == 0.0 && p.longitud == 0.0);
      return matchesSearch && validCoordinates;
    }).toList();

    final fibraProvider = Provider.of<FibraProvider>(context);
    final filteredFibra = fibraProvider.puntos.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (p.direccion?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa - Yaracuy'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              onTap: (_isEditMode || _isMeasuring) ? _handleMapTap : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ven911.app',
              ),
              if (_measurePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _measurePoints,
                      color: Colors.deepOrange,
                      strokeWidth: 4,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: filteredExistentes.map((punto) {
                  final color = _getMarkerColor(punto);
                  return Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(punto.latitud, punto.longitud),
                    child: GestureDetector(
                      onTap: () {
                        if (_isMeasuring) {
                          _addMeasurePoint(
                            LatLng(punto.latitud, punto.longitud),
                          );
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => PointFormModal(punto: punto),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: filteredPropuestas.map((propuesta) {
                  return Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(propuesta.latitud, propuesta.longitud),
                    child: GestureDetector(
                      onTap: () async {
                        if (_isMeasuring) {
                          _addMeasurePoint(
                            LatLng(propuesta.latitud, propuesta.longitud),
                          );
                          return;
                        }
                        if (_draggingPointId == propuesta.id) {
                          _cancelDragging();
                          return;
                        }
                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              PropuestaFormModal(propuesta: propuesta),
                        );
                        if (result is LatLng && mounted) {
                          _startGuidedMeasure(
                            result,
                            targetId: propuesta.id,
                            targetType: 'propuesta',
                          );
                        }
                      },
                      onLongPress: _isEditMode
                          ? () {
                              _startDragging(
                                id: propuesta.id,
                                isPropuesta: true,
                                isFibra: false,
                              );
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isEditMode && _draggingPointId == propuesta.id
                              ? AppTheme.warningYellow
                              : AppTheme.successGreen,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Transform.rotate(
                            angle: -0.785398,
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: filteredFibra.map((punto) {
                  return Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(punto.latitud, punto.longitud),
                    child: GestureDetector(
                      onTap: () async {
                        if (_isMeasuring) {
                          _addMeasurePoint(
                            LatLng(punto.latitud, punto.longitud),
                          );
                          return;
                        }
                        if (_draggingPointId == punto.id) {
                          _cancelDragging();
                          return;
                        }
                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => FibraFormModal(punto: punto),
                        );
                        if (result is LatLng && mounted) {
                          _startGuidedMeasure(
                            result,
                            targetId: punto.id,
                            targetType: 'fibra',
                          );
                        }
                      },
                      onLongPress: _isEditMode
                          ? () {
                              _startDragging(
                                id: punto.id,
                                isPropuesta: false,
                                isFibra: true,
                              );
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isEditMode && _draggingPointId == punto.id
                              ? AppTheme.warningYellow
                              : AppTheme.primaryBlue,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.settings_input_component,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_measurePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    ..._measurePoints.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      return Marker(
                        point: point,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.deepOrange : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      );
                    }),
                    if (_measureDistanceMeters != null &&
                        _measurePoints.length == 2)
                      Marker(
                        point: LatLng(
                          (_measurePoints[0].latitude +
                                  _measurePoints[1].latitude) /
                              2,
                          (_measurePoints[0].longitude +
                                  _measurePoints[1].longitude) /
                              2,
                        ),
                        width: 120,
                        height: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDistance(_measureDistanceMeters!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 48,
                      height: 48,
                      point: _currentLocation!,
                      child: Transform.rotate(
                        angle: ((_currentHeading ?? 0) * math.pi / 180),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_measureDistanceMeters != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 80,
              child: Card(
                color: Colors.deepOrange.shade700,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.straighten, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Distancia: ${_formatDistance(_measureDistanceMeters!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_guidedMeasureTargetId != null &&
                          _guidedMeasureTargetType != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _isMeasuring = false);
                            final pointsProvider = Provider.of<PointsProvider>(
                              context,
                              listen: false,
                            );
                            final fibraProvider = Provider.of<FibraProvider>(
                              context,
                              listen: false,
                            );

                            if (_guidedMeasureTargetType == 'propuesta') {
                              final target = pointsProvider.propuestas
                                  .firstWhere(
                                    (p) => p.id == _guidedMeasureTargetId,
                                    orElse: () =>
                                        pointsProvider.propuestas.first,
                                  );
                              if (!mounted) return;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => PropuestaFormModal(
                                  propuesta: target,
                                  distanciaInicialMetros:
                                      _measureDistanceMeters,
                                ),
                              );
                            } else if (_guidedMeasureTargetType == 'fibra') {
                              final target = fibraProvider.puntos.firstWhere(
                                (p) => p.id == _guidedMeasureTargetId,
                                orElse: () => fibraProvider.puntos.first,
                              );
                              if (!mounted) return;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => FibraFormModal(
                                  punto: target,
                                  distanciaInicialMetros:
                                      _measureDistanceMeters,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Rellenar campo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Limpiar medición',
                        onPressed: _clearMeasurement,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Buscar punto de cámara...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryBlue,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text(
                              'Con Energía',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: _filterEnergiaOnly,
                            onSelected: (val) =>
                                setState(() => _filterEnergiaOnly = val),
                            selectedColor: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text(
                              'Con Fibra Óptica',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: _filterFibraOnly,
                            onSelected: (val) =>
                                setState(() => _filterFibraOnly = val),
                            selectedColor: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              'Puntos: ${filteredExistentes.length + filteredPropuestas.length + filteredFibra.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: AppTheme.borderLight,
                          ),
                          const SizedBox(width: 8),
                          if (_isEditMode)
                            Chip(
                              label: const Text(
                                'Modo Edición Activo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppTheme.warningYellow,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'measure_btn',
                  backgroundColor: _isMeasuring
                      ? Colors.deepOrange
                      : Colors.white,
                  onPressed: _toggleMeasureMode,
                  tooltip: _isMeasuring
                      ? 'Salir de medición'
                      : 'Medir distancia',
                  child: Icon(
                    Icons.straighten,
                    color: _isMeasuring ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'edit_mode_btn',
                  backgroundColor: _isEditMode
                      ? AppTheme.warningYellow
                      : Colors.white,
                  child: Icon(
                    _isEditMode ? Icons.edit_off : Icons.edit_location_alt,
                    color: _isEditMode ? Colors.white : AppTheme.primaryBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                      if (_isEditMode) {
                        _isMeasuring = false;
                        _measurePoints.clear();
                        _measureDistanceMeters = null;
                      }
                      if (!_isEditMode) {
                        _draggingPointId = null;
                        _isDraggingPropuesta = false;
                        _isDraggingFibra = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                  onPressed: () => pointsProvider.fetchPuntos(),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location_btn',
                  backgroundColor: _followMe
                      ? AppTheme.primaryBlue
                      : Colors.white,
                  onPressed: () {
                    if (_currentLocation == null) return;
                    setState(() => _followMe = !_followMe);
                    _mapController.move(_currentLocation!, 16.0);
                  },
                  child: Icon(
                    Icons.my_location,
                    color: _followMe ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter_btn',
                  backgroundColor: AppTheme.primaryBlue,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                  ),
                  onPressed: () => _mapController.move(_initialCenter, 13.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewPointTypeSheet extends StatelessWidget {
  final LatLng point;

  const _NewPointTypeSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context, listen: false);
    final nearest = _nearestCamara(point, pointsProvider.puntosExistentes);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nuevo punto de interés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Transform.rotate(
              angle: 0.785398,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: const Icon(Icons.videocam, color: Colors.white),
                ),
              ),
            ),
            title: const Text('Propuesta de mejora de cámara'),
            subtitle: Text(
              nearest != null
                  ? 'Sugerencia: Mejora a ${nearest.nombre}'
                  : 'Sin cámara cercana identificada',
            ),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => PropuestaFormModal(
                  propuesta: PropuestaPuntoCamara(
                    id: '', // New proposal
                    nombre: 'Propuesta: ${nearest?.nombre ?? "Nueva"}',
                    latitud: point.latitude,
                    longitud: point.longitude,
                    puntoCamaraReferenciaId: nearest?.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.settings_input_component,
                color: Colors.white,
              ),
            ),
            title: const Text('Punto de Fibra Óptica'),
            subtitle: const Text('Azul — Nodo o reserva de fibra'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => FibraFormModal(
                  punto: PuntoFibraOptica(
                    id: '',
                    latitud: point.latitude,
                    longitud: point.longitude,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  PuntoCamara? _nearestCamara(LatLng point, List<PuntoCamara> puntos) {
    return nearestCamara(point, puntos);
  }
}

PuntoCamara? nearestCamara(LatLng point, List<PuntoCamara> puntos) {
  const dist = Distance();
  PuntoCamara? nearest;
  double best = double.infinity;
  for (final p in puntos) {
    final d = dist(point, LatLng(p.latitud, p.longitud));
    if (d < best) {
      best = d;
      nearest = p;
    }
  }
  return nearest;
}
