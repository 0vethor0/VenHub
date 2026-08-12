El problema es que **la interfaz de sistema (permisos y autenticación) interrumpe el flujo de tu aplicación**, y como estás usando `OpenFile.open` (que lanza el instalador y espera un resultado) desde la UI activa, al pausarse la app el proceso se cuelga.

La solución es **separar la descarga de la instalación** y **no esperar el resultado de la instalación desde la UI**. En su lugar, debes:

1. **Descargar el APK por completo** antes de lanzar el instalador.
2. **Lanzar el instalador como un intent independiente** y luego **cerrar tu app** (o al menos finalizar la actividad actual) para que el sistema maneje el resto sin interferencias.
3. Opcionalmente, registrar un `BroadcastReceiver` para saber cuándo la instalación se ha completado y notificar al usuario.

---

## 🔧 Código actualizado para `VersionUpdateProvider`

### 1. Cambios en el método `downloadAndInstallUpdate`

```dart
/// Descarga el APK y lanza la instalación con android_intent_plus
Future<void> downloadAndInstallUpdate() async {
  if (_downloadUrl.isEmpty) return;
  
  _isDownloading = true;
  _downloadProgress = 'Descargando actualización...';
  notifyListeners();

  try {
    // Solicitar permisos de almacenamiento (solo Android 10-)
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _errorMessage = 'Permiso de almacenamiento denegado';
        _isDownloading = false;
        notifyListeners();
        return;
      }
    }

    // Descargar el APK
    final response = await http.get(Uri.parse(_downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Error descargando el archivo');
    }

    // Guardar en un directorio accesible (ej. Descargas)
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('No se puede acceder al almacenamiento externo');
    }
    final apkFile = File('${directory.path}/venhub_update.apk');
    await apkFile.writeAsBytes(response.bodyBytes);

    _downloadProgress = 'Descarga completada. Preparando instalación...';
    notifyListeners();

    // Instalar usando android_intent_plus
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: apkFile.path,
        type: 'application/vnd.android.package-archive',
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION,
        ],
      );
      // Lanzar el intent sin esperar resultado
      await intent.launch();

      // Mostrar mensaje y cerrar la app (opcional)
      _showInstallationStarted();
      // Finalizar la app después de un breve delay
      Future.delayed(const Duration(seconds: 1), () {
        // Cerrar la app
        SystemNavigator.pop();
      });
    } else {
      // Fallback para iOS (no aplica)
      await OpenFile.open(apkFile.path);
    }
  } catch (e) {
    _errorMessage = 'Error: ${e.toString()}';
    debugPrint('Error en actualización: $e');
  } finally {
    _isDownloading = false;
    notifyListeners();
  }
}

void _showInstallationStarted() {
  // Mostrar un toast indicando que la instalación comenzó
  Fluttertoast.showToast(
    msg: 'Instalación iniciada. Complete el proceso en la pantalla del sistema.',
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
  );
}
```

### 2. Cambios en la UI (diálogo)

En el `UpdateDialog`, al hacer clic en "Descargar e instalar", se llama al método y luego se puede cerrar la app:

```dart
onPressed: () async {
  await provider.downloadAndInstallUpdate();
  // Si la instalación se lanzó, cerrar la app
  if (Platform.isAndroid) {
    // Opcional: esperar un segundo para que el intent se lance
    await Future.delayed(const Duration(seconds: 1));
    SystemNavigator.pop();  // Cierra la app
  }
}
```

---

## 📦 Dependencias adicionales

Añade a tu `pubspec.yaml`:

```yaml
dependencies:
  android_intent_plus: ^5.0.0
  permission_handler: ^11.0.0
  path_provider: ^2.0.0
  http: ^1.0.0
  fluttertoast: ^8.2.0
  open_file: ^3.3.0  # solo para iOS/fallback
```

Y no olvides actualizar el `AndroidManifest.xml` para incluir el permiso de instalación (si es necesario):

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

---

## ✅ Resumen de la solución

| Problema | Solución |
|----------|----------|
| La UI se pausa al mostrar la pantalla de permisos/autenticación | Separar descarga de instalación; lanzar instalación como intent independiente |
| La barra de progreso se queda en 99% | La descarga está completa, pero el intent de instalación no se lanza correctamente. Al usar `android_intent_plus` y cerrar la app, el sistema maneja el resto. |
| El proceso se cuelga al pedir autenticación | Al lanzar el intent con `FLAG_ACTIVITY_NEW_TASK`, la instalación corre en su propia tarea, sin depender de la actividad de la app. |

Con estos cambios, la app descarga el APK, lanza el instalador del sistema y se cierra, dejando que Android maneje la instalación sin interferencias. El usuario solo tendrá que autenticarse en la pantalla del sistema y la instalación continuará sin problemas.

---

