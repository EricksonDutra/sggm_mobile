// lib/services/stub_local_notifications.dart
// Stub para compilação Flutter Web — nenhum método executa lógica real.

class FlutterLocalNotificationsPlugin {
  const FlutterLocalNotificationsPlugin();

  Future<bool?> initialize(
    dynamic settings, {
    dynamic onDidReceiveNotificationResponse,
  }) async =>
      true;

  Future<void> show(
    int id,
    String? title,
    String? body,
    dynamic details, {
    String? payload,
  }) async {}

  Future<void> cancelAll() async {}
  Future<void> cancel(int id) async {}
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class NotificationResponse {
  final String? payload;
  const NotificationResponse({this.payload});
}

class AndroidInitializationSettings {
  final String defaultIcon;
  const AndroidInitializationSettings(this.defaultIcon);
}

class DarwinInitializationSettings {
  final bool requestAlertPermission;
  final bool requestBadgePermission;
  final bool requestSoundPermission;
  const DarwinInitializationSettings({
    this.requestAlertPermission = false,
    this.requestBadgePermission = false,
    this.requestSoundPermission = false,
  });
}

class InitializationSettings {
  final AndroidInitializationSettings? android;
  final DarwinInitializationSettings? iOS;
  const InitializationSettings({this.android, this.iOS});
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(
    String channelId,
    String channelName, {
    String? channelDescription,
    dynamic importance,
    dynamic priority,
    String? icon,
    bool enableLights = false,
    bool enableVibration = false,
    bool playSound = false,
  });
}

class DarwinNotificationDetails {
  const DarwinNotificationDetails({
    bool presentAlert = false,
    bool presentBadge = false,
    bool presentSound = false,
  });
}

class NotificationDetails {
  final AndroidNotificationDetails? android;
  final DarwinNotificationDetails? iOS;
  const NotificationDetails({this.android, this.iOS});
}

class AndroidNotificationChannel {
  const AndroidNotificationChannel(
    String id,
    String name, {
    String? description,
    dynamic importance,
    bool enableVibration = false,
    bool playSound = false,
  });
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<void> createNotificationChannel(dynamic channel) async {}
}

class Importance {
  static const Importance high = Importance._();
  const Importance._();
}

class Priority {
  static const Priority high = Priority._();
  const Priority._();
}
