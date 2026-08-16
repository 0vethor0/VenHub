import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Envuelve connectivity_plus en un servicio simple y reutilizable.
///
/// Se registra UNA sola vez a nivel de aplicación (ver main.dart) para
/// que tanto el mapa como, más adelante, el resto de la app (el plan de
/// modo offline general que ya discutieron) puedan reutilizar la misma
/// fuente de verdad sobre el estado de conexión, en vez de que cada
/// pantalla implemente su propia detección por separado.
///
/// Nota: connectivity_plus reporta si hay una interfaz de red activa
/// (WiFi/datos), no si hay internet real (puede haber WiFi sin salida a
/// internet). Para este caso de uso es suficiente; si más adelante se
/// necesita una validación más estricta, se puede añadir un ping HTTP
/// ligero — no se incluye aquí para no sumar complejidad innecesaria.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    _isOnline = _resolveOnline(initial);
    _controller.add(_isOnline);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resolveOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _resolveOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
