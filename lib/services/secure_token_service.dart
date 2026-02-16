import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenService {
  static const String _tokenKey = 'sggm_jwt_token';
  static const String _isLiderKey = 'sggm_is_lider';

  final FlutterSecureStorage _storage;

  SecureTokenService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveCredentials(String token, bool isLider) async {
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
    } catch (e) {
      throw Exception('Erro ao salvar credenciais: $e');
    }
  }

  /// Recuperar token JWT
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

  /// Recuperar status de líder
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

  /// Verificar se existem credenciais salvas
  Future<bool> hasCredentials() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Deletar credenciais (logout)
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
    } catch (e) {
      throw Exception('Erro ao deletar credenciais: $e');
    }
  }

  // Configurações específicas do Android
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  // Configurações específicas do iOS (Keychain)
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
}
