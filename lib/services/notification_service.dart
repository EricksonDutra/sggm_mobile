// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    print('🔔 [NOTIFICAÇÕES] Inicializando...');

    // 1. Solicitar permissão (iOS)
    await _requestPermission();

    // 2. Configurar notificações locais
    await _setupLocalNotifications();

    // 3. Obter FCM Token inicial
    await _getFCMToken();

    // 4. Handlers de mensagens
    _setupMessageHandlers();

    print('✅ [NOTIFICAÇÕES] Configuradas com sucesso!');
  }

  /// Solicita permissão para notificações (principalmente iOS)
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 [PERMISSÃO] Status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [PERMISSÃO] Usuário concedeu permissão');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ [PERMISSÃO] Usuário concedeu permissão provisória');
    } else {
      print('❌ [PERMISSÃO] Usuário negou permissão');
    }
  }

  /// Obtém o FCM Token do dispositivo (método privado para inicialização)
  Future<String?> _getFCMToken() async {
    try {
      // Para web, você precisaria passar vapidKey aqui
      if (Platform.isIOS || Platform.isAndroid) {
        _fcmToken = await _firebaseMessaging.getToken();
      }

      if (_fcmToken != null) {
        print('✅ [FCM TOKEN] Obtido: ${_fcmToken!.substring(0, 20)}...');
        return _fcmToken;
      } else {
        print('⚠️ [FCM TOKEN] Não foi possível obter');
        return null;
      }
    } catch (e) {
      print('❌ [FCM TOKEN] Erro ao obter: $e');
      return null;
    }
  }

  /// 🔥 PÚBLICO: Obtém o token FCM (pode ser chamado de qualquer lugar)
  /// Usado pelo AuthProvider para enviar token ao backend
  Future<String?> getToken() async {
    // Se já temos o token em cache, retorna
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      print('✅ [GET TOKEN] Usando token em cache');
      return _fcmToken;
    }

    // Caso contrário, busca um novo
    print('🔄 [GET TOKEN] Buscando novo token...');
    return await _getFCMToken();
  }

  /// 🔥 PÚBLICO: Método para configurar callback de token refresh
  /// Usado pelo AuthProvider para reenviar token automaticamente
  void onTokenRefresh(Function(String token) callback) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 [TOKEN REFRESH] Novo token: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;

      // Chamar callback fornecido (ex: AuthProvider.reenviarFCMToken)
      callback(newToken);
    }, onError: (error) {
      print('❌ [TOKEN REFRESH] Erro: $error');
    });
  }

  /// Configuração de notificações locais
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

    // Criar canal de notificação Android
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

  /// Configuração dos handlers de mensagens
  void _setupMessageHandlers() {
    // App em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App em background (clique na notificação)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // App fechado (clique na notificação que abriu o app)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });
  }

  /// Handler quando mensagem chega com app aberto
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 [MENSAGEM] Recebida em foreground');
    print('   Título: ${message.notification?.title}');
    print('   Corpo: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Mostrar notificação local
    await _showLocalNotification(message);
  }

  /// Handler quando usuário clica na notificação
  void _handleBackgroundMessage(RemoteMessage message) {
    print('🖱️ [CLIQUE] Notificação clicada');
    print('   Data: ${message.data}');

    // Extrair dados
    final tipo = message.data['tipo'];
    final eventoId = message.data['evento_id'];

    print('   Tipo: $tipo');
    print('   Evento ID: $eventoId');

    // TODO: Implementar navegação
    // Exemplo usando GlobalKey<NavigatorState>:
    // navigatorKey.currentState?.pushNamed('/evento/$eventoId');
  }

  /// Mostra notificação local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'sggm_channel',
      'SGGM Notificações',
      channelDescription: 'Notificações de escalas e eventos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // 🔥 Personalização adicional
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Nova Notificação',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Callback quando notificação é clicada
  void _onNotificationTapped(NotificationResponse response) {
    print('🖱️ [CLIQUE LOCAL] Payload: ${response.payload}');

    // TODO: Implementar navegação baseada no payload
    // Exemplo:
    // final data = json.decode(response.payload ?? '{}');
    // final eventoId = data['evento_id'];
    // navigatorKey.currentState?.pushNamed('/evento/$eventoId');
  }

  /// 🔥 Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ [NOTIFICAÇÕES] Todas canceladas');
  }

  /// 🔥 Cancela notificação específica
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('🗑️ [NOTIFICAÇÃO] ID $id cancelada');
  }
}
