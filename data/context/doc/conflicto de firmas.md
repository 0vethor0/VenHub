He identificado el problema principal: **conflicto de firmas entre la versión instalada (debug) y la versión de actualización (release)**. Cuando instalas una app desde el IDE (debug) y luego intentas actualizar con un APK firmado con keystore de producción, Android bloquea la instalación porque las firmas no coinciden.

---

## 🔍 Diagnóstico completo

| Posible causa | Síntoma | Solución |
|---------------|---------|----------|
| **Firma diferente** | Instalación falla al 99% con "Aplicación no instalada" | Desinstalar versión anterior o usar mismo keystore |
| **Versión de código igual o menor** | La instalación se rechaza porque la nueva versión no es mayor | Asegurar que `version_codigo` en Supabase sea mayor que el `buildNumber` actual |
| **APK dañado** | La descarga se completa pero el archivo no es un APK válido | Verificar integridad del archivo descargado (tamaño, checksum) |
| **Permisos de instalación** | El sistema no permite la instalación de fuentes desconocidas | Verificar `REQUEST_INSTALL_PACKAGES` en manifest |
| **Ruta de archivo incorrecta** | FileProvider no puede compartir el archivo | Usar `getApplicationDocumentsDirectory()` y configurar `file_paths.xml` |

---

## 🛠️ Plan de Acción para el Agente

### Fase 1: Refactorizar método de descarga e instalación

#### 1.1. Cambiar directorio de descarga
```dart
// Antes: getExternalStorageDirectory()
final directory = await getApplicationDocumentsDirectory();
```

#### 1.2. Actualizar `file_paths.xml`
```xml
<paths>
    <external-files-path name="apk" path="." />
    <files-path name="apk" path="." />  <!-- Agregar esta línea -->
    <cache-path name="cache" path="." />
</paths>
```

#### 1.3. Agregar verificación de integridad del APK
Después de descargar, verificar que el archivo no esté vacío:
```dart
if (response.bodyBytes.isEmpty || response.contentLength == 0) {
  throw Exception('El archivo descargado está vacío');
}
```

#### 1.4. Agregar logs detallados
```dart
debugPrint('VersionUpdate: APK guardado en: ${apkFile.path}');
debugPrint('VersionUpdate: Tamaño del APK: ${apkFile.lengthSync()} bytes');
debugPrint('VersionUpdate: URI generado: $uri');
```

---

### Fase 2: Manejar conflictos de firma

#### 2.1. Detectar si la app instalada es debug o release
```dart
bool _isDebugBuild() {
  // Verificar si el keystore de debug está presente
  // O usar PackageInfo para verificar el buildNumber
}
```

#### 2.2. Mostrar mensaje de error específico para firmas
```dart
if (errorMessage?.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE') ?? false) {
  _errorMessage = 'La versión instalada no es compatible. Desinstala la app actual primero.';
}
```

#### 2.3. Sugerir desinstalación manual
Mostrar un diálogo que indique al usuario que debe desinstalar la versión anterior antes de instalar.

---

### Fase 3: Ajustes en el workflow CI/CD

#### 3.1. Asegurar que el `version_codigo` sea incremental
En `release.yml`, el cálculo del código de versión ya está correcto:
```bash
CODIGO=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))
```

#### 3.2. Publicar el APK de release también como `app-release.apk` (sin renombrar) para facilitar pruebas manuales


---

### Fase 5: Mejoras de UX

#### 5.1. Diálogo de actualización mejorado
- Mostrar el tamaño de la descarga.
- Mostrar el progreso con porcentaje.
- Si el error es de firma, guiar al usuario para desinstalar la versión actual.

#### 5.2. Registro de errores
- Enviar logs de errores de instalación a un servicio de monitoreo (opcional).

---

## 📝 Prompt para el Agente IA

