import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show navigatorKey;
import '../screens/update_dialog.dart';

class VersionUpdateProvider with ChangeNotifier {
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
      _realtimeChannel!.subscribe();
    } catch (e) {
      debugPrint('VersionUpdateProvider: Error subscribing to Realtime: $e');
    }
  }

  /// Request storage permission (only for Android <= 12, as >= 13 handles it differently)
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return false;

    // Request permission using permission_handler
    final status = await Permission.storage.status;
    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return status.isGranted || status.isLimited;
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
      // Storage permission check (we can still try if denied, since cache folder works)
      await _requestStoragePermission();

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'El servidor respondió con código ${response.statusCode}',
        );
      }

      final totalLength = response.contentLength ?? 0;
      int receivedLength = 0;

      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/app-update.apk';
      final file = File(apkPath);

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();

      final stream = response.stream;
      await for (final chunk in stream) {
        sink.add(chunk);
        receivedLength += chunk.length;
        if (totalLength > 0) {
          _downloadProgress = receivedLength / totalLength;
          notifyListeners();
        }
      }

      await sink.close();
      client.close();

      _isDownloading = false;
      _downloadProgress = 1.0;
      notifyListeners();

      // Trigger APK installation
      await _installApk(apkPath);
    } catch (e) {
      _isDownloading = false;
      _errorMessage = 'Error en descarga/instalación: ${e.toString()}';
      notifyListeners();
      debugPrint('VersionUpdateProvider: Download/Install error: $e');
    }
  }

  /// Open APK with OpenFile package
  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      // Handle the result dynamically to be compatible with varying enum capitalizations
      final resultType = result.type.toString().toLowerCase();
      if (!resultType.contains('done')) {
        throw Exception('Error de OpenFile: ${result.message}');
      }
    } catch (e) {
      throw Exception('No se pudo iniciar el instalador de APK: $e');
    }
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
