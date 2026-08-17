import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificación persistente de progreso para las descargas de sitios.
///
/// Resuelve directamente la queja de "no hay ninguna señal de que algo
/// esté pasando": mientras se descarga un sitio, el técnico ve una
/// notificación con el nombre del sitio y el porcentaje real, visible
/// aunque minimice la app.
class DownloadNotificationService {
  static const _channelId = 'site_downloads';
  static const _channelName = 'Descargas de mapas sin conexión';
  static const _notificationId = 9001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Progreso de descarga de zonas para uso sin conexión.',
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Android 13+ requiere permiso explícito para mostrar notificaciones.
  /// Llamar antes de la primera descarga (ver map_layer_provider.dart).
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showProgress({
    required String siteName,
    required int completed,
    required int total,
  }) async {
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();
    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          'Progreso de descarga de zonas para uso sin conexión.',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      ongoing: completed < total,
      autoCancel: completed >= total,
    );
    await _plugin.show(
      id: _notificationId,
      title: 'Descargando $siteName',
      body: '$percent% ($completed de $total tiles)',
      notificationDetails: NotificationDetails(android: details),
    );
  }

  Future<void> showDone(String siteName) async {
    const details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: false,
      autoCancel: true,
    );
    await _plugin.show(
      id: _notificationId,
      title: '$siteName descargado',
      body: 'Disponible para uso sin conexión.',
      notificationDetails: const NotificationDetails(android: details),
    );
  }

  Future<void> cancel() => _plugin.cancel(id: _notificationId);
}
