
---

## 📁 1. Nuevo archivo de tema (`lib/theme/app_theme.dart`)

Este archivo centraliza todos los colores, tipografías y estilos según los wireframes. Incluye dos variantes: **oscuro** (para splash, login, register y perfil) y **claro** (para el resto de pantallas). La barra inferior utiliza el tema oscuro.

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // ---- Paleta de colores extraída de los wireframes ----
  static const Color primaryDark = Color(0xFF0F172A);   // Fondo oscuro (splash, perfil)
  static const Color primaryBlue = Color(0xFF2563EB);   // Azul de acento (botones, estadísticas)
  static const Color dangerRed = Color(0xFFDC2626);     // Rojo para pendientes/alertas
  static const Color successGreen = Color(0xFF10B981);  // Verde para completados
  static const Color warningYellow = Color(0xFFF59E0B); // Amarillo para advertencias

  static const Color bgLight = Color(0xFFF8FAFC);       // Fondo claro (mapa, reportes)
  static const Color cardWhite = Color(0xFFFFFFFF);     // Tarjetas blancas
  static const Color textDark = Color(0xFF1E293B);      // Texto oscuro
  static const Color textMuted = Color(0xFF64748B);     // Texto secundario
  static const Color borderLight = Color(0xFFE2E8F0);   // Bordes claros

  // Para fondos oscuros
  static const Color textLight = Color(0xFFFFFFFF);

  // ---- Tipografía ----
  static const String fontFamily = 'Roboto'; // O la que prefieras

  // ---- Tema claro (para la mayoría de pantallas) ----
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: cardWhite,
      error: dangerRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textLight),
    ),
    cardTheme: CardTheme(
      color: cardWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryDark,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ---- Tema oscuro (para splash, login, register, perfil) ----
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryDark,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryDark,
      secondary: primaryBlue,
      surface: Color(0xFF1E293B),
      error: dangerRed,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textLight),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white60),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryDark,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
  );
}
```

---

## 📁 2. Añadir el icono de la app como asset

Copia el archivo `data/Wireframes UI Kit/icon.png` a la carpeta `assets/`. Luego, en `pubspec.yaml`, añade:

```yaml
flutter:
  assets:
    - .env
    - assets/icon.png   # ← nueva línea
```

---

## 📁 3. Nuevo `splash_screen.dart` (Body.png)

Fondo oscuro, logo centrado (el icono de la app), y texto de estado.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/version_update_provider.dart';
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
      nextScreen = const HomeScreen();  // ← ahora va a HomeScreen
    } else {
      nextScreen = const LoginScreen();
    }

    if (mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
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
            // Logo centrado (icono)
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
```

---

## 📁 4. Nueva pantalla de inicio (`home_screen.dart`) con barra inferior

Esta pantalla contiene la barra de navegación inferior y las páginas (Inicio, Mapa, Reportes, Ajustes). La primera pestaña (Inicio) muestra el resumen de reportes y pendientes, tal como en Body-1.png.

Crea `lib/screens/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../map/map_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/points_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeTab(),      // Índice 0
    MapScreen(),    // Índice 1
    ReportsScreen(),// Índice 2
    ProfileScreen(),// Índice 3
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// ---- Pestaña de Inicio (Body-1.png) ----
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Calcular estadísticas
    final total = pointsProvider.puntos.length;
    final conEnergia = pointsProvider.puntos.where((p) => p.energiaElectrica).length;
    final conFibra = pointsProvider.puntos.where((p) => p.fibraOptica).length;
    final pendientes = pointsProvider.puntos.where((p) => !p.energiaElectrica && !p.fibraOptica).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hola, Instalador'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido de nuevo a CAM-G',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            // Tarjetas de estadísticas
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'REPORTES HOY',
                    value: pointsProvider.reportes.length.toString(),
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
            // Botón Nuevo Reporte
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Abrir modal para nuevo reporte (puedes redirigir a mapa)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nuevo Reporte (en desarrollo)')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Mapa de ubicaciones (sección)
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
              child: const Center(
                child: Text(
                  'Vista previa del mapa',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Actividad Reciente
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _ActivityCard(
              title: 'Residencia Las Flores',
              subtitle: 'Cámara DOMO-IP instalada',
              time: '10:30 AM',
            ),
            const _ActivityCard(
              title: 'Condominio El Rosal',
              subtitle: 'Revisión de conexión',
              time: '09:45 AM',
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Widget auxiliar: tarjeta de estadística ----
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

// ---- Widget auxiliar: tarjeta de actividad ----
class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const _ActivityCard({required this.title, required this.subtitle, required this.time});

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
```

---

## 📁 5. Modificar `login_screen.dart` (fondo oscuro, estilo Body.png)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'update_password_screen.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AuthProvider? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth = Provider.of<AuthProvider>(context, listen: false);
      _auth!.addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.pendingPasswordUpdate) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
      );
      return;
    }
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && auth.friendlyErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.friendlyErrorMessage!),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final launched = await auth.loginWithGoogle();
    if (!mounted) return;
    if (!launched && auth.friendlyErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.friendlyErrorMessage!),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 64,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acceso para personal de levantamiento VEN911',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su correo';
                          }
                          if (!value.contains('@')) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingrese su contraseña'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _handleGoogleLogin,
                        icon: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.white,
                              ),
                        label: const Text('Continuar con Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿No tienes cuenta? Regístrate aquí',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 📁 6. Modificar `register_screen.dart` (fondo oscuro)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted && auth.friendlyErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.friendlyErrorMessage!),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registro de Inspector')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crear Nueva Cuenta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingrese sus datos oficiales para crear una cuenta',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese su nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese su correo'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña (mínimo 6 caracteres)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Registrar Cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 📁 7. Modificar `map_screen.dart` (fondo claro, estilo Body-2)

