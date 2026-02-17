import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenService {
  static const String _tokenKey = 'sggm_jwt_token';
  static const String _refreshTokenKey = 'sggm_refresh_token';
  static const String _isLiderKey = 'sggm_is_lider';
  static const String _musicoIdKey = 'sggm_musico_id';
  static const String _tipoUsuarioKey = 'sggm_tipo_usuario';
  static const String _nomeKey = 'sggm_nome'; // ✅ Adicionado
  static const String _usernameKey = 'sggm_username'; // ✅ Adicionado
  static const String _emailKey = 'sggm_email'; // ✅ Adicionado
  static const String _biometricEnabledKey = 'sggm_biometric_enabled';
  static const String _biometricUsernameKey = 'sggm_biometric_username';

  final FlutterSecureStorage _storage;

  SecureTokenService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  // ========== SALVAR CREDENCIAIS ==========
  Future<void> saveCredentials({
    required String token,
    String? refreshToken,
    required bool isLider,
    required int musicoId,
    required String tipoUsuario,
    String? nome, // ✅ Adicionado
    String? username, // ✅ Adicionado
    String? email, // ✅ Adicionado
  }) async {
    try {
      await _storage.write(
        key: _tokenKey,
        value: token,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      if (refreshToken != null) {
        await _storage.write(
          key: _refreshTokenKey,
          value: refreshToken,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
      }

      await _storage.write(
        key: _isLiderKey,
        value: isLider.toString(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      await _storage.write(
        key: _musicoIdKey,
        value: musicoId.toString(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      await _storage.write(
        key: _tipoUsuarioKey,
        value: tipoUsuario,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      // ✅ Salvar dados adicionais do usuário
      if (nome != null) {
        await _storage.write(
          key: _nomeKey,
          value: nome,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
      }

      if (username != null) {
        await _storage.write(
          key: _usernameKey,
          value: username,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
      }

      if (email != null) {
        await _storage.write(
          key: _emailKey,
          value: email,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
      }
    } catch (e) {
      throw Exception('Erro ao salvar credenciais: $e');
    }
  }

  // ========== RECUPERAR DADOS ==========
  Future<String?> getToken() async {
    try {
      return await _storage.read(
        key: _tokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      throw Exception('Erro ao recuperar token: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(
        key: _refreshTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> getIsLider() async {
    try {
      final value = await _storage.read(
        key: _isLiderKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<int?> getMusicoId() async {
    try {
      final value = await _storage.read(
        key: _musicoIdKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getTipoUsuario() async {
    try {
      return await _storage.read(
        key: _tipoUsuarioKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ NOVOS MÉTODOS
  Future<String?> getNome() async {
    try {
      return await _storage.read(
        key: _nomeKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(
        key: _usernameKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getEmail() async {
    try {
      return await _storage.read(
        key: _emailKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }

  // ========== VERIFICAÇÃO ==========
  Future<bool> hasCredentials() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== DELETAR CREDENCIAIS ==========
  Future<void> deleteCredentials() async {
    try {
      await _storage.delete(
        key: _tokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _refreshTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _isLiderKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _musicoIdKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _tipoUsuarioKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _nomeKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _usernameKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _emailKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      throw Exception('Erro ao deletar credenciais: $e');
    }
  }

  // ========== CONFIGURAÇÕES DE SEGURANÇA ==========
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<void> enableBiometricLogin(String username) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: 'true',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      await _storage.write(
        key: _biometricUsernameKey,
        value: username,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      print('✅ Login biométrico habilitado para: $username');
    } catch (e) {
      throw Exception('Erro ao habilitar biometria: $e');
    }
  }

  /// Desabilitar login biométrico
  Future<void> disableBiometricLogin() async {
    try {
      await _storage.delete(
        key: _biometricEnabledKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _biometricUsernameKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      print('✅ Login biométrico desabilitado');
    } catch (e) {
      throw Exception('Erro ao desabilitar biometria: $e');
    }
  }

  /// Verificar se login biométrico está habilitado
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(
        key: _biometricEnabledKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Obter username salvo para biometria
  Future<String?> getBiometricUsername() async {
    try {
      return await _storage.read(
        key: _biometricUsernameKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      return null;
    }
  }
}
