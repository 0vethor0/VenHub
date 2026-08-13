Excelente, has dado con el punto clave. Los logs que compartes son oro puro:

```
I/flutter (25345): VersionUpdate: APK guardado en: /data/user/0/com.ven911.ven911_app/files/venhub_update.apk
I/flutter (25345): VersionUpdate: Tamaño del APK: 56334294 bytes
I/flutter (25345): VersionUpdate: URI generado: content://com.ven911.ven911_app.fileprovider/apk/venhub_update.apk
V/IntentSender(25345): Sending intent Intent { act=android.intent.action.VIEW dat=content://... typ=application/vnd.android.package-archive flg=0x10000001 (has extras) }
...
Lost connection to device.
```

**La descarga es exitosa, la URI es válida y el intent se lanza correctamente.**  
El problema real es que **inmediatamente después de lanzar el intent, la app se cierra** (por el `SystemNavigator.pop` que programaste con 1 segundo de retraso). Esto provoca que:

1. **No puedas ver el resultado de la instalación** (si falla por firma, el sistema muestra un diálogo, pero la app ya no está activa).
2. **El mensaje de error de firma que tienes en el diálogo nunca se muestra** porque ese error no se lanza en el código de Flutter, sino que es un fallo a nivel del sistema operativo al intentar instalar el APK.

---

## 🔍 Análisis detallado de los logs

| Línea | Interpretación |
|-------|----------------|
| `VersionUpdate: build debug detectado — actualización release puede fallar por firma distinta` | Tu código detecta correctamente que estás en debug y que la firma puede ser un problema. |
| `VersionUpdate: APK guardado en: .../files/venhub_update.apk` | La ruta ahora está dentro de `files/`, que **sí está cubierta por `<files-path>`** en `file_paths.xml`. Por eso la URI se genera sin error. |
| `URI generado: content://.../apk/venhub_update.apk` | FileProvider funciona perfectamente. |
| `Sending intent ...` | El intent se envía al sistema para instalar. |
| `Lost connection to device.` | La app se cierra (el `SystemNavigator.pop` se ejecutó) y el dispositivo se desconecta del debugger. |

**Conclusión:** El flujo de descarga y generación de URI ya está arreglado. El fallo visible ahora es **la salida temprana de la app**, que impide que el usuario vea el resultado de la instalación (y que tú puedas depurar el posible error de firma).

---

## 🛠️ Solución propuesta

### 1. Eliminar `SystemNavigator.pop` del método de instalación

En lugar de cerrar la app, **deja que la app siga ejecutándose** después de lanzar el intent. El usuario podrá ver el diálogo del sistema, y si la instalación falla, la app permanecerá abierta y podrá mostrar un mensaje de error (por ejemplo, al reanudar la app o al volver a ella).

**Cambio en `version_update_provider.dart`:**

```dart
// Dentro de downloadAndInstallUpdate, después de intent.launch():
await intent.launch();

_showInstallationStarted();
// ❌ Elimina esta línea:
// Future.delayed(const Duration(seconds: 1), SystemNavigator.pop);

// ✅ En su lugar, simplemente notifica que la instalación se inició.
// La app se mantiene en primer plano; el usuario verá el diálogo del sistema.
```

Si quieres, puedes añadir un `Navigator.pop(context)` para cerrar el diálogo de actualización, pero no cierres toda la app.

### 2. Mejorar la experiencia de usuario

- Después de lanzar el intent, muestra un **SnackBar** o **Toast** indicando que la instalación está en curso y que, si falla, debe desinstalar la versión anterior.
- La app quedará en segundo plano (o en primer plano) mientras el sistema maneja la instalación. Cuando el usuario regrese, la app seguirá funcionando y podrá verificar nuevamente la versión (si no se actualizó, volverá a mostrar el diálogo).

### 3. Manejar el error de firma sin cerrar la app

Dado que la app no recibe el resultado de la instalación, no puedes capturar `INSTALL_FAILED_UPDATE_INCOMPATIBLE` directamente. Sin embargo, puedes:

- En el próximo inicio de la app, al verificar la versión, si la versión remota sigue siendo mayor, mostrar el diálogo nuevamente y, en ese diálogo, **si el usuario está en debug, mostrar un mensaje fijo**:
  > "Estás usando una versión de desarrollo. Para instalar la actualización, desinstala la versión actual desde Ajustes y luego instala la versión release."

Eso ya lo tienes en `update_dialog.dart` con la línea:
```dart
if (provider.isDebugBuild) { ... }
```

Pero como la app se cerraba, ese mensaje solo se veía antes de la descarga. Ahora, si la instalación falla, la app no se cerrará y podrás mostrar un mensaje adicional (por ejemplo, en el mismo diálogo) indicando que la instalación falló y ofreciendo el botón de "Abrir configuración".

---

## 📦 Código final recomendado para `downloadAndInstallUpdate`

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
      final directory = await getApplicationSupportDirectory(); // ✅ Ya está bien
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

        // ✅ Mostrar toast y NO cerrar la app
        _showInstallationStarted();
        
        // Opcional: cerrar el diálogo de actualización si está abierto
        // (pero no toda la app)
        // if (_isDialogShowing) Navigator.of(context).pop();

        // ✅ La app sigue viva; el usuario verá el diálogo del sistema.
        // Si la instalación falla, la app seguirá aquí y podrá mostrar
        // un mensaje de error en el próximo ciclo.
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


