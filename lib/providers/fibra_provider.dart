import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/punto_fibra_optica.dart';

class FibraProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PuntoFibraOptica> _puntos = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final bool enableRealtime;

  List<PuntoFibraOptica> get puntos => _puntos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FibraProvider({this.enableRealtime = true}) {
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

  Future<void> fetchPuntos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.rpc('get_puntos_fibra_geojson').catchError((
        _,
      ) async {
        return await _supabase.from('puntos_fibra_optica').select('*');
      });

      if (res is List) {
        _puntos = res
            .map(
              (item) => PuntoFibraOptica.fromMap(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      try {
        final fallbackRes = await _supabase
            .from('puntos_fibra_optica')
            .select('*');
        _puntos = (fallbackRes as List)
            .map(
              (item) => PuntoFibraOptica.fromMap(item as Map<String, dynamic>),
            )
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
        .from('puntos_fibra_optica')
        .stream(primaryKey: ['id'])
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) fetchPuntos();
          },
          onError: (Object error) {
            debugPrint('FibraProvider: Realtime error: $error');
            _realtimeSubscription?.cancel();
            _realtimeSubscription = null;
          },
        );
  }

  Future<bool> crearPuntoFibra({
    required double lat,
    required double lon,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('puntos_fibra_optica').insert({
        'ubicacion': 'POINT($lon $lat)',
        'creado_por': userId,
        ...data,
      });
      await fetchPuntos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePuntoFibra(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('puntos_fibra_optica').update(updates).eq('id', id);
      await fetchPuntos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
