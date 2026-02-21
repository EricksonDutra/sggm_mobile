// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

import 'package:sggm/util/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    AppLogger.debug('Inicializando notificações...');

    await _requestPermission();
    await _setupLocalNotifications();
    await _getFCMToken();
    _setupMessageHandlers();

    AppLogger.info('Notificações configuradas com sucesso');
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        AppLogger.info('Permissão de notificação concedida');
        break;
      case AuthorizationStatus.provisional:
        AppLogger.warning('Permissão de notificação provisória concedida');
        break;
      default:
        AppLogger.warning('Permissão de notificação negada');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        _fcmToken = await _firebaseMessaging.getToken();
      }

      if (_fcmToken != null) {
        AppLogger.debug('FCM Token obtido com sucesso');
        return _fcmToken;
      }

      AppLogger.warning('Não foi possível obter o FCM Token');
      return null;
    } catch (e) {
      AppLogger.error('Erro ao obter FCM Token', e);
      return null;
    }
  }

  Future<String?> getToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      AppLogger.debug('Usando FCM Token em cache');
      return _fcmToken;
    }

    AppLogger.debug('Buscando novo FCM Token...');
    return await _getFCMToken();
  }

  void onTokenRefresh(Function(String token) callback) {
    _firebaseMessaging.onTokenRefresh.listen(
      (newToken) {
        AppLogger.debug('FCM Token atualizado pelo Firebase');
        _fcmToken = newToken;
        callback(newToken);
      },
      onError: (error) {
        AppLogger.error('Erro ao atualizar FCM Token', error);
      },
    );
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const androidChannel = AndroidNotificationChannel(
      'sggm_channel',
      'SGGM Notificações',
      description: 'Notificações de escalas e eventos',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleBackgroundMessage(message);
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.debug(
      'Mensagem recebida em foreground — título: ${message.notification?.title}',
    );
    await _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    final tipo = message.data['tipo'];
    final eventoId = message.data['evento_id'];
    AppLogger.debug('Notificação clicada — tipo: $tipo | eventoId: $eventoId');

    // TODO: Implementar navegação
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'sggm_channel',
      'SGGM Notificações',
      channelDescription: 'Notificações de escalas e eventos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Nova Notificação',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug('Notificação local clicada');
    // TODO: Implementar navegação baseada no payload
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    AppLogger.info('Todas as notificações canceladas');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    AppLogger.info('Notificação ID $id cancelada');
  }
}
