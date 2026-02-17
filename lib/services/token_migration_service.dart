import 'secure_token_service.dart';

class TokenMigrationService {
  // ignore: unused_field
  final SecureTokenService _secureTokenService;

  TokenMigrationService(this._secureTokenService);

  /// Migração não mais necessária - todos os tokens agora são seguros
  Future<void> migrateIfNeeded() async {
    print('ℹ️ Sistema de tokens atualizado - migração não necessária');
    // Não faz nada - migração desativada
    return;
  }
}
