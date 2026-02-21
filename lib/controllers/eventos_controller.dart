import 'package:flutter/material.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class EventoProvider with ChangeNotifier {
  List<Evento> _eventos = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.eventosEndpoint;

  List<Evento> get eventos => _eventos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarEventos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(apiUrl);
      AppLogger.debug('listarEventos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _eventos = _parseEventosList(response.data);
        AppLogger.info('${_eventos.length} eventos carregados');
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao listar eventos');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('listarEventos', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adicionarEvento(Evento evento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: evento.toJson());
      AppLogger.debug('adicionarEvento status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final novo = Evento.fromJson(response.data);
        _eventos.add(novo);
        AppLogger.info('Evento adicionado: ID ${novo.id}');
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao criar evento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('adicionarEvento', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarEvento(int id, Evento novoEvento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: novoEvento.toJson());
      AppLogger.debug('atualizarEvento status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _eventos.indexWhere((e) => e.id == id);
        if (index != -1) {
          _eventos[index] = Evento.fromJson(response.data);
          AppLogger.info('Evento atualizado: ID $id');
        }
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao atualizar evento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('atualizarEvento $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletarEvento(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');
      AppLogger.debug('deletarEvento status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _eventos.removeWhere((e) => e.id == id);
        AppLogger.info('Evento deletado: ID $id');
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao deletar evento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('deletarEvento $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarRepertorio(int eventoId, List<int> musicaIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '$apiUrl$eventoId/adicionar_repertorio/',
        body: {'musicas': musicaIds},
      );
      AppLogger.debug('atualizarRepertorio status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        AppLogger.info('Repertório do evento $eventoId atualizado');
        await listarEventos();
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao atualizar setlist');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('atualizarRepertorio $eventoId', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Evento?> buscarEvento(int id) async {
    try {
      final response = await ApiService.get('$apiUrl$id/');
      AppLogger.debug('buscarEvento status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Evento encontrado: ID $id');
        return Evento.fromJson(response.data);
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Evento não encontrado');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('buscarEvento $id', e);
      return null;
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

  List<Evento> _parseEventosList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw UnknownException(details: 'Formato inesperado: ${data.runtimeType}');
    }

    return resultsList.map((item) => Evento.fromJson(item as Map<String, dynamic>)).toList();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpar() {
    _eventos = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
