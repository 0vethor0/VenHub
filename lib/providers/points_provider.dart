import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/punto_camara.dart';

class PointsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PuntoCamara> _puntos = [];
  PuntoCamara? _selectedPunto;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final bool enableRealtime;

  List<PuntoCamara> get puntos => _puntos;
  PuntoCamara? get selectedPunto => _selectedPunto;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PointsProvider({this.enableRealtime = true}) {
    fetchPuntos();
    if (enableRealtime) {
      _bindRealtimeToAuth();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void selectPunto(PuntoCamara? punto) {
    _selectedPunto = punto;
    notifyListeners();
  }

  Future<void> fetchPuntos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Execute query to select points with PostGIS ST_AsGeoJSON
      final res = await _supabase.rpc('get_puntos_camara_geojson').catchError((
        _,
      ) async {
        // Fallback to normal select if RPC isn't deployed yet
        return await _supabase.from('puntos_camara').select('*');
      });

      if (res is List) {
        _puntos = res
            .map((item) => PuntoCamara.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Try direct select fallback
      try {
        final fallbackRes = await _supabase.from('puntos_camara').select('*');
        _puntos = (fallbackRes as List)
            .map((item) => PuntoCamara.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (err) {
        _errorMessage = err.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _bindRealtimeToAuth() {
    void syncSubscription(Session? session) {
      if (session != null) {
        _subscribeRealtime();
      } else {
        _realtimeSubscription?.cancel();
        _realtimeSubscription = null;
      }
    }

    syncSubscription(_supabase.auth.currentSession);
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      syncSubscription(data.session);
    });
  }

  void _subscribeRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _supabase
        .from('puntos_camara')
        .stream(primaryKey: ['id'])
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) fetchPuntos();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('PointsProvider: Realtime error: $error');
            _realtimeSubscription?.cancel();
            _realtimeSubscription = null;
          },
        );
  }

  Future<bool> updatePunto(String puntoId, Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final data = {
        ...updates,
        'actualizado_por': userId,
        'actualizado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('puntos_camara').update(data).eq('id', puntoId);
      await fetchPuntos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
