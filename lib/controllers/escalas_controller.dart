import 'package:flutter/material.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class EscalasProvider extends ChangeNotifier {
  List<Escala> _escalas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.escalasEndpoint;

  List<Escala> get escalas => _escalas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarEscalas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(apiUrl);
      AppLogger.debug('listarEscalas status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _escalas = _parseEscalasList(response.data);
        AppLogger.info('${_escalas.length} escalas carregadas');
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao listar escalas');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('listarEscalas', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adicionarEscala(Escala escala) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: escala.toJson());
      AppLogger.debug('adicionarEscala status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final novaEscala = Escala.fromJson(response.data);
        _escalas.add(novaEscala);
        AppLogger.info('Escala adicionada: ID ${novaEscala.id}');
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao criar escala');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('adicionarEscala', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarEscala(int id, Escala escala) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: escala.toJson());
      AppLogger.debug('atualizarEscala status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _escalas.indexWhere((e) => e.id == id);
        if (index != -1) {
          _escalas[index] = Escala.fromJson(response.data);
          AppLogger.info('Escala atualizada: ID $id');
        }
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao atualizar escala');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('atualizarEscala $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletarEscala(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');
      AppLogger.debug('deletarEscala status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _escalas.removeWhere((escala) => escala.id == id);
        AppLogger.info('Escala deletada: ID $id');
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao deletar escala');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('deletarEscala $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Escala>> buscarEscalasPorEvento(int eventoId) async {
    try {
      final response = await ApiService.get('$apiUrl?evento=$eventoId');
      AppLogger.debug('buscarEscalasPorEvento status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final escalas = _parseEscalasList(response.data);
        AppLogger.debug('${escalas.length} escalas encontradas para evento $eventoId');
        return escalas;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao buscar escalas do evento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('buscarEscalasPorEvento $eventoId', e);
      return [];
    }
  }

  Future<List<Escala>> buscarEscalasPorMusico(int musicoId) async {
    try {
      final response = await ApiService.get('$apiUrl?musico=$musicoId');
      AppLogger.debug('buscarEscalasPorMusico status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final escalas = _parseEscalasList(response.data);
        AppLogger.debug('${escalas.length} escalas encontradas para músico $musicoId');
        return escalas;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao buscar escalas do músico');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('buscarEscalasPorMusico $musicoId', e);
      return [];
    }
  }

  Future<bool> confirmarPresenca(int escalaId, bool confirmado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '$apiUrl$escalaId/confirmar/',
        body: {'confirmado': confirmado},
      );
      AppLogger.debug('confirmarPresenca status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _escalas.indexWhere((e) => e.id == escalaId);
        if (index != -1) {
          final escalaAtual = _escalas[index];
          _escalas[index] = Escala(
            id: escalaAtual.id,
            musicoNome: escalaAtual.musicoNome,
            musicoId: escalaAtual.musicoId,
            eventoNome: escalaAtual.eventoNome,
            instrumentoNoEvento: escalaAtual.instrumentoNoEvento,
            confirmado: confirmado,
            criadoEm: escalaAtual.criadoEm,
            eventoId: escalaAtual.eventoId,
          );
          AppLogger.info('Presença ${confirmado ? "confirmada" : "desconfirmada"} na escala $escalaId');
        }
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao confirmar presença');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('confirmarPresenca $escalaId', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  AppException _exceptionFromStatus(int? statusCode, String fallback) {
    switch (statusCode) {
      case 401:
        return const UnauthorizedException();
      case 403:
        return const ForbiddenException();
      case 404:
        return const NotFoundException();
      case 422:
        return const ValidationException();
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(statusCode: statusCode);
        }
        return UnknownException(details: '$fallback (HTTP $statusCode)');
    }
  }

  List<Escala> _parseEscalasList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw UnknownException(details: 'Formato inesperado: ${data.runtimeType}');
    }

    return resultsList.map((item) => Escala.fromJson(item as Map<String, dynamic>)).toList();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpar() {
    _escalas = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
