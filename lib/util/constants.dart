class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.ericksondutra.cloud',
  );

  static const int timeoutSeconds = int.fromEnvironment(
    'TIMEOUT_SECONDS',
    defaultValue: 10,
  );

  static const String escalasEndpoint = '$baseUrl/api/escalas/';
  static const String musicosEndpoint = '$baseUrl/api/musicos/';
  static const String eventosEndpoint = '$baseUrl/api/eventos/';
  static const String instrumentosEndpoint = '$baseUrl/api/instrumentos/';
  static const String musicasEndpoint = '$baseUrl/api/musicas/';

  static const String loginPath = '/api/login/';
  static const String refreshTokenPath = '/api/token/refresh/';
  static const String atualizarFCMTokenPath = '/api/musicos/atualizar_fcm_token/';
}

class AppRoutes {
  static const String home = '/home';
  static const String musicos = '/musicos';
  static const String eventos = '/eventos';
  static const String escalas = '/escalas';
}
