import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../main.dart' show navigatorKey;
import '../screens/update_dialog.dart';

class VersionUpdateProvider with ChangeNotifier {
  static const _installChannel = MethodChannel('com.ven911.ven911_app/install');

  bool _updateAvailable = false;
  String _latestVersion = '';
  String _downloadUrl = '';
  bool _isRequired = false;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _isDialogShowing = false;

  RealtimeChannel? _realtimeChannel;
  int _currentVersionCode = 0;
  String _currentVersionName = '';
  final bool enableRealtime;

  // Getters
  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;
  String get downloadUrl => _downloadUrl;
  bool get isRequired => _isRequired;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isDialogShowing => _isDialogShowing;
  String get currentVersionName => _currentVersionName;

  VersionUpdateProvider({this.enableRealtime = true});

  set isDialogShowing(bool val) {
    _isDialogShowing = val;
    notifyListeners();
  }

  /// Initialize the provider
  Future<void> init() async {
    await _getCurrentVersion();
    await checkForUpdates();
    if (enableRealtime) {
      _subscribeToRealtime();
    }
  }

  /// Fetch local app version information
  Future<void> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersionName = packageInfo.version;

      final buildNum = int.tryParse(packageInfo.buildNumber) ?? 0;
      final parsedCode = _parseVersionNameToCode(packageInfo.version);

      // Use the maximum of the two to be robust
      _currentVersionCode = buildNum > parsedCode ? buildNum : parsedCode;

      debugPrint(
        'VersionUpdateProvider: Local App Version Name: $_currentVersionName, Code: $_currentVersionCode',
      );
    } catch (e) {
      debugPrint('VersionUpdateProvider: Error getting local version: $e');
    }
  }

  /// Parse semver string to numeric version code (e.g. 1.2.3 -> 10203)
  int _parseVersionNameToCode(String version) {
    try {
      final cleanVersion = version.startsWith('v')
          ? version.substring(1)
          : version;
      final parts = cleanVersion.split('+')[0].split('.');
      if (parts.isEmpty) return 0;

      final major = int.tryParse(parts[0]) ?? 0;
      final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

      return major * 10000 + minor * 100 + patch;
    } catch (e) {
      return 0;
    }
  }

  /// Check for updates manually from Supabase
  Future<void> checkForUpdates() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('versiones_app')
          .select()
          .order('version_codigo', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _processNewVersion(response);
      }
    } catch (e) {
      debugPrint('VersionUpdateProvider: Error checking for updates: $e');
    }
  }

  /// Process the record and check if it is newer
  void _processNewVersion(Map<String, dynamic> record) {
    final dbVersionCodigo = record['version_codigo'] as int? ?? 0;
    final dbVersionNombre = record['version_nombre'] as String? ?? '';
    final dbUrlDescarga = record['url_descarga'] as String? ?? '';
    final dbObligatoria = record['obligatoria'] as bool? ?? true;

    debugPrint(
      'VersionUpdateProvider: DB Version Code: $dbVersionCodigo, Local: $_currentVersionCode',
    );

    if (dbVersionCodigo > _currentVersionCode) {
      _updateAvailable = true;
      _latestVersion = dbVersionNombre;
      _downloadUrl = dbUrlDescarga;
      _isRequired = dbObligatoria;
      notifyListeners();

      // Show dialog if we are not on the startup screen (will check navigator context)
      _showUpdateDialogIfNeeded();
    } else {
      _updateAvailable = false;
      notifyListeners();
    }
  }

  /// Subscribe to changes using Realtime
  void _subscribeToRealtime() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel('public:versiones_app')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'versiones_app',
            callback: (payload) {
              debugPrint(
                'VersionUpdateProvider: Realtime INSERT event received: ${payload.newRecord}',
              );
              final newRecord = payload.newRecord;
              _processNewVersion(newRecord);
            },
          );
      _realtimeChannel!.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint(
            'VersionUpdateProvider: Realtime channel error: $error',
          );
        }
      });
    } catch (e) {
      debugPrint('VersionUpdateProvider: Error subscribing to Realtime: $e');
    }
  }

  /// Download and trigger the installation of the APK
  Future<void> downloadAndInstallUpdate() async {
    if (_downloadUrl.isEmpty) {
      _errorMessage = 'URL de descarga vacía.';
      notifyListeners();
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        final installStatus = await Permission.requestInstallPackages.request();
        if (!installStatus.isGranted) {
          _errorMessage = 'Permiso de instalación denegado';
          return;
        }

        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          _errorMessage = 'Permiso de almacenamiento denegado';
          return;
        }
      }

      final response = await http.get(Uri.parse(_downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Error descargando el archivo');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('No se puede acceder al almacenamiento externo');
      }
      final apkFile = File('${directory.path}/venhub_update.apk');
      await apkFile.writeAsBytes(response.bodyBytes);

      _downloadProgress = 1.0;
      notifyListeners();

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
      msg:
          'Instalación iniciada. Complete el proceso en la pantalla del sistema.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Helper to trigger dialog via global navigatorKey
  void _showUpdateDialogIfNeeded() {
    // This is used for runtime updates via Realtime.
    // If the dialog is already showing, we don't open another one.
    if (_isDialogShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showUpdateDialog();
    });
  }

  /// Trigger the update dialog manually
  void showUpdateDialog() {
    if (_isDialogShowing) return;

    final context = navigatorKey.currentContext;
    if (context != null) {
      _isDialogShowing = true;
      notifyListeners();

      showDialog(
        context: context,
        barrierDismissible: !_isRequired,
        builder: (context) => const UpdateDialog(),
      ).then((_) {
        _isDialogShowing = false;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }
}
