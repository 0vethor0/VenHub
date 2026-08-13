import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  static const _loginRedirectUrl = 'com.ven911.ven911App://login-callback';
  static const _resetRedirectUrl = 'com.ven911.ven911App://reset-callback';

  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  Perfil? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _pendingPasswordUpdate = false;

  User? get user => _user;
  Perfil? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get pendingPasswordUpdate => _pendingPasswordUpdate;
  String? get errorMessage => _errorMessage;

  String? get friendlyErrorMessage {
    final msg = _errorMessage;
    if (msg == null) return null;
    if (msg.contains('email_not_confirmed')) {
      return 'Por favor verifica tu correo electrónico antes de iniciar sesión.';
    }
    if (msg.contains('invalid_grant') ||
        msg.contains('Invalid login credentials')) {
      return 'Credenciales inválidas. Verifica tu correo y contraseña.';
    }
    return msg;
  }

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
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _pendingPasswordUpdate = true;
      } else if (data.event == AuthChangeEvent.signedIn &&
          data.session != null) {
        _pendingPasswordUpdate = false;
      }
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
        final nombre =
            _user!.userMetadata?['full_name'] ??
            _user!.userMetadata?['name'] ??
            _user!.userMetadata?['nombre'] ??
            _user!.email?.split('@').first ??
            'Usuario';
        await _supabase.from('perfiles').insert({
          'id': _user!.id,
          'email': _user!.email ?? '',
          'nombre': nombre,
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _loginRedirectUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _resetRedirectUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _pendingPasswordUpdate = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleResetPasswordRedirect(String url) async {
    if (url.contains('reset-callback')) {
      _pendingPasswordUpdate = true;
      notifyListeners();
    }
  }

  void clearPendingPasswordUpdate() {
    _pendingPasswordUpdate = false;
    notifyListeners();
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
    _pendingPasswordUpdate = false;
    notifyListeners();
  }
}