Elimina el `AppBar` personalizado y la navegación hacia Reports y Profile, porque ahora eso lo maneja la barra inferior. Conserva la lógica del mapa, los filtros y el modal.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/punto_camara.dart';
import '../../providers/points_provider.dart';
import '../../theme/app_theme.dart';
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

  final LatLng _initialCenter = const LatLng(10.339, -68.735);

  Color _getMarkerColor(PuntoCamara punto) {
    if (punto.energiaElectrica && punto.fibraOptica) {
      return AppTheme.successGreen;
    } else if (punto.energiaElectrica || punto.fibraOptica) {
      return AppTheme.warningYellow;
    }
    return AppTheme.dangerRed;
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

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
                              color: Colors.black.withOpacity(0.3),
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
          // Barra de búsqueda y filtros (igual que antes)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Buscar punto de cámara...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
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
                            label: const Text('Con Energía', style: TextStyle(fontSize: 12)),
                            selected: _filterEnergiaOnly,
                            onSelected: (val) => setState(() => _filterEnergiaOnly = val),
                            selectedColor: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Con Fibra Óptica', style: TextStyle(fontSize: 12)),
                            selected: _filterFibraOnly,
                            onSelected: (val) => setState(() => _filterFibraOnly = val),
                            selectedColor: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              'Puntos: ${filteredPuntos.length}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppTheme.borderLight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botones de centrar y refrescar (sin cambios)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                  onPressed: () => pointsProvider.fetchPuntos(),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter_btn',
                  backgroundColor: AppTheme.primaryBlue,
                  child: const Icon(Icons.my_location, color: Colors.white),
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
```

---

## 📁 8. Modificar `reports_screen.dart` (Body-3)

Mantén la lista de reportes con tarjetas que muestren el estado (RECOMENDADO, INTERFERENCIA, TÉCNICO) con colores.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/points_provider.dart';
import '../../theme/app_theme.dart';
import '../map/widgets/point_form_modal.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsProvider = Provider.of<PointsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Instalación'),
        automaticallyImplyLeading: false,
      ),
      body: pointsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pointsProvider.puntos.length,
              itemBuilder: (ctx, i) {
                final punto = pointsProvider.puntos[i];
                // Determinar estado según los campos
                String estado = 'RECOMENDADO';
                Color estadoColor = AppTheme.successGreen;
                if (!punto.energiaElectrica && !punto.fibraOptica) {
                  estado = 'INTERFERENCIA';
                  estadoColor = AppTheme.dangerRed;
                } else if (!punto.energiaElectrica || !punto.fibraOptica) {
                  estado = 'TÉCNICO';
                  estadoColor = AppTheme.warningYellow;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      punto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${punto.id.substring(0, 8)} • ${_timeAgo(punto.actualizadoEn)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: estadoColor, width: 1),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Domo IP 4K', // Podrías poner el tipo de cámara (si lo tienes)
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, size: 16, color: AppTheme.textMuted),
                          ],
                        ),
                      ],
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

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'ahora';
  }
}
```

---

## 📁 9. Modificar `profile_screen.dart` (Body-4)

Fondo oscuro, avatar, nombre, rol, opciones de configuración.

```dart
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
              // Avatar y nombre
              Row(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 54, color: AppTheme.primaryBlue),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          'ID: ${profile?.id.substring(0, 8) ?? 'INST-882'}',
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

              // Configuración General
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
                  activeColor: AppTheme.primaryBlue,
                ),
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Modo Oscuro',
                subtitle: 'Ahorro de batería en campo',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppTheme.primaryBlue,
                ),
              ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Notificaciones',
                subtitle: 'Alertas de nuevas asignaciones',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Datos y Almacenamiento
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
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              ),
              const SizedBox(height: 32),

              // Botón Cerrar Sesión
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }
}
```

---

## 📁 10. `point_form_modal.dart` (sin cambios en lógica, solo estilos)

Asegúrate de que el modal use los colores del tema. Puedes ajustar el fondo y los bordes para que sean blancos y con sombra, tal como aparece en los wireframes. El código actual ya es bastante bueno, solo verifica que los colores de los botones y campos coincidan con `AppTheme`.

---

## 📁 11. Ajuste en `main.dart`

Cambia el `home` a `HomeScreen` y asegúrate de que el tema se aplique correctamente. Usa el tema claro por defecto, pero las pantallas que necesitan oscuro lo establecerán localmente con `Theme(data: AppTheme.darkTheme, child: ...)`.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/points_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/version_update_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Advertencia: No se pudo cargar .env como asset");
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://juktboqlmcnydepwlnpy.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const Ven911App());
}

class Ven911App extends StatefulWidget {
  const Ven911App({super.key});

  @override
  State<Ven911App> createState() => _Ven911AppState();
}

class _Ven911AppState extends State<Ven911App> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    final url = uri.toString();
    if (!url.contains('reset-callback')) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.handleResetPasswordRedirect(url);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => VersionUpdateProvider()..init()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'VEN 911 - Levantamiento de Campo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
```

---

## 📁 12. `update_password_screen.dart` y `reset_password_screen.dart`

Aplica el tema oscuro a estas pantallas también, igual que hicimos con login y register. Envuelve el `Scaffold` en `Theme(data: AppTheme.darkTheme, child: ...)`.

---

