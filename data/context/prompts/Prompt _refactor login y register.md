# Plan de Acción: Autenticación en VenHub (Email/Password + Google OAuth)

## Contexto Actual
- La app ya tiene autenticación con email/contraseña implementada en `AuthProvider` y las pantallas `LoginScreen` y `RegisterScreen`.
- Se necesita añadir autenticación con Google OAuth y la funcionalidad de "Olvidé contraseña" (recuperación de contraseña).
- Ya se ha creado el cliente OAuth en Google Cloud Console y se han obtenido las credenciales.

---

## 📋 Configuración de Google OAuth (Ya Realizada)

### En Google Cloud Console:
- **Cliente Android** (para autenticación nativa via Google Sign-In):
  - **Package name**: `com.ven911.ven911_app`
  - **SHA-1**: (obtenido con `keytool`)
  - **Client ID**: `611258875001-hb4ft1tcll956u1qvg3rt125136q5hfg9.apps.googleusercontent.com`
  - **Sin Client Secret** (no necesario para Android)

- **Cliente Web** (para flujo OAuth con Supabase):
  - **Authorized redirect URIs**: `https://<tu-proyecto>.supabase.co/auth/v1/callback`
  - **Client ID**: (obtenido al crear el cliente web)
  - **Client Secret**: (obtenido al crear el cliente web)

### En Supabase (Configuración del proveedor Google):
- **Client ID**: (el del cliente web)
- **Client Secret**: (el del cliente web)
- **Callback URL**: la proporcionada automáticamente
- **Skip nonce checks**: **desactivado**
- **Allow users without an email**: **desactivado**

---

## 🔧 Configuración de Deep Linking (YA REALIZADA)

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.ven911.ven911App" android:host="login-callback" />
</intent-filter>
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.ven911.ven911App</string>
        </array>
    </dict>
