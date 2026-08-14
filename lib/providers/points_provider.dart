import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/punto_camara.dart';
import '../models/propuesta_punto_camara.dart';

class PointsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PuntoCamara> _puntos = [];
  List<PropuestaPuntoCamara> _propuestas = [];
  PuntoCamara? _selectedPunto;
  PropuestaPuntoCamara? _selectedPropuesta;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  StreamSubscription<List<Map<String, dynamic>>>?
  _realtimePropuestasSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final bool enableRealtime;

  List<PuntoCamara> get puntos => _puntos;
  List<PropuestaPuntoCamara> get propuestas => _propuestas;
  List<PuntoCamara> get puntosExistentes =>
      _puntos.where((p) => p.tipoPunto == 'existente').toList();
  List<PuntoCamara> get puntosPropuestaMejora =>
      _puntos.where((p) => p.tipoPunto == 'propuesta_mejora').toList();

  PuntoCamara? get selectedPunto => _selectedPunto;
  PropuestaPuntoCamara? get selectedPropuesta => _selectedPropuesta;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PointsProvider({this.enableRealtime = true}) {
    fetchAllData();
    if (enableRealtime) {
      _bindRealtimeToAuth();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimePropuestasSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void selectPunto(PuntoCamara? punto) {
    _selectedPunto = punto;
    _selectedPropuesta = null;
    notifyListeners();
  }

  void selectPropuesta(PropuestaPuntoCamara? propuesta) {
    _selectedPropuesta = propuesta;
    _selectedPunto = null;
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
        _puntos = res.map((item) => PuntoCamara.fromMap(item)).toList();
      }
    } catch (e) {
      // Try direct select fallback
      try {
        final fallbackRes = await _supabase.from('puntos_camara').select('*');
        _puntos = (fallbackRes as List)
            .map((item) => PuntoCamara.fromMap(item))
            .toList();
      } catch (err) {
        _errorMessage = err.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPropuestas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.from('propuesta_puntos_camara').select('*');

      _propuestas = (res as List)
          .map((item) => PropuestaPuntoCamara.fromMap(item))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchPuntos(), fetchPropuestas()]);
  }

  void _bindRealtimeToAuth() {
    void syncSubscription(Session? session) {
      if (session != null) {
        _subscribeRealtime();
        _subscribeRealtimePropuestas();
      } else {
        _realtimeSubscription?.cancel();
        _realtimeSubscription = null;
        _realtimePropuestasSubscription?.cancel();
        _realtimePropuestasSubscription = null;
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

  void _subscribeRealtimePropuestas() {
    _realtimePropuestasSubscription?.cancel();
    _realtimePropuestasSubscription = _supabase
        .from('propuesta_puntos_camara')
        .stream(primaryKey: ['id'])
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) fetchPropuestas();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('PointsProvider: Realtime propuestas error: $error');
            _realtimePropuestasSubscription?.cancel();
            _realtimePropuestasSubscription = null;
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

  Future<bool> crearPuntoPropuesta({
    required String nombre,
    required double lat,
    required double lon,
    String? puntoCamaraReferenciaId,
    required Map<String, dynamic> datosAdicionales,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final insertData = {
        'nombre': nombre,
        'ubicacion': 'POINT($lon $lat)',
        'punto_camara_referencia_id':
            (puntoCamaraReferenciaId != null &&
                puntoCamaraReferenciaId.isNotEmpty)
            ? puntoCamaraReferenciaId
            : null,
        'actualizado_por': userId,
        'actualizado_en': DateTime.now().toIso8601String(),
        ...datosAdicionales,
      };

      await _supabase.from('propuesta_puntos_camara').insert(insertData);
      await fetchPropuestas();
      return true;
    } catch (e) {
      debugPrint('PointsProvider: Error creating proposal: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePunto(String puntoId, {bool isPropuesta = false}) async {
    try {
      if (isPropuesta) {
        await _supabase
            .from('propuesta_puntos_camara')
            .delete()
            .eq('id', puntoId);
        await fetchPropuestas();
      } else {
        await _supabase.from('puntos_camara').delete().eq('id', puntoId);
        await fetchPuntos();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUbicacion(
    String puntoId,
    double newLat,
    double newLon, {
    bool isPropuesta = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final data = {
        'ubicacion': 'POINT($newLon $newLat)',
        'actualizado_por': userId,
        'actualizado_en': DateTime.now().toIso8601String(),
      };

      if (isPropuesta) {
        await _supabase
            .from('propuesta_puntos_camara')
            .update(data)
            .eq('id', puntoId);
        await fetchPropuestas();
      } else {
        await _supabase.from('puntos_camara').update(data).eq('id', puntoId);
        await fetchPuntos();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePropuesta(
    String propuestaId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final data = {
        ...updates,
        'actualizado_por': userId,
        'actualizado_en': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('propuesta_puntos_camara')
          .update(data)
          .eq('id', propuestaId);
      await fetchPropuestas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
