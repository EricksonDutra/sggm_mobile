/// Hierarquia de exceções de domínio do SGGM.
/// Nunca exponha DioException ou mensagens técnicas diretamente ao usuário.
abstract class AppException implements Exception {
  final String message;
  final String? technicalDetails;

  const AppException(this.message, {this.technicalDetails});

  @override
  String toString() => message;
}

/// Sem conexão com a internet ou host inacessível.
class NetworkException extends AppException {
  const NetworkException({String? details})
      : super(
          'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          technicalDetails: details,
        );
}

/// Timeout de conexão ou resposta.
class TimeoutException extends AppException {
  const TimeoutException({String? details})
      : super(
          'O servidor demorou muito para responder. Tente novamente em instantes.',
          technicalDetails: details,
        );
}

/// HTTP 401 — token inválido ou expirado.
class UnauthorizedException extends AppException {
  const UnauthorizedException({String? details})
      : super(
          'Sua sessão expirou. Faça login novamente.',
          technicalDetails: details,
        );
}

/// HTTP 403 — sem permissão para o recurso.
class ForbiddenException extends AppException {
  const ForbiddenException({String? details})
      : super(
          'Você não tem permissão para realizar esta ação.',
          technicalDetails: details,
        );
}

/// HTTP 404 — recurso não encontrado.
class NotFoundException extends AppException {
  const NotFoundException({String? details})
      : super(
          'O item solicitado não foi encontrado.',
          technicalDetails: details,
        );
}

/// HTTP 422 / 400 — dados inválidos enviados ao servidor.
class ValidationException extends AppException {
  final Map<String, dynamic>? fieldErrors;

  const ValidationException({String? details, this.fieldErrors})
      : super(
          'Verifique os dados informados e tente novamente.',
          technicalDetails: details,
        );
}

/// HTTP 5xx — erro interno no servidor.
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({this.statusCode, String? details})
      : super(
          'Ocorreu um erro no servidor. Tente novamente mais tarde.',
          technicalDetails: details,
        );
}

/// Erro desconhecido / não mapeado.
class UnknownException extends AppException {
  const UnknownException({String? details})
      : super(
          'Ocorreu um erro inesperado. Tente novamente.',
          technicalDetails: details,
        );
}
