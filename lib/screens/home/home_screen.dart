import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/punto_camara.dart';
import '../../providers/points_provider.dart';
import '../../theme/app_theme.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomeTab(),
    const MapScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Ajustes'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  int _reportesHoy(List<PuntoCamara> puntos) {
    final hoy = DateTime.now();
    return puntos.where((p) {
      final d = p.actualizadoEn;
      if (d == null) return false;
      return d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
    }).length;
  }

  List<PuntoCamara> _actividadReciente(List<PuntoCamara> puntos) {
    final sorted = List<PuntoCamara>.from(puntos)
      ..sort((a, b) {
        final da = a.actualizadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.actualizadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    return sorted.take(3).toList();
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _subtitle(PuntoCamara punto) {
    if (punto.energiaElectrica && punto.fibraOptica) {
      return 'Instalación completa';
    }
    if (!punto.energiaElectrica && !punto.fibraOptica) {
      return 'Pendiente de revisión';
    }
    return 'Revisión parcial en curso';
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);
    final pendientes = pointsProvider.puntos
        .where((p) => !p.energiaElectrica && !p.fibraOptica)
        .length;
    final recientes = _actividadReciente(pointsProvider.puntos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hola, Instalador'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido de nuevo a CAM-G',
              style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'REPORTES HOY',
                    value: _reportesHoy(pointsProvider.puntos).toString(),
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'PENDIENTES',
                    value: pendientes.toString(),
                    color: AppTheme.dangerRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nuevo Reporte (en desarrollo)')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Reporte'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mapa Ubicaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Center(
                child: Text(
                  '${pointsProvider.puntos.length} puntos registrados',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            if (recientes.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Sin actividad reciente'),
                  subtitle: Text('Los puntos actualizados aparecerán aquí'),
                ),
              )
            else
              ...recientes.map(
                (p) => _ActivityCard(
                  title: p.nombre,
                  subtitle: _subtitle(p),
                  time: _formatTime(p.actualizadoEn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(time, style: const TextStyle(color: AppTheme.textMuted)),
      ),
    );
  }
}
