import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sggm/core/errors/error_handler.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/services/biometric_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class AuthProvider extends ChangeNotifier {
  late SecureTokenService _secureTokenService;
  late BiometricService _biometricService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isLider = false;
  bool _isAdmin = false;
  String? _token;
  String? _refreshToken;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isLider => _isLider;
  bool get isAdmin => _isAdmin;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider({SecureTokenService? secureTokenService}) {
    _secureTokenService = secureTokenService ?? SecureTokenService();
    _biometricService = BiometricService();
  }

  Future<bool> refreshAccessToken() async {
    try {
      final savedRefreshToken = await _secureTokenService.getRefreshToken();

      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        AppLogger.warning('Refresh token não encontrado');
        await logout();
        return false;
      }

      AppLogger.info('Renovando access token...');

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

        AppLogger.info('Access token renovado com sucesso');
        notifyListeners();
        return true;
      }

      if (response.statusCode == 401) {
        AppLogger.warning('Refresh token expirado, redirecionando para login');
        await logout();
        return false;
      }

      AppLogger.error('Erro ao renovar token: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      AppLogger.error('Erro ao renovar token', e);
      if (e.response?.statusCode == 401) await logout();
      return false;
    } catch (e) {
      AppLogger.error('Exceção ao renovar token', e);
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null; // ✅ CORREÇÃO 1: limpa erro anterior a cada tentativa
    notifyListeners();

    try {
      AppLogger.debug('Tentando login...');

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        AppConstants.loginPath,
        data: {'username': username, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      AppLogger.debug('Login status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        _token = data['access'];
        _refreshToken = data['refresh'];
        _isLider = data['is_lider'] ?? false;
        _isAdmin = data['is_admin'] ?? false;
        _isAuthenticated = true;

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

        AppLogger.info('Login realizado com sucesso');
        await enviarFCMToken();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // ✅ CORREÇÃO 2: status não-200 (401, 403, etc.) agora popula _errorMessage
      AppLogger.warning('Erro no login: ${response.statusCode}');
      final appException = ErrorHandler.handle(
        DioException(
          requestOptions: RequestOptions(path: AppConstants.loginPath),
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
      _errorMessage = appException.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // ✅ CORREÇÃO 3: um único catch trata DioException de rede e demais erros
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('login exception', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> enviarFCMToken() async {
    if (_token == null) {
      AppLogger.warning('Token JWT não disponível para envio do FCM');
      return;
    }

    try {
      final fcmToken = await NotificationService().getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        AppLogger.warning('Token FCM não disponível');
        return;
      }

      AppLogger.debug('Enviando token FCM...');

      final response = await ApiService.post(
        AppConstants.atualizarFCMTokenPath,
        body: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        AppLogger.info('Token FCM enviado com sucesso');
      } else {
        AppLogger.warning('Erro ao enviar token FCM: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('Erro ao enviar token FCM', e);
    } catch (e) {
      AppLogger.error('Exceção ao enviar token FCM', e);
    }
  }

  Future<void> reenviarFCMToken() async {
    AppLogger.debug('Reenviando token FCM...');
    await enviarFCMToken();
  }

  Future<void> loadSavedAuth() async {
    try {
      AppLogger.debug('Verificando autenticação salva...');
      final hasCredentials = await _secureTokenService.hasCredentials();

      if (!hasCredentials) {
        AppLogger.info('Nenhuma sessão salva encontrada');
        return;
      }

      _token = await _secureTokenService.getToken();
      _refreshToken = await _secureTokenService.getRefreshToken();
      _isLider = await _secureTokenService.getIsLider();

      _userData = {
        'musico_id': await _secureTokenService.getMusicoId(),
        'tipo_usuario': await _secureTokenService.getTipoUsuario(),
        'is_lider': _isLider,
        'nome': await _secureTokenService.getNome(),
        'username': await _secureTokenService.getUsername(),
        'email': await _secureTokenService.getEmail(),
        'refresh': _refreshToken,
      };

      if (!isTokenValid()) {
        AppLogger.warning('Access token expirado, tentando renovar...');
        final renewed = await refreshAccessToken();
        if (!renewed) {
          AppLogger.warning('Não foi possível renovar o token');
          _isAuthenticated = false;
          _userData = null;
          notifyListeners();
          return;
        }
      }

      _isAuthenticated = true;
      AppLogger.info('Sessão restaurada com sucesso');

      await enviarFCMToken();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar auth', e, stackTrace);
      _isAuthenticated = false;
      _userData = null;
      notifyListeners();
    }
  }

  Future<bool> canUseBiometric() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      AppLogger.error('Erro ao verificar biometria', e);
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureTokenService.isBiometricEnabled();
    } catch (e) {
      AppLogger.error('Erro ao verificar se biometria está habilitada', e);
      return false;
    }
  }

  Future<String> getBiometricDescription() async {
    try {
      return await _biometricService.getBiometricTypeDescription();
    } catch (e) {
      AppLogger.error('Erro ao obter descrição da biometria', e);
      return 'Biometria';
    }
  }

  Future<void> enableBiometricLogin() async {
    try {
      if (_userData?['username'] == null) {
        AppLogger.warning('Username não disponível para habilitar biometria');
        return;
      }
      await _secureTokenService.enableBiometricLogin(_userData!['username']);
      AppLogger.info('Login biométrico habilitado');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Erro ao habilitar biometria', e);
      rethrow;
    }
  }

  Future<void> disableBiometricLogin() async {
    try {
      await _secureTokenService.disableBiometricLogin();
      AppLogger.info('Login biométrico desabilitado');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Erro ao desabilitar biometria', e);
      rethrow;
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      AppLogger.debug('Iniciando login biométrico...');

      final enabled = await _secureTokenService.isBiometricEnabled();
      if (!enabled) {
        AppLogger.warning('Login biométrico não habilitado');
        return false;
      }

      final hasCredentials = await _secureTokenService.hasCredentials();
      if (!hasCredentials) {
        AppLogger.warning('Sem credenciais salvas para login biométrico');
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        reason: 'Autentique-se para acessar o SGGM',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (!authenticated) {
        AppLogger.warning('Autenticação biométrica falhou ou foi cancelada');
        return false;
      }

      AppLogger.info('Biometria validada, restaurando sessão...');
      await loadSavedAuth();

      return _isAuthenticated;
    } catch (e) {
      AppLogger.error('Erro no login biométrico', e);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await ApiService.post(
          AppConstants.atualizarFCMTokenPath,
          body: {'fcm_token': ''},
        );
        AppLogger.info('Token FCM limpo no backend');
      }
    } on DioException catch (e) {
      AppLogger.error('Erro ao limpar token FCM', e);
    } catch (e) {
      AppLogger.error('Erro ao limpar token FCM', e);
    }

    _isAuthenticated = false;
    _isLider = false;
    _isAdmin = false;
    _token = null;
    _refreshToken = null;
    _userData = null;

    await _secureTokenService.deleteCredentials();

    AppLogger.info('Logout realizado');
    notifyListeners();
  }

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
      return DateTime.now().isBefore(
        expirationDate.subtract(const Duration(seconds: 30)),
      );
    } catch (e) {
      AppLogger.error('Erro ao validar token', e);
      return false;
    }
  }

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
      AppLogger.error('Erro ao calcular expiração do token', e);
      return null;
    }
  }

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
      return '${expirationDate.day}/${expirationDate.month}/${expirationDate.year} '
          '${expirationDate.hour}:${expirationDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      AppLogger.error('Erro ao obter data de expiração do token', e);
      return null;
    }
  }

  Map<String, dynamic>? getTokenPayload() {
    if (_token == null) return null;
    try {
      final parts = _token!.split('.');
      if (parts.length != 3) return null;

      return json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } catch (e) {
      AppLogger.error('Erro ao decodificar token', e);
      return null;
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  void forceAuthStateUpdate() => notifyListeners();
}
