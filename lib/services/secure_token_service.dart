import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenService {
  static const String _tokenKey = 'sggm_jwt_token';
  static const String _isLiderKey = 'sggm_is_lider';
  static const String _musicoIdKey = 'sggm_musico_id'; // ✅ NOVO
  static const String _tipoUsuarioKey = 'sggm_tipo_usuario'; // ✅ NOVO

  final FlutterSecureStorage _storage;

  SecureTokenService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  // ✅ ATUALIZADO: Salvar mais informações do login
  Future<void> saveCredentials({
    required String token,
    required bool isLider,
    required int musicoId, // ✅ NOVO
    required String tipoUsuario, // ✅ NOVO
  }) async {
    try {
      await _storage.write(
        key: _tokenKey,
        value: token,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      await _storage.write(
        key: _isLiderKey,
        value: isLider.toString(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      // ✅ NOVO: Salvar musicoId
      await _storage.write(
        key: _musicoIdKey,
        value: musicoId.toString(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      // ✅ NOVO: Salvar tipoUsuario
      await _storage.write(
        key: _tipoUsuarioKey,
        value: tipoUsuario,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      throw Exception('Erro ao salvar credenciais: $e');
    }
  }

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

  // ✅ NOVO: Recuperar ID do músico logado
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

  // ✅ NOVO: Recuperar tipo de usuário
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

  Future<bool> hasCredentials() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteCredentials() async {
    try {
      await _storage.delete(
        key: _tokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _isLiderKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      // ✅ NOVO: Deletar novos campos
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
    } catch (e) {
      throw Exception('Erro ao deletar credenciais: $e');
    }
  }

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
}
