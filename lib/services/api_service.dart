import 'package:dio/dio.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/util/constants.dart';
import 'package:sggm/util/app_logger.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  late final SecureTokenService _secureTokenService;
  late final Dio _dio;

  // ✅ Callback para notificar logout quando refresh token expira
  static void Function()? onTokenExpired;

  // ✅ Controle de renovação para evitar múltiplas chamadas simultâneas
  static bool _isRefreshing = false;
  static final List<_PendingRequest> _pendingRequests = [];

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _secureTokenService = SecureTokenService();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// ✅ Método para setar callback de logout
  static void setOnTokenExpired(void Function() callback) {
    onTokenExpired = callback;
  }

  /// Configurar interceptadores do Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // 🔐 Adicionar token automaticamente em todas as requisições
            final token = await _secureTokenService.getToken();

            AppLogger.debug('🔍 [AUTH] Verificando token...');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              AppLogger.debug('✅ [AUTH] Token adicionado');
            } else {
              AppLogger.warning('⚠️ [AUTH] Token não disponível');
            }
          } catch (e) {
            AppLogger.error('❌ [AUTH] Erro ao obter token', e);
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // 🔄 Tratar erro 401 (token expirado) com renovação automática
          if (error.response?.statusCode == 401) {
            AppLogger.warning('❌ [AUTH] Token expirado (401)');

            // Se já está renovando, adicionar à fila de requisições pendentes
            if (_isRefreshing) {
              AppLogger.debug('⏳ [AUTH] Já renovando token, adicionando à fila...');
              _pendingRequests.add(_PendingRequest(
                requestOptions: error.requestOptions,
                handler: handler,
              ));
              return;
            }

            _isRefreshing = true;

            try {
              AppLogger.debug('🔄 [AUTH] Tentando renovar access token...');

              // Obter refresh token
              final refreshToken = await _secureTokenService.getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                AppLogger.warning('❌ [AUTH] Refresh token não encontrado');
                _isRefreshing = false;
                _handleTokenExpiration();
                return handler.next(error);
              }

              // Chamar endpoint de refresh
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
                AppLogger.debug('✅ [AUTH] Novo access token obtido');

                // Salvar novo token
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

                // ✅ Retentar requisição original com novo token
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                final response = await _dio.fetch(error.requestOptions);

                // ✅ Processar requisições pendentes
                AppLogger.debug('📋 [AUTH] Processando ${_pendingRequests.length} requisições pendentes');
                for (var pending in _pendingRequests) {
                  pending.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  _dio.fetch(pending.requestOptions).then(
                    (response) {
                      pending.handler.resolve(response);
                    },
                    onError: (e) {
                      pending.handler.reject(e);
                    },
                  );
                }
                _pendingRequests.clear();
                _isRefreshing = false;

                return handler.resolve(response);
              } else if (refreshResponse.statusCode == 401) {
                // Refresh token expirado
                AppLogger.warning('❌ [AUTH] Refresh token expirado ou inválido');
                _isRefreshing = false;
                _pendingRequests.clear();
                _handleTokenExpiration();
                return handler.next(error);
              }

              AppLogger.warning('❌ [AUTH] Erro ao renovar token: ${refreshResponse.statusCode}');
              _isRefreshing = false;
              _pendingRequests.clear();
              return handler.next(error);
            } catch (e) {
              AppLogger.warning('❌ [AUTH] Exceção ao renovar token: $e');
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

  /// ✅ Método para lidar com expiração do refresh token
  void _handleTokenExpiration() {
    AppLogger.debug('🚪 [AUTH] Executando callback de logout...');
    if (onTokenExpired != null) {
      onTokenExpired!();
    }
  }

  /// GET
  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useAuth = true,
  }) async {
    try {
      AppLogger.debug('📥 [API GET] $baseUrl$endpoint');
      final response = await _instance._dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      AppLogger.info('✅ [API] GET Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.warning('❌ [API GET] Erro: ${e.message}');
      AppLogger.warning('📝 Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// POST
  static Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      AppLogger.debug('📤 [API POST] $baseUrl$endpoint');
      if (body != null) {
        AppLogger.debug('📋 Body keys: ${body.keys.toList()}');
      }
      final response = await _instance._dio.post(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      AppLogger.info('✅ [API] POST Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.warning('❌ [API POST] Erro: ${e.message}');
      AppLogger.warning('📝 Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// PUT
  static Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      AppLogger.debug('📤 [API PUT] $baseUrl$endpoint');
      final response = await _instance._dio.put(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      AppLogger.info('✅ [API] PUT Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.warning('❌ [API PUT] Erro: ${e.message}');
      AppLogger.warning('📝 Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// PATCH
  static Future<Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    try {
      AppLogger.debug('📤 [API PATCH] $baseUrl$endpoint');
      final response = await _instance._dio.patch(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      AppLogger.info('✅ [API] PATCH Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.warning('❌ [API PATCH] Erro: ${e.message}');
      AppLogger.warning('📝 Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// DELETE
  static Future<Response> delete(
    String endpoint, {
    bool useAuth = true,
  }) async {
    try {
      AppLogger.debug('🗑️ [API DELETE] $baseUrl$endpoint');
      final response = await _instance._dio.delete(
        endpoint,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      AppLogger.info('✅ [API] DELETE Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.warning('❌ [API DELETE] Erro: ${e.message}');
      AppLogger.warning('📝 Response: ${e.response?.data}');
      rethrow;
    }
  }
}

/// ✅ Classe auxiliar para gerenciar requisições pendentes
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest({
    required this.requestOptions,
    required this.handler,
  });
}
