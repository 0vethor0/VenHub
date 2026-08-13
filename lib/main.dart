import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/points_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/version_update_provider.dart';
import 'screens/auth/update_password_screen.dart';
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

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://juktboqlmcnydepwlnpy.supabase.co';
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

  void _handleDeepLink(Uri uri) async {
    final url = uri.toString();

    // Caso 1: Recuperación de contraseña (ya existente)
    if (url.contains('reset-callback')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.handleResetPasswordRedirect(url);

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
      });
      return;
    }

    // Caso 2: Login con Google (nuevo)
    if (url.contains('login-callback')) {
      try {
        // recoverSession extrae los tokens de la URL y los guarda en Supabase
        final response = await Supabase.instance.client.auth.recoverSession(
          url,
        );
        if (response.session != null) {
          debugPrint(
            '✅ Sesión de Google restaurada: ${response.session?.user.email}',
          );
          // No es necesario navegar aquí; AuthProvider reaccionará al evento SIGNED_IN
        }
      } catch (e) {
        debugPrint('❌ Error al restaurar sesión de Google: $e');
      }
    }
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
