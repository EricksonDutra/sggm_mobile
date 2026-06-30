// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'package:sggm/services/stub_local_notifications.dart';

import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/navigation_service.dart';
import 'package:sggm/util/notification_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal(); // construtor vazio — sem acesso ao Firebase aqui

  // LAZY: getter em vez de field final — só acessa após Firebase.initializeApp()
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;

  FlutterLocalNotificationsPlugin? _localNotifications;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    AppLogger.debug('Inicializando notificações...');

    await _requestPermission();

    if (!kIsWeb) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      await _setupLocalNotifications();
    }

    await _getFCMToken();
    _setupMessageHandlers();

    AppLogger.info('Notificações configuradas com sucesso');
  }

  Future<void> _requestPermission() async {
    try {
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
    } catch (e) {
      AppLogger.warning('Permissão de notificação não disponível: $e');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

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
    if (_localNotifications == null) return;

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

    await _localNotifications!.initialize(
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

    await _localNotifications!
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
    if (!kIsWeb) await _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    final tipo = message.data['tipo'];
    final eventoId = message.data['evento_id'];
    AppLogger.debug('Notificação clicada — tipo: $tipo | eventoId: $eventoId');
    _navegarParaDestino(tipo: tipo, eventoId: eventoId);
  }

  void _navegarParaDestino({required String? tipo, required String? eventoId}) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      AppLogger.warning('Navigator não disponível para navegação via notificação');
      return;
    }
    final route = resolveNotificationRoute(tipo: tipo, eventoId: eventoId);
    AppLogger.debug('Navegando para ${route.route} | args: ${route.arguments}');
    navigator.pushNamed(route.route, arguments: route.arguments);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb || _localNotifications == null) return;

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

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      message.notification?.title ?? 'Nova Notificação',
      message.notification?.body ?? '',
      details,
      payload: '${message.data['tipo']}|${message.data['evento_id'] ?? ''}',
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug('Notificação local clicada — payload: ${response.payload}');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    final tipo = parts.isNotEmpty ? parts[0] : null;
    final eventoId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    _navegarParaDestino(tipo: tipo, eventoId: eventoId);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || _localNotifications == null) return;
    await _localNotifications!.cancelAll();
    AppLogger.info('Todas as notificações canceladas');
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb || _localNotifications == null) return;
    await _localNotifications!.cancel(id);
    AppLogger.info('Notificação ID $id cancelada');
  }
}