</array>
```

---

## 🚀 Plan de Acción

### Fase 1: Refactorizar `AuthProvider`

#### 1.1. Agregar método `loginWithGoogle()`
```dart
Future<bool> loginWithGoogle() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final redirectUrl = 'com.ven911.ven911App://login-callback';
    await _supabase.auth.signInWithOAuth(
      Provider.google,
      redirectTo: redirectUrl,
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

#### 1.2. Agregar método `resetPassword()`
```dart
Future<bool> resetPassword(String email) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final redirectUrl = 'com.ven911.ven911App://reset-callback';
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
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

#### 1.3. Agregar método `updatePassword()`
```dart
Future<bool> updatePassword(String newPassword) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
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

#### 1.4. Mejorar `loadProfile()` para usuarios de Google
```dart
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
      // Obtener nombre de los metadatos del usuario
      final nombre = _user!.userMetadata?['full_name'] ??
                      _user!.userMetadata?['name'] ??
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
```

#### 1.5. Manejar el deep link de recuperación
Agregar un método para procesar el deep link cuando el usuario regresa después de restablecer la contraseña:
```dart
Future<void> handleResetPasswordRedirect(String url) async {
  // Este método puede ser llamado desde el SplashScreen o desde un listener
  if (url.contains('reset-callback')) {
    // La sesión ya debería estar actualizada con el nuevo token
    // Solo notificar que está listo para cambiar la contraseña
    notifyListeners();
  }
}
```

---

### Fase 2: Crear Pantalla de Recuperación de Contraseña

#### [NEW] `lib/screens/auth/reset_password_screen.dart`
- Pantalla donde el usuario ingresa su email para recibir el enlace de recuperación.
- Botón "Enviar enlace de recuperación".
- Mostrar mensaje de éxito o error.

#### [NEW] `lib/screens/auth/update_password_screen.dart`
- Pantalla donde el usuario ingresa su nueva contraseña después de hacer clic en el enlace de recuperación.
- Dos campos: "Nueva contraseña" y "Confirmar contraseña".
- Botón "Actualizar contraseña".

#### [NEW] `lib/screens/auth/forgot_password_screen.dart`
- Enlace en `LoginScreen` que navega a `ResetPasswordScreen`.

---

### Fase 3: Actualizar UI de Login

#### 3.1. Agregar botón "Continuar con Google" en `LoginScreen`
```dart
OutlinedButton.icon(
  onPressed: auth.isLoading ? null : () async {
    final success = await auth.loginWithGoogle();
    if (success && mounted) {
      // El usuario será redirigido a Google y luego de vuelta
    }
  },
  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
  label: const Text('Continuar con Google'),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Color(0xFF2563EB)),
    padding: const EdgeInsets.symmetric(vertical: 14),
  ),
)
```

#### 3.2. Agregar enlace "¿Olvidaste tu contraseña?"
```dart
TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
  },
  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Color(0xFF94A3B8))),
)
```

---

### Fase 4: Manejar Deep Links en la App

#### 4.1. Configurar escucha de deep links en `main.dart`
```dart
import 'package:app_links/app_links.dart';

void main() async {
  // ... inicializaciones
  
  // Escuchar deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((Uri uri) {
    final authProvider = Provider.of<AuthProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    if (uri.toString().contains('reset-callback')) {
      // Navegar a la pantalla de actualización de contraseña
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (_) => const UpdatePasswordScreen(),
        ),
      );
    }
  });
}
```

#### 4.2. Agregar manejo en `SplashScreen`
```dart
Future<void> _checkAuth() async {
  // ... código existente

  // Verificar si el usuario viene de un enlace de recuperación
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null && session.user?.email == null) {
    // El usuario está autenticado pero sin email (caso de recuperación)
    // Redirigir a actualizar contraseña
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
    );
    return;
  }
  // ... resto del flujo
}
```

---

### Fase 5: Mejoras de UX

#### 5.1. Agregar indicador de carga en los botones de Google
```dart
if (auth.isLoading) {
  const CircularProgressIndicator(color: Colors.white);
} else {
  const Text('Continuar con Google');
}
```

#### 5.2. Agregar manejo de errores específicos
```dart
// En AuthProvider
if (errorMessage?.contains('email_not_confirmed') ?? false) {
  // Mostrar mensaje específico de verificación de email
}
if (errorMessage?.contains('invalid_grant') ?? false) {
  // Mostrar mensaje de credenciales inválidas
}
```

#### 5.3. Agregar verificación de email
- Supabase permite verificar email antes de permitir el acceso. Asegurar que el flujo esté configurado.

---

### Fase 6: Actualizar Dependencias

Agregar en `pubspec.yaml` (si no están ya):
```yaml
dependencies:
  app_links: ^6.0.0  # Para manejar deep links
  google_sign_in: ^6.1.5  # Opcional: para autenticación nativa con Google
```

---

## 📝 Prompt para el Agente IA en Cursor

> **Agente, tu tarea es implementar la autenticación completa en la app VenHub (Flutter), incluyendo email/contraseña, Google OAuth y recuperación de contraseña.**
>
> ### Contexto
> - **Backend**: Supabase con tabla `perfiles` que extiende `auth.users`.
> - **Google OAuth**: Ya configurado en Google Cloud Console y Supabase. El cliente Android tiene package name `com.ven911.ven911_app` y SHA-1 correspondiente. El cliente Web tiene los redirect URIs configurados. Supabase ya tiene el Client ID y Client Secret del cliente Web.
> - **Deep links**: Configurados con esquema `com.ven911.ven911App://` y hosts `login-callback` y `reset-callback`.
>
> ### Tareas
>
> 1. **Refactorizar `AuthProvider`**:
>    - Agregar `loginWithGoogle()` usando `signInWithOAuth`.
>    - Agregar `resetPassword(email)` usando `resetPasswordForEmail`.
>    - Agregar `updatePassword(newPassword)` usando `updateUser`.
>    - Mejorar `loadProfile()` para manejar usuarios de Google extrayendo nombre de `userMetadata`.
>    - Manejar deep links de recuperación de contraseña.
>
> 2. **Crear nuevas pantallas**:
>    - `ResetPasswordScreen`: pantalla para ingresar email y solicitar enlace de recuperación.
>    - `UpdatePasswordScreen`: pantalla para establecer nueva contraseña después del enlace de recuperación.
>
> 3. **Actualizar `LoginScreen`**:
>    - Agregar botón "Continuar con Google".
>    - Agregar enlace "¿Olvidaste tu contraseña?" que navega a `ResetPasswordScreen`.
>
> 4. **Agregar manejo de deep links**:
>    - Escuchar en `main.dart` con `app_links`.
>    - En `SplashScreen`, verificar si el usuario viene de un enlace de recuperación y redirigir a `UpdatePasswordScreen`.
>
> 5. **Mejoras de UX**:
>    - Mostrar mensajes de error específicos (email no confirmado, credenciales inválidas).
>    - Agregar indicadores de carga en los botones.
>
> ### Código de referencia
>
> El `AuthProvider` actual tiene:
> ```dart
> class AuthProvider extends ChangeNotifier {
>   User? _user;
>   Perfil? _profile;
>   bool _isLoading = false;
>   String? _errorMessage;
>   
>   Future<bool> login(String email, String password) async { ... }
>   Future<bool> register(String email, String password, String nombre) async { ... }
>   Future<void> logout() async { ... }
>   Future<void> loadProfile() async { ... }
> }
> ```
>
> ### Consideraciones de seguridad
>
> - No almacenar contraseñas en texto plano (Supabase las maneja con hash).
> - Usar `redirectTo` para que el usuario regrese a la app después del OAuth.
> - Validar entradas en los formularios (email válido, contraseña mínima 6 caracteres).
> - Manejar errores de red y mostrar mensajes amigables.
>
> ### Dependencias necesarias
>
> - `app_links`: para deep links.
> - `google_sign_in`: opcional si se usa autenticación nativa (si usas `signInWithOAuth` de Supabase, no es necesario).
>
> ### Pruebas
>
> 1. Verificar que login con email/contraseña funciona.
> 2. Verificar que login con Google redirige y autentica correctamente.
> 3. Verificar que "olvidé contraseña" envía el email de recuperación.
> 4. Verificar que el enlace de recuperación redirige a la app y permite cambiar la contraseña.
> 5. Verificar que el perfil se crea correctamente para usuarios nuevos (tanto email como Google).

---

## 🧪 Flujo de Prueba

1. **Registro con email**: Completar el formulario de registro, verificar que se crea el usuario en Supabase y el perfil en `perfiles`.
2. **Login con email**: Iniciar sesión con las credenciales registradas.
3. **Login con Google**: Hacer clic en "Continuar con Google", seleccionar cuenta, regresar a la app y verificar que el usuario está autenticado y el perfil fue creado.
4. **Olvidé contraseña**: Ingresar email, recibir el correo, hacer clic en el enlace, ser redirigido a la app y poder cambiar la contraseña.
5. **Cierre de sesión**: Cerrar sesión y verificar que se limpia el estado.

---

## 📦 Archivos a modificar/crear

### Modificar:
- `lib/providers/auth_provider.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/main.dart` (para deep links)

### Crear:
- `lib/screens/auth/reset_password_screen.dart`
- `lib/screens/auth/update_password_screen.dart`
- (Opcional) `lib/screens/auth/forgot_password_screen.dart` (si no se usa `ResetPasswordScreen`)

---
