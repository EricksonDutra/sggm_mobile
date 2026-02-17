import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/util/constants.dart';

class AuthProvider extends ChangeNotifier {
  // ========== Secure Storage ==========
  late SecureTokenService _secureTokenService;

  // ========== State ==========
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isLider = false;
  bool _isAdmin = false;
  String? _token;
  String? _refreshToken;

  // ========== User Data ==========
  Map<String, dynamic>? _userData;

  // ========== Getters ==========
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isLider => _isLider;
  bool get isAdmin => _isAdmin;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;

  // ========== Constructor ==========
  AuthProvider({SecureTokenService? secureTokenService}) {
    _secureTokenService = secureTokenService ?? SecureTokenService();
  }

  // ========== LOGIN ==========
  /// Fazer login com username e password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔐 Tentando login: $username');

      // ✅ Login usa POST direto (sem ApiService) porque não tem token ainda
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        AppConstants.loginPath,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ Extrair dados da resposta
        _token = data['access'];
        _refreshToken = data['refresh'];
        _isLider = data['is_lider'] ?? false;
        _isAdmin = data['is_admin'] ?? false;
        _isAuthenticated = true;

        // ✅ Salvar dados do usuário
        _userData = {
          'refresh': _refreshToken,
          'musico_id': data['musico_id'],
          'nome': data['nome'],
          'username': data['username'],
          'email': data['email'],
          'tipo_usuario': data['tipo_usuario'],
          'is_lider': _isLider,
          'is_admin': _isAdmin,
        };

        // 🔐 Salvar credenciais de forma segura
        await _secureTokenService.saveCredentials(
          token: _token!,
          isLider: _isLider,
          musicoId: data['musico_id'] ?? 0, // ✅ NOVO
          tipoUsuario: data['tipo_usuario'] ?? 'MUSICO', // ✅ NOVO
        );

        print('✅ Login realizado: ${_userData!['nome']}');
        print('👤 Tipo: ${_userData!['tipo_usuario']}');
        print('👑 É líder: $_isLider');

        // 📤 Enviar token FCM ao backend
        await enviarFCMToken();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Erro no login: ${response.statusCode}');
        print('📝 Response: ${response.data}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      print('❌ Erro DioException no login: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Exceção no login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== FCM TOKEN ==========
  /// Enviar token FCM para o backend
  Future<void> enviarFCMToken() async {
    if (_token == null) {
      print('⚠️ Token JWT não disponível');
      return;
    }

    try {
      final fcmToken = await NotificationService().getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Token FCM não disponível');
        return;
      }

      print('📤 Enviando token FCM...');

      // ✅ Usar ApiService para endpoints autenticados
      final response = await ApiService.post(
        AppConstants.atualizarFCMTokenPath,
        body: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM enviado com sucesso');
      } else {
        print('❌ Erro ao enviar token FCM: ${response.statusCode}');
        print('📝 Body: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ Erro ao enviar token FCM: ${e.message}');
      print('📝 Response: ${e.response?.data}');
    } catch (e) {
      print('❌ Exceção ao enviar token FCM: $e');
    }
  }

  /// Re-enviar token FCM
  Future<void> reenviarFCMToken() async {
    print('🔄 Reenviando token FCM...');
    await enviarFCMToken();
  }

  // ========== AUTO-LOGIN ==========
  /// Carregar autenticação salva ao abrir o app
  Future<void> loadSavedAuth() async {
    try {
      print('🔍 Verificando autenticação salva...');
      final hasCredentials = await _secureTokenService.hasCredentials();
      if (hasCredentials) {
        _token = await _secureTokenService.getToken();
        _isLider = await _secureTokenService.getIsLider();

        final musicoId = await _secureTokenService.getMusicoId();
        final tipoUsuario = await _secureTokenService.getTipoUsuario();

        _isAuthenticated = true;

        // ✅ Reconstruir userData a partir do storage
        _userData = {
          'musico_id': musicoId,
          'tipo_usuario': tipoUsuario,
          'is_lider': _isLider,
        };
        print('✅ Token JWT carregado do armazenamento seguro');
        print('👤 Músico ID: $musicoId');
        print('👤 Tipo: $tipoUsuario');

        // ✅ Reenviar FCM token apenas se autenticado
        await enviarFCMToken();

        notifyListeners();
      } else {
        print('ℹ️ Nenhuma sessão salva encontrada');
      }
    } catch (e) {
      print('❌ Erro ao carregar auth: $e');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  // ========== LOGOUT ==========
  /// Fazer logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        // ✅ Limpar token FCM no backend usando ApiService
        await ApiService.post(
          AppConstants.atualizarFCMTokenPath,
          body: {'fcm_token': ''},
        );
        print('✅ Token FCM limpo no backend');
      }
    } on DioException catch (e) {
      print('⚠️ Erro ao limpar token FCM: ${e.message}');
    } catch (e) {
      print('⚠️ Erro ao limpar token FCM: $e');
    }

    // Limpar estado local
    _isAuthenticated = false;
    _isLider = false;
    _isAdmin = false;
    _token = null;
    _refreshToken = null;
    _userData = null;

    // Limpar armazenamento seguro
    await _secureTokenService.deleteCredentials();

    print('✅ Logout realizado');
    notifyListeners();
  }

  // ========== UTILITÁRIOS ==========
  /// Verificar se o token ainda é válido (decodificar JWT)
  bool isTokenValid() {
    if (_token == null) return false;
    try {
      final parts = _token!.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return false;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expirationDate);
    } catch (e) {
      print('⚠️ Erro ao validar token: $e');
      return false;
    }
  }

  /// Obter o tempo restante do token em minutos
  int? getTokenExpirationMinutes() {
    if (_token == null) return null;
    try {
      final parts = _token!.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return null;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      if (expirationDate.isBefore(now)) return 0;
      return expirationDate.difference(now).inMinutes;
    } catch (e) {
      print('⚠️ Erro ao calcular expiração: $e');
      return null;
    }
  }

  /// Obter informações do usuário decodificadas do token
  Map<String, dynamic>? getTokenPayload() {
    if (_token == null) return null;
    try {
      final parts = _token!.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      return payload;
    } catch (e) {
      print('⚠️ Erro ao decodificar token: $e');
      return null;
    }
  }
}
