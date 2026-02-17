import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/services/biometric_service.dart';
import 'package:sggm/util/constants.dart';

class AuthProvider extends ChangeNotifier {
  // ========== Secure Storage ==========
  late SecureTokenService _secureTokenService;
  late BiometricService _biometricService;

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
    _biometricService = BiometricService();
  }

  // ========== REFRESH TOKEN ==========
  /// Renovar access token usando refresh token
  Future<bool> refreshAccessToken() async {
    try {
      // Recuperar refresh token do storage
      final savedRefreshToken = await _secureTokenService.getRefreshToken();

      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        print('⚠️ Refresh token não encontrado');
        await logout();
        return false;
      }

      print('🔄 Renovando access token...');

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        '/api/token/refresh/',
        data: {'refresh': savedRefreshToken},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String;
        _token = newAccessToken;

        // Atualizar token no storage (mantendo o refresh token)
        await _secureTokenService.saveCredentials(
          token: newAccessToken,
          refreshToken: savedRefreshToken,
          isLider: _isLider,
          musicoId: _userData?['musico_id'] ?? 0,
          tipoUsuario: _userData?['tipo_usuario'] ?? 'MUSICO',
          nome: _userData?['nome'],
          username: _userData?['username'],
          email: _userData?['email'],
        );

        print('✅ Access token renovado com sucesso');
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Refresh token expirou, fazer logout
        print('❌ Refresh token expirado, redirecionando para login');
        await logout();
        return false;
      }

      print('❌ Erro ao renovar token: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('❌ Erro ao renovar token: ${e.message}');
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return false;
    } catch (e) {
      print('❌ Exceção ao renovar token: $e');
      return false;
    }
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
          refreshToken: _refreshToken,
          isLider: _isLider,
          musicoId: data['musico_id'] ?? 0,
          tipoUsuario: data['tipo_usuario'] ?? 'MUSICO',
          nome: data['nome'],
          username: data['username'],
          email: data['email'],
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
        _refreshToken = await _secureTokenService.getRefreshToken();
        _isLider = await _secureTokenService.getIsLider();

        final musicoId = await _secureTokenService.getMusicoId();
        final tipoUsuario = await _secureTokenService.getTipoUsuario();
        final nome = await _secureTokenService.getNome();
        final username = await _secureTokenService.getUsername();
        final email = await _secureTokenService.getEmail();

        // ✅ Reconstruir userData ANTES de verificar token
        _userData = {
          'musico_id': musicoId,
          'tipo_usuario': tipoUsuario,
          'is_lider': _isLider,
          'nome': nome,
          'username': username,
          'email': email,
          'refresh': _refreshToken,
        };

        // ✅ Verificar validade do token e renovar se necessário
        if (!isTokenValid()) {
          print('⚠️ Access token expirado, tentando renovar...');
          final renewed = await refreshAccessToken();
          if (!renewed) {
            print('❌ Não foi possível renovar o token');
            // Limpar dados e forçar novo login
            _isAuthenticated = false;
            _userData = null;
            notifyListeners();
            return;
          }
        }

        _isAuthenticated = true;

        print('✅ Sessão restaurada: $nome');
        print('👤 Músico ID: $musicoId');
        print('👤 Tipo: $tipoUsuario');
        print('⏰ Token válido por: ${getTokenExpirationMinutes()} minutos');

        // ✅ Reenviar FCM token apenas se autenticado
        await enviarFCMToken();

        notifyListeners();
      } else {
        print('ℹ️ Nenhuma sessão salva encontrada');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar auth: $e');
      print('📋 StackTrace: $stackTrace');
      _isAuthenticated = false;
      _userData = null;
      notifyListeners();
    }
  }

  /// Verificar se pode usar biometria
  Future<bool> canUseBiometric() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      print('❌ Erro ao verificar biometria: $e');
      return false;
    }
  }

  /// Verificar se biometria está habilitada
  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureTokenService.isBiometricEnabled();
    } catch (e) {
      print('❌ Erro ao verificar se biometria está habilitada: $e');
      return false;
    }
  }

  /// Obter descrição da biometria disponível
  Future<String> getBiometricDescription() async {
    try {
      return await _biometricService.getBiometricTypeDescription();
    } catch (e) {
      print('❌ Erro ao obter descrição da biometria: $e');
      return 'Biometria';
    }
  }

  /// Habilitar login biométrico
  Future<void> enableBiometricLogin() async {
    try {
      if (_userData?['username'] != null) {
        await _secureTokenService.enableBiometricLogin(_userData!['username']);
        print('✅ Login biométrico habilitado');
        notifyListeners();
      } else {
        print('⚠️ Username não disponível para habilitar biometria');
      }
    } catch (e) {
      print('❌ Erro ao habilitar biometria: $e');
      rethrow;
    }
  }

  /// Desabilitar login biométrico
  Future<void> disableBiometricLogin() async {
    try {
      await _secureTokenService.disableBiometricLogin();
      print('✅ Login biométrico desabilitado');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao desabilitar biometria: $e');
      rethrow;
    }
  }

  /// Login com biometria
  Future<bool> loginWithBiometric() async {
    try {
      print('🔐 Iniciando login biométrico...');

      // Verificar se biometria está habilitada
      final enabled = await _secureTokenService.isBiometricEnabled();
      if (!enabled) {
        print('⚠️ Login biométrico não habilitado');
        return false;
      }

      // Verificar se há credenciais salvas
      final hasCredentials = await _secureTokenService.hasCredentials();
      if (!hasCredentials) {
        print('⚠️ Sem credenciais salvas');
        return false;
      }

      // Autenticar com biometria
      final authenticated = await _biometricService.authenticate(
        reason: 'Autentique-se para acessar o SGGM',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (!authenticated) {
        print('❌ Autenticação biométrica falhou ou foi cancelada');
        return false;
      }

      // Se autenticou, restaurar sessão
      print('✅ Biometria validada, restaurando sessão...');
      await loadSavedAuth();

      return _isAuthenticated;
    } catch (e) {
      print('❌ Erro no login biométrico: $e');
      return false;
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
      final now = DateTime.now();

      // ✅ Adicionar margem de segurança de 30 segundos
      return now.isBefore(expirationDate.subtract(const Duration(seconds: 30)));
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

  /// Obter data de expiração do token formatada
  String? getTokenExpirationDate() {
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
      return '${expirationDate.day}/${expirationDate.month}/${expirationDate.year} ${expirationDate.hour}:${expirationDate.minute}';
    } catch (e) {
      print('⚠️ Erro ao obter data de expiração: $e');
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

  /// ✅ NOVO: Forçar atualização do estado de autenticação
  void forceAuthStateUpdate() {
    notifyListeners();
  }
}
