import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reporte.dart';

class ReportsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Reporte> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Reporte> get reportes => _reportes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReportesPorPunto(String puntoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('reportes')
          .select('*, perfiles(nombre)')
          .eq('punto_id', puntoId)
          .order('creado_en', ascending: false);

      _reportes = (res as List).map((e) => Reporte.fromMap(e)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearReporte({
    required String puntoId,
    required String observacion,
    File? fotoFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      String? photoUrl;
      if (fotoFile != null) {
        final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'evidencias/$fileName';
        await _supabase.storage.from('reportes_media').upload(path, fotoFile);
        photoUrl = _supabase.storage.from('reportes_media').getPublicUrl(path);
      }

      await _supabase.from('reportes').insert({
        'punto_id': puntoId,
        'autor_id': user.id,
        'observacion': observacion,
        'url_evidencia_foto': photoUrl,
      });

      await fetchReportesPorPunto(puntoId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

