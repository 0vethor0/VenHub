import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/points_provider.dart';
import '../map/widgets/point_form_modal.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Foro General de Puntos')),
      body: pointsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pointsProvider.puntos.length,
              itemBuilder: (ctx, i) {
                final punto = pointsProvider.puntos[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: punto.energiaElectrica
                          ? const Color(0xFF10B981)
                          : const Color(0xFFDC2626),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      punto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Energía: ${punto.energiaElectrica ? "SI" : "NO"} • Fibra: ${punto.fibraOptica ? "SI" : "NO"} • Poste: ${punto.existenciaPoste ? "SI" : "NO"}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => PointFormModal(punto: punto),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