> **Agente, necesito resolver el problema de instalación de la actualización de la app. La instalación falla al 99% con el mensaje "Aplicación no instalada" debido a conflictos de firma y/o permisos de archivos.**
>
> ### Contexto actual
> - La app usa `version_update_provider.dart` para descargar e instalar APKs desde GitHub Releases.
> - El APK se descarga en `getExternalStorageDirectory()` y se instala con `android_intent_plus`.
> - El FileProvider está configurado en `AndroidManifest.xml` y `file_paths.xml`.
> - El workflow de release (`release.yml`) firma el APK con un keystore de producción.
> - **Problema**: La versión instalada en el dispositivo es de debug (firmada con debug keystore), mientras que la actualización es release (firmada con keystore de producción). Android impide la instalación porque las firmas no coinciden.
>
> ### Tareas
>
> 1. **Refactorizar `downloadAndInstallUpdate` en `version_update_provider.dart`**:
>    - Cambiar `getExternalStorageDirectory()` por `getApplicationDocumentsDirectory()`.
>    - Agregar verificación de integridad del APK (tamaño, contenido no vacío).
>    - Agregar logs detallados para depuración.
>
> 2. **Actualizar `file_paths.xml`**:
>    - Agregar `<files-path name="apk" path="." />`.
>
> 3. **Agregar manejo de errores específicos**:
>    - Detectar `INSTALL_FAILED_UPDATE_INCOMPATIBLE` y mostrar mensaje: "La versión instalada no es compatible. Desinstala la app actual primero."
>    - Agregar un botón en el diálogo de error que lleve a la configuración de la app para desinstalar (opcional).
>
> 4. **Mejorar el diálogo de actualización**:
>    - Mostrar el tamaño del APK (si se puede obtener).
>    - Mostrar el porcentaje de descarga con una barra de progreso.
>    - Al finalizar la descarga, mostrar un mensaje de "Instalación iniciada" antes de lanzar el intent.
>
> 5. **Agregar una flag en el código para saber si la app está en debug o release**:
>    - Usar `kReleaseMode` de `foundation.dart` para mostrar mensajes de depuración.
>
> ### Código de referencia
>
> `downloadAndInstallUpdate` actual:
> ```dart
> Future<void> downloadAndInstallUpdate() async {
>   if (_downloadUrl.isEmpty) return;
>   _isDownloading = true;
>   _downloadProgress = 0.0;
>   notifyListeners();
>   try {
>     final response = await http.get(Uri.parse(_downloadUrl));
>     final directory = await getExternalStorageDirectory();
>     final apkFile = File('${directory.path}/venhub_update.apk');
>     await apkFile.writeAsBytes(response.bodyBytes);
>     _downloadProgress = 1.0;
>     notifyListeners();
>     if (Platform.isAndroid) {
>       final uri = await _installChannel.invokeMethod<String>('getApkUri', {
>         'path': apkFile.path,
>       });
>       final intent = AndroidIntent(
>         action: 'action_view',
>         data: uri,
>         type: 'application/vnd.android.package-archive',
>         flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_GRANT_READ_URI_PERMISSION],
>       );
>       await intent.launch();
>     } else {
>       await OpenFile.open(apkFile.path);
>     }
>   } catch (e) {
>     _errorMessage = 'Error: ${e.toString()}';
>   } finally {
>     _isDownloading = false;
>     notifyListeners();
>   }
> }
> ```
>
> ### Dependencias
> - `android_intent_plus`
> - `permission_handler`
> - `path_provider`
> - `http`
> - `open_file`
>
> ### Pruebas de verificación
> 1. Instalar la versión release actual (firmada con producción) manualmente.
> 2. Simular una nueva versión (subir un release con código mayor).
> 3. Verificar que la descarga se complete y la instalación sea exitosa.
> 4. Verificar que los logs muestren la ruta del APK y el tamaño.
> 5. Probar con una versión de debug instalada (para confirmar el mensaje de error de firma).

---

## 📦 Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/providers/version_update_provider.dart` | Refactorizar `downloadAndInstallUpdate` |
| `android/app/src/main/res/xml/file_paths.xml` | Agregar `files-path` |
| `lib/screens/update_dialog.dart` | Mejorar UI con tamaño y porcentaje |
| `android/app/src/main/AndroidManifest.xml` | (Opcional) Verificar permisos |

---

## ✅ Checklist de verificación

- [ ] `getApplicationDocumentsDirectory()` usado en lugar de `getExternalStorageDirectory()`.
- [ ] `file_paths.xml` tiene `<files-path name="apk" path="." />`.
- [ ] Se agregaron logs para depurar la ruta y tamaño del APK.
- [ ] Se maneja el error `INSTALL_FAILED_UPDATE_INCOMPATIBLE` con mensaje específico.
- [ ] El diálogo de actualización muestra el porcentaje de descarga.
- [ ] Se probó el flujo con una versión release instalada previamente.
- [ ] Se probó el flujo con una versión debug instalada (debe mostrar error de firma).

---

