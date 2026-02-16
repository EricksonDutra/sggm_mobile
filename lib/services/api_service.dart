import 'package:dio/dio.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/util/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  late final SecureTokenService _secureTokenService;
  late final Dio _dio;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _secureTokenService = SecureTokenService();

    // ✅ CORRIGIDO: Criar Dio DEPOIS de inicializar _secureTokenService
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // ✅ AGORA o interceptor pode usar _secureTokenService com segurança
    _setupInterceptors();
  }

  /// Configurar interceptadores do Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // 🔐 Adicionar token automaticamente em todas as requisições
            final token = await _secureTokenService.getToken();

            print('🔍 [AUTH] Verificando token...');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              print('✅ [AUTH] Token adicionado: ${token.substring(0, 20)}...');
            } else {
              print('⚠️ [AUTH] Token não disponível - requisição sem autenticação');
            }
          } catch (e) {
            print('❌ [AUTH] Erro ao obter token: $e');
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // 🔄 Tratar erro 401 (token expirado)
          if (error.response?.statusCode == 401) {
            print('❌ [AUTH] Token expirado ou inválido (401)');
            print('📝 Response: ${error.response?.data}');
            // TODO: Aqui você poderia tentar renovar o token com refresh_token
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// GET
  static Future<Response> get(
    String endpoint, {
    bool useAuth = true,
  }) async {
    try {
      print('📥 [API GET] $baseUrl$endpoint');
      final response = await _instance._dio.get(
        endpoint,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print('✅ [API] GET Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ [API GET] Erro: ${e.message}');
      print('📝 Response: ${e.response?.data}');
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
      print('📤 [API POST] $baseUrl$endpoint');
      if (body != null) {
        print('📋 Body keys: ${body.keys.toList()}');
      }
      final response = await _instance._dio.post(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print('✅ [API] POST Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ [API POST] Erro: ${e.message}');
      print('📝 Response: ${e.response?.data}');
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
      print('📤 [API PUT] $baseUrl$endpoint');
      final response = await _instance._dio.put(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print('✅ [API] PUT Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ [API PUT] Erro: ${e.message}');
      rethrow;
    }
  }

  /// DELETE
  static Future<Response> delete(
    String endpoint, {
    bool useAuth = true,
  }) async {
    try {
      print('🗑️ [API DELETE] $baseUrl$endpoint');
      final response = await _instance._dio.delete(
        endpoint,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print('✅ [API] DELETE Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ [API DELETE] Erro: ${e.message}');
      rethrow;
    }
  }
}
