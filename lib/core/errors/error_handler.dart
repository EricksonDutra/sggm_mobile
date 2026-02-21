import 'package:dio/dio.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/util/app_logger.dart';

/// Converte qualquer exceção em uma [AppException] com mensagem amigável.
/// Use em todos os blocos catch dos controllers.
///
/// Exemplo:
/// ```dart
/// } on DioException catch (e) {
///   throw ErrorHandler.handle(e);
/// } catch (e) {
///   throw ErrorHandler.handle(e);
/// }
/// ```
class ErrorHandler {
  ErrorHandler._();

  /// Mapeia [error] para a [AppException] correspondente.
  /// Se já for uma [AppException], retorna sem transformar.
  static AppException handle(Object error) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _handleDioException(error);
    }

    AppLogger.error('Erro não mapeado', error);
    return UnknownException(details: error.toString());
  }

  static AppException _handleDioException(DioException e) {
    AppLogger.error('DioException [${e.type}]', e);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(details: e.message);

      case DioExceptionType.connectionError:
        return NetworkException(details: e.message);

      case DioExceptionType.badResponse:
        return _handleHttpResponse(e);

      case DioExceptionType.cancel:
        return const UnknownException(details: 'Requisição cancelada');

      case DioExceptionType.unknown:
      default:
        // Verifica se é um erro de rede por baixo (ex: SocketException)
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('socketexception') ||
            msg.contains('failed host lookup') ||
            msg.contains('network is unreachable')) {
          return NetworkException(details: e.message);
        }
        return UnknownException(details: e.message);
    }
  }

  static AppException _handleHttpResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final details = 'HTTP $statusCode — ${e.response?.data}';

    switch (statusCode) {
      case 400:
        return ValidationException(
          details: details,
          fieldErrors: e.response?.data is Map<String, dynamic> ? e.response!.data as Map<String, dynamic> : null,
        );
      case 401:
        return UnauthorizedException(details: details);
      case 403:
        return ForbiddenException(details: details);
      case 404:
        return NotFoundException(details: details);
      case 422:
        return ValidationException(details: details);
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(statusCode: statusCode, details: details);
        }
        return UnknownException(details: details);
    }
  }
}
