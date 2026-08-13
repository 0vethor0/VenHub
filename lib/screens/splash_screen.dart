import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/version_update_provider.dart';
import 'auth/login_screen.dart';
import 'auth/update_password_screen.dart';
import 'map/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final updateProvider = Provider.of<VersionUpdateProvider>(
      context,
      listen: false,
    );
    await updateProvider.checkForUpdates();

    if (!mounted) return;

    if (updateProvider.updateAvailable && updateProvider.isRequired) {
      updateProvider.showUpdateDialog();
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final Widget nextScreen;
    if (auth.pendingPasswordUpdate) {
      nextScreen = const UpdatePasswordScreen();
    } else if (auth.isAuthenticated) {
      nextScreen = const MapScreen();
    } else {
      nextScreen = const LoginScreen();
    }

    if (mounted) {
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
    }

    if (updateProvider.updateAvailable && !updateProvider.isRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateProvider.showUpdateDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2563EB), width: 2),
              ),
              child: const Icon(
                Icons.videocam_outlined,
                size: 80,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'VEN 911',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Levantamiento de Campo - Yaracuy',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }
}
