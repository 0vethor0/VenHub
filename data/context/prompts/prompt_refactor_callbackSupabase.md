## Plan de Acción: Integración de Google OAuth en Flutter con Supabase

### Objetivo
Completar la integración del flujo de autenticación con Google OAuth en la aplicación VenHub, asegurando que al regresar del navegador la aplicación capture el deep link, restaure la sesión en Supabase y redirija automáticamente al usuario al HomeScreen.

**Premisas** (ya están hechas y no se modifican):
- `AndroidManifest.xml` ya contiene el `intent-filter` para `com.ven911.ven911App://login-callback`.
- Google Cloud Console ya tiene la URL de redirección de Supabase (`https://<project>.supabase.co/auth/v1/callback`).
- Supabase (URL Configuration) ya tiene agregado `com.ven911.ven911App://login-callback` en Redirect URLs.
- La dependencia `app_links` ya está instalada y el listener está activo (solo se extiende).

---

### Archivos a Modificar

#### 1. `lib/providers/auth_provider.dart`
**Acción:** Verificar que `loginWithGoogle()` incluya el `redirectTo` correcto.

**Código actualizado (si no lo tiene):**

```dart
Future<bool> loginWithGoogle() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.ven911.ven911App://login-callback', // ← igual que en Supabase
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
```

> **Nota:** Si ya lo tiene, no es necesario modificarlo. Solo verificar que la cadena coincida exactamente con la configurada en Supabase.

---

#### 2. `lib/main.dart`
**Acción:** Extender el listener de `app_links` para manejar `login-callback` y llamar a `recoverSession`.

**Paso 2.1:** Modificar el método `_handleDeepLink` para que distinga entre `reset-callback` y `login-callback`.

**Código final (sustituir el método existente):**

```dart
void _handleDeepLink(Uri uri) async {
  final url = uri.toString();
  
  // Caso 1: Recuperación de contraseña (ya existente)
  if (url.contains('reset-callback')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.handleResetPasswordRedirect(url);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
      );
    });
    return;
  }

  // Caso 2: Login con Google (nuevo)
  if (url.contains('login-callback')) {
    try {
      // recoverSession extrae los tokens de la URL y los guarda en Supabase
      final session = await Supabase.instance.client.auth.recoverSession(uri);
      if (session != null) {
        debugPrint('✅ Sesión de Google restaurada: ${session.user?.email}');
        // No es necesario navegar aquí; AuthProvider reaccionará al evento SIGNED_IN
      }
    } catch (e) {
      debugPrint('❌ Error al restaurar sesión de Google: $e');
    }
  }
}
```

**Paso 2.2:** Asegurar que el listener esté suscrito correctamente (ya está en `initState`):

```dart
_linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
```

---

### Verificación del Funcionamiento

- El `AuthProvider` ya tiene un listener de `onAuthStateChange` que actualiza `_user` cuando la sesión cambia.  
- Cuando `recoverSession` restaura la sesión, se dispara el evento `SIGNED_IN` y el `AuthProvider` notifica a los listeners.  
- `LoginScreen` (y cualquier otra pantalla que escuche) redirigirá automáticamente al `HomeScreen`.

**Si `recoverSession` no está disponible** (versión antigua de `supabase_flutter`), usar:

```dart
final session = await Supabase.instance.client.auth.getSessionFromUrl(uri);
```

Pero se recomienda actualizar a la última versión (v2+) y usar `recoverSession`.

---

### Prueba Final

1. Desinstalar la app (para limpiar sesiones antiguas).
2. Ejecutar `flutter run`.
3. Tocar "Continuar con Google".
4. Seleccionar una cuenta.
5. Verificar que la app se abre nuevamente y el usuario queda autenticado en el `HomeScreen`.

---

### Resumen de Cambios

| Archivo | Cambio |
|---------|--------|
| `lib/providers/auth_provider.dart` | Verificar `redirectTo` en `loginWithGoogle()` |
| `lib/main.dart` | Extender `_handleDeepLink` para manejar `login-callback` y llamar a `recoverSession` |

---

