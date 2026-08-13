import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final idShort = profile != null && profile.id.length >= 8
        ? profile.id.substring(0, 8)
        : 'INST-882';

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil del Inspector'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 54,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.nombre ?? 'Inspector',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Técnico Nivel Senior',
                          style: TextStyle(fontSize: 14, color: Colors.white60),
                        ),
                        Text(
                          'ID: $idShort',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'CONFIGURACIÓN GENERAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.sync,
                title: 'Sincronización Automática',
                subtitle: 'Subir reportes al terminar',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Modo Oscuro',
                subtitle: 'Ahorro de batería en campo',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Notificaciones',
                subtitle: 'Alertas de nuevas asignaciones',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'DATOS Y ALMACENAMIENTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.map,
                title: 'Mapas sin Conexión',
                subtitle: 'Descargar áreas de trabajo  1.2 GB',
                trailing: const Text(
                  'Descargar',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.photo_library,
                title: 'Limpiar Caché de Fotos',
                subtitle: 'Libera espacio local',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white60),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }
}
