import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/version_update_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/update_password_screen.dart';
import 'home/home_screen.dart';

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
      nextScreen = const HomeScreen();
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
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              '911',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cargando datos del sitio...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Validando cobertura y red...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'INSTALACIÓN Y SEGURIDAD V2.4',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white38,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
