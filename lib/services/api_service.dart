import 'package:dio/dio.dart';
import 'package:sggm/services/retry_interceptor.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  late final SecureTokenService _secureTokenService;
  late final Dio _dio;

  static void Function()? onTokenExpired;

  static bool _isRefreshing = false;
  static final List<_PendingRequest> _pendingRequests = [];

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
    _secureTokenService = SecureTokenService();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: AppConstants.timeoutSeconds),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  static void setOnTokenExpired(void Function() callback) {
    onTokenExpired = callback;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _secureTokenService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              AppLogger.debug('Token de autenticação adicionado');
            } else {
              AppLogger.warning('Token não disponível - requisição sem autenticação');
            }
          } catch (e) {
            AppLogger.error('Erro ao obter token', e);
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            AppLogger.warning('Token expirado (401) — tentando renovar');

            if (_isRefreshing) {
              AppLogger.debug('Já renovando token, adicionando à fila');
              _pendingRequests.add(_PendingRequest(
                requestOptions: error.requestOptions,
                handler: handler,
              ));
              return;
            }

            _isRefreshing = true;

            try {
              final refreshToken = await _secureTokenService.getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                AppLogger.warning('Refresh token não encontrado');
                _isRefreshing = false;
                _handleTokenExpiration();
                return handler.next(error);
              }

              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final refreshResponse = await refreshDio.post(
                '/api/token/refresh/',
                data: {'refresh': refreshToken},
                options: Options(
                  contentType: Headers.jsonContentType,
                  validateStatus: (status) => status != null && status < 500,
                ),
              );

              if (refreshResponse.statusCode == 200) {
                final newAccessToken = refreshResponse.data['access'] as String;
                AppLogger.debug('Novo access token obtido');

                await _secureTokenService.saveCredentials(
                  token: newAccessToken,
                  refreshToken: refreshToken,
                  isLider: await _secureTokenService.getIsLider(),
                  musicoId: (await _secureTokenService.getMusicoId()) ?? 0,
                  tipoUsuario: (await _secureTokenService.getTipoUsuario()) ?? 'MUSICO',
                  nome: await _secureTokenService.getNome(),
                  username: await _secureTokenService.getUsername(),
                  email: await _secureTokenService.getEmail(),
                );

                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await _dio.fetch(error.requestOptions);

                AppLogger.debug('Processando ${_pendingRequests.length} requisições pendentes');
                for (var pending in _pendingRequests) {
                  pending.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  _dio.fetch(pending.requestOptions).then(
                        (res) => pending.handler.resolve(res),
                        onError: (e) => pending.handler.reject(e),
                      );
                }
                _pendingRequests.clear();
                _isRefreshing = false;

                return handler.resolve(response);
              } else if (refreshResponse.statusCode == 401) {
                AppLogger.warning('Refresh token expirado ou inválido');
                _isRefreshing = false;
                _pendingRequests.clear();
                _handleTokenExpiration();
                return handler.next(error);
              }

              AppLogger.error('Erro ao renovar token: ${refreshResponse.statusCode}');
              _isRefreshing = false;
              _pendingRequests.clear();
              return handler.next(error);
            } catch (e) {
              AppLogger.error('Exceção ao renovar token', e);
              _isRefreshing = false;
              _pendingRequests.clear();
              _handleTokenExpiration();
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  void _handleTokenExpiration() {
    AppLogger.info('Executando callback de logout por token expirado');
    onTokenExpired?.call();
  }

  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useAuth = true,
  }) async {
    try {
      final response = await _instance._dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      AppLogger.debug('GET $endpoint — status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Erro GET $endpoint', e);
      rethrow;
    }
  }

  static Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      final response = await _instance._dio.post(
        endpoint,
        data: body,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      AppLogger.debug('POST $endpoint — status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Erro POST $endpoint', e);
      rethrow;
    }
  }

  static Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      final response = await _instance._dio.put(
        endpoint,
        data: body,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      AppLogger.debug('PUT $endpoint — status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Erro PUT $endpoint', e);
      rethrow;
    }
  }

  static Future<Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      final response = await _instance._dio.patch(
        endpoint,
        data: body,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      AppLogger.debug('PATCH $endpoint — status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Erro PATCH $endpoint', e);
      rethrow;
    }
  }

  static Future<Response> delete(
    String endpoint, {
    bool useAuth = true,
  }) async {
    try {
      final response = await _instance._dio.delete(
        endpoint,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      AppLogger.debug('DELETE $endpoint — status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Erro DELETE $endpoint', e);
      rethrow;
    }
  }
}

class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.requestOptions, required this.handler});
}
