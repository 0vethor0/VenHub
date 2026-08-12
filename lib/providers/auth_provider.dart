import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  Perfil? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Perfil? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      loadProfile();
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    if (_user == null) return;
    try {
      final res = await _supabase
          .from('perfiles')
          .select('*')
          .eq('id', _user!.id)
          .maybeSingle();

      if (res != null) {
        _profile = Perfil.fromMap(res);
      } else {
        // Create profile row if it doesn't exist
        await _supabase.from('perfiles').insert({
          'id': _user!.id,
          'email': _user!.email ?? '',
          'nombre': _user!.userMetadata?['nombre'] ?? _user!.email?.split('@').first ?? 'Usuario',
        });
        await loadProfile();
        return;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = res.user;
      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String nombre) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre},
      );
      _user = res.user;
      if (_user != null) {
        // El perfil se crea automáticamente mediante un Trigger SQL en Supabase (handle_new_user)
        // para evitar problemas de RLS (Row Level Security) cuando el usuario aún no está autenticado completamente.
        await loadProfile();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }
}

