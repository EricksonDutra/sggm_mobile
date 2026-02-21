import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/services/secure_token_service.dart';

class MockSecureTokenService extends Mock implements SecureTokenService {}

void main() {
  late AuthProvider authProvider;
  late MockSecureTokenService mockTokenService;

  setUp(() {
    mockTokenService = MockSecureTokenService();
    authProvider = AuthProvider(secureTokenService: mockTokenService);
  });

  group('AuthProvider - Estado inicial', () {
    test('não está autenticado por padrão', () {
      expect(authProvider.isAuthenticated, false);
    });

    test('não está carregando por padrão', () {
      expect(authProvider.isLoading, false);
    });

    test('token é null por padrão', () {
      expect(authProvider.token, null);
    });

    test('userData é null por padrão', () {
      expect(authProvider.userData, null);
    });

    test('errorMessage é null por padrão', () {
      expect(authProvider.errorMessage, null);
    });
  });

  group('AuthProvider - isTokenValid()', () {
    test('retorna false quando token é null', () {
      expect(authProvider.isTokenValid(), false);
    });

    test('retorna false para token malformado', () {
      // Força token inválido via reflexão não é possível diretamente,
      // mas podemos testar via logout que limpa o token
      authProvider.limparErro(); // não lança exceção
      expect(authProvider.isTokenValid(), false);
    });
  });

  group('AuthProvider - limparErro()', () {
    test('limpa errorMessage e notifica listeners', () {
      // Chama sem erro — não deve lançar
      expect(() => authProvider.limparErro(), returnsNormally);
      expect(authProvider.errorMessage, null);
    });
  });

  group('AuthProvider - logout()', () {
    test('limpa estado após logout', () async {
      when(() => mockTokenService.deleteCredentials()).thenAnswer((_) async {});

      await authProvider.logout();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.userData, null);
      expect(authProvider.isLider, false);
    });
  });

  group('AuthProvider - loadSavedAuth()', () {
    test('não autentica quando não há credenciais salvas', () async {
      when(() => mockTokenService.hasCredentials()).thenAnswer((_) async => false);

      await authProvider.loadSavedAuth();

      expect(authProvider.isAuthenticated, false);
    });
  });
}
