import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/util/validators.dart';

void main() {
  group('Validators - validateEmail()', () {
    test('email válido retorna null', () {
      expect(Validators.validateEmail('teste@email.com'), null);
    });

    test('email vazio retorna mensagem', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('email sem @ retorna mensagem', () {
      expect(Validators.validateEmail('emailsemarroba'), isNotNull);
    });

    test('null retorna mensagem', () {
      expect(Validators.validateEmail(null), isNotNull);
    });
  });

  group('Validators - validateRequired()', () {
    test('valor preenchido retorna null', () {
      expect(Validators.validateRequired('João', 'Nome'), null);
    });

    test('valor vazio retorna mensagem', () {
      expect(Validators.validateRequired('', 'Nome'), isNotNull);
    });

    test('só espaços retorna mensagem', () {
      expect(Validators.validateRequired('   ', 'Nome'), isNotNull);
    });
  });

  group('Validators - validatePassword()', () {
    test('senha válida retorna null', () {
      expect(Validators.validatePassword('test-value-ok'), null);
    });

    test('senha curta retorna mensagem', () {
      expect(Validators.validatePassword('abc'), isNotNull);
    });

    test('senha vazia retorna mensagem', () {
      expect(Validators.validatePassword(''), isNotNull);
    });
  });
}
