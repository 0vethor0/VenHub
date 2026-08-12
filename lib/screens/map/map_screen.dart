import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/punto_camara.dart';
import '../../providers/points_provider.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import 'widgets/point_form_modal.dart';

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

  // Center of Yaracuy (San Felipe)
  final LatLng _initialCenter = const LatLng(10.339, -68.735);

  Color _getMarkerColor(PuntoCamara punto) {
    if (punto.energiaElectrica && punto.fibraOptica) {
      return const Color(0xFF10B981); // Emerald Green
    } else if (punto.energiaElectrica || punto.fibraOptica) {
      return const Color(0xFFF59E0B); // Amber
    }
    return const Color(0xFFDC2626); // Red
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

    // Apply local filters
    final filteredPuntos = pointsProvider.puntos.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesEnergia = !_filterEnergiaOnly || p.energiaElectrica;
      final matchesFibra = !_filterFibraOnly || p.fibraOptica;
      return matchesSearch && matchesEnergia && matchesFibra;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map, color: Colors.white),
            SizedBox(width: 8),
            Text('VEN911 - Yaracuy'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Foro de Reportes',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ven911.app',
              ),
              MarkerLayer(
                markers: filteredPuntos.map((punto) {
                  final color = _getMarkerColor(punto);
                  return Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(punto.latitud, punto.longitud),
                    child: GestureDetector(
                      onTap: () {
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
            ],
          ),

          // TOP SEARCH & FILTER BAR OVERLAY
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
                      style: const TextStyle(color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        hintText: 'Buscar punto de cámara...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF2563EB),
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
                            selectedColor: const Color(0xFF2563EB),
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
                            selectedColor: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              'Puntos: ${filteredPuntos.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: const Color(0xFFE2E8F0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // REFRESH / CENTER FAB BUTTONS
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                  onPressed: () {
                    pointsProvider.fetchPuntos();
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter_btn',
                  backgroundColor: const Color(0xFF2563EB),
                  child: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: () {
                    _mapController.move(_initialCenter, 13.0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
