import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/core/errors/app_exception.dart';

void main() {
  group('AppException - mensagens', () {
    test('NetworkException tem mensagem correta', () {
      const e = NetworkException();
      expect(e.message, contains('internet'));
    });

    test('UnauthorizedException tem mensagem correta', () {
      const e = UnauthorizedException();
      expect(e.message, contains('expirou'));
    });

    test('ServerException tem mensagem correta', () {
      const e = ServerException();
      expect(e.message, contains('servidor'));
    });

    test('ServerException aceita statusCode', () {
      const e = ServerException(statusCode: 503);
      expect(e.statusCode, 503);
    });

    test('ValidationException tem mensagem correta', () {
      const e = ValidationException();
      expect(e.message, contains('dados'));
    });

    test('ValidationException aceita details técnico', () {
      const e = ValidationException(details: 'campo email inválido');
      expect(e.technicalDetails, 'campo email inválido');
    });

    test('NotFoundException tem mensagem correta', () {
      const e = NotFoundException();
      expect(e.message, contains('encontrado'));
    });

    test('TimeoutException tem mensagem correta', () {
      const e = TimeoutException();
      expect(e.message, contains('demorou'));
    });

    test('ForbiddenException tem mensagem correta', () {
      const e = ForbiddenException();
      expect(e.message, contains('permissão'));
    });

    test('UnknownException tem mensagem correta', () {
      const e = UnknownException();
      expect(e.message, contains('inesperado'));
    });
  });
}
