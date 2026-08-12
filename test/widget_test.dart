import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ven911_app/providers/auth_provider.dart';
import 'package:ven911_app/providers/points_provider.dart';
import 'package:ven911_app/providers/reports_provider.dart';
import 'package:ven911_app/providers/version_update_provider.dart';
import 'package:ven911_app/screens/splash_screen.dart';

class MockGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getItem({required String key}) async => _storage[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }
}

void main() {
  setUpAll(() async {
    // Initialize Supabase with dummy credentials and custom memory-based storages to prevent plugin channel errors in tests
    await Supabase.initialize(
      url: 'https://juktboqlmcnydepwlnpy.supabase.co',
      publishableKey: 'dummy-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MockGotrueAsyncStorage(),
      ),
    );
  });

  testWidgets('Splash screen renders basic text and loader', (
    WidgetTester tester,
  ) async {
    // Pump the SplashScreen wrapped in the necessary providers.
    // Realtime is disabled in providers to avoid Supabase Realtime errors in tests.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => PointsProvider(enableRealtime: false),
          ),
          ChangeNotifierProvider(create: (_) => ReportsProvider()),
          ChangeNotifierProvider(
            create: (_) => VersionUpdateProvider(enableRealtime: false),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Verify that the splash screen title 'VEN 911' is rendered.
    expect(find.text('VEN 911'), findsOneWidget);

    // Verify that the subtitle is rendered.
    expect(find.text('Levantamiento de Campo - Yaracuy'), findsOneWidget);

    // Verify that the circular progress loader is present.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Drain the pending timer from Future.delayed inside SplashScreen._checkAuth
    await tester.pump(const Duration(seconds: 2));
  });
}
