import 'package:sggm/util/app_logger.dart';

import 'secure_token_service.dart';

class TokenMigrationService {
  // ignore: unused_field
  final SecureTokenService _secureTokenService;

  TokenMigrationService(this._secureTokenService);

  /// Migração não mais necessária - todos os tokens agora são seguros
  Future<void> migrateIfNeeded() async {
    AppLogger.info('ℹ️ Sistema de tokens atualizado - migração não necessária');
    // Não faz nada - migração desativada
    return;
  }
}
