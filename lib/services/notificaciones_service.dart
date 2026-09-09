import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionesService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    const canal = AndroidNotificationChannel(
      'moove_asistencia',
      'Asistencia Moove',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(canal);

    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) {
      final notif = mensaje.notification;
      if (notif != null) {
        mostrarLocal(titulo: notif.title ?? '', cuerpo: notif.body ?? '');
      }
    });
  }

  static Future<String?> obtenerToken() => _messaging.getToken();

  static Future<void> mostrarLocal({
    required String titulo,
    required String cuerpo,
  }) {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'moove_asistencia',
        'Asistencia Moove',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_notification',
      ),
    );
    return _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      cuerpo,
      detalles,
    );
  }
}
