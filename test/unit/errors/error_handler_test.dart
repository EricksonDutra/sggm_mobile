import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler - DioException', () {
    test('connectionError retorna NetworkException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final result = ErrorHandler.handle(error);
      expect(result, isA<NetworkException>());
    });

    test('connectionTimeout retorna TimeoutException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final result = ErrorHandler.handle(error);
      expect(result, isA<TimeoutException>());
    });

    test('status 401 retorna UnauthorizedException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );
      final result = ErrorHandler.handle(error);
      expect(result, isA<UnauthorizedException>());
    });

    test('status 404 retorna NotFoundException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );
      final result = ErrorHandler.handle(error);
      expect(result, isA<NotFoundException>());
    });

    test('status 500 retorna ServerException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );
      final result = ErrorHandler.handle(error);
      expect(result, isA<ServerException>());
    });

    test('erro genérico retorna UnknownException', () {
      final result = ErrorHandler.handle(Exception('erro genérico'));
      expect(result, isA<UnknownException>());
    });

    test('AppException passada diretamente é retornada sem transformação', () {
      const original = NetworkException();
      final result = ErrorHandler.handle(original);
      expect(result, same(original));
    });
  });
}
