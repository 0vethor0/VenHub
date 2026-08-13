
---

## 🛠️ Solución propuesta

**Cambiar el directorio de descarga a `getApplicationSupportDirectory()` (o `getFilesDir()`)**.  
En Android, `getApplicationSupportDirectory()` retorna el mismo directorio que `getFilesDir()` (`/data/data/.../files/`), y ese **sí está cubierto por `<files-path>`**. Así evitamos tener que modificar `file_paths.xml` y el código queda más limpio.

### Cambios en `version_update_provider.dart`

Reemplaza la línea donde obtienes el directorio:

```dart
// Antes
final directory = await getApplicationDocumentsDirectory();

// Después
final directory = await getApplicationSupportDirectory();
```

También puedes usar `getFilesDir()` directamente, pero `getApplicationSupportDirectory()` es la opción recomendada para archivos de soporte de la app.

### ¿Por qué funciona?

- `getApplicationSupportDirectory()` → `/data/data/com.ven911.ven911_app/files/`  
- Tu `file_paths.xml` ya tiene `<files-path name="apk" path="." />`, que cubre exactamente esa raíz.

---

## 🔧 Código completo actualizado de `downloadAndInstallUpdate`

Asegúrate de que el método quede así (con las mejoras ya implementadas en tu plan anterior):

```dart
Future<void> downloadAndInstallUpdate() async {
  if (_downloadUrl.isEmpty) {
    _errorMessage = 'URL de descarga vacía.';
    notifyListeners();
    return;
  }

  _isDownloading = true;
  _downloadProgress = 0.0;
  _errorMessage = null;
  _isSignatureConflict = false;
  notifyListeners();

  try {
    if (Platform.isAndroid) {
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        _errorMessage = 'Permiso de instalación denegado';
        return;
      }
    }

    await _fetchApkSize();

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Error descargando el archivo (${response.statusCode})');
      }

      final contentLength = response.contentLength ?? _apkSizeBytes ?? 0;
      final directory = await getApplicationSupportDirectory(); // <--- CAMBIO AQUÍ
      final apkFile = File('${directory.path}/venhub_update.apk');
      final sink = apkFile.openWrite();
      var received = 0;

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          _downloadProgress = received / contentLength;
          notifyListeners();
        }
      }
      await sink.close();

      if (!await apkFile.exists() || apkFile.lengthSync() == 0) {
        throw Exception('El archivo descargado está vacío');
      }

      _downloadProgress = 1.0;
      notifyListeners();

      debugPrint('VersionUpdate: APK guardado en: ${apkFile.path}');
      debugPrint('VersionUpdate: Tamaño del APK: ${apkFile.lengthSync()} bytes');

      if (Platform.isAndroid) {
        final uri = await _installChannel.invokeMethod<String>('getApkUri', {
          'path': apkFile.path,
        });
        if (uri == null || uri.isEmpty) {
          throw Exception('No se pudo preparar el APK para instalación');
        }

        final intent = AndroidIntent(
          action: 'action_view',
          data: uri,
          type: 'application/vnd.android.package-archive',
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_GRANT_READ_URI_PERMISSION,
          ],
        );
        await intent.launch();

        _showInstallationStarted();
        Future.delayed(const Duration(seconds: 1), SystemNavigator.pop);
      } else {
        await OpenFile.open(apkFile.path);
      }
    } finally {
      client.close();
    }
  } catch (e) {
    _setDownloadError(e);
    debugPrint('VersionUpdate: Error en actualización: $e');
  } finally {
    _isDownloading = false;
    notifyListeners();
  }
}
```

---

## 📁 Verifica `file_paths.xml`

Ya tienes la configuración correcta, pero asegúrate de que esté así:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-files-path name="apk" path="." />
    <files-path name="apk" path="." />
    <cache-path name="cache" path="." />
</paths>
```

Con el cambio a `getApplicationSupportDirectory()`, usamos `<files-path>`.

---

## 🧪 Prueba local sin subir a GitHub

Para depurar sin esperar un release, puedes:

1. **Forzar una URL local** en `version_update_provider.dart` durante el desarrollo (por ejemplo, apuntando a un APK en un servidor local o en el almacenamiento del dispositivo).
2. **Simular una nueva versión** insertando manualmente un registro en Supabase con un `version_codigo` mayor que el actual.
3. **Usar `adb`** para instalar el APK manualmente y verificar que la firma coincida.

---

## 🔁 Resumen de cambios

| Archivo | Cambio |
|---------|--------|
| `lib/providers/version_update_provider.dart` | Cambiar `getApplicationDocumentsDirectory()` por `getApplicationSupportDirectory()` |
| `android/app/src/main/res/xml/file_paths.xml` | Ya está bien (no requiere cambios) |
| `android/app/src/main/AndroidManifest.xml` | Verificar que el provider tenga `android:authorities="${applicationId}.fileprovider"` (ya está) |

---
