import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar eventos: ${e.message}';
      AppLogger.error('Erro ao listar eventos', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar eventos: $e';
      AppLogger.error('Erro ao listar eventos', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarEvento(Evento evento) async {
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
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao criar evento';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar evento: ${e.message}';
      AppLogger.error('Erro ao adicionar evento', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar evento: $e';
      AppLogger.error('Erro ao adicionar evento', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarEvento(int id, Evento novoEvento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: novoEvento.toJson());

      AppLogger.debug('atualizarEvento status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _eventos.indexWhere((evento) => evento.id == id);
        if (index != -1) {
          _eventos[index] = Evento.fromJson(response.data);
          AppLogger.info('Evento atualizado: ID $id');
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar evento';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar evento: ${e.message}';
      AppLogger.error('Erro ao atualizar evento ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar evento: $e';
      AppLogger.error('Erro ao atualizar evento ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletarEvento(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');

      AppLogger.debug('deletarEvento status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _eventos.removeWhere((evento) => evento.id == id);
        AppLogger.info('Evento deletado: ID $id');
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar evento';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar evento: ${e.message}';
      AppLogger.error('Erro ao deletar evento ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar evento: $e';
      AppLogger.error('Erro ao deletar evento ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarRepertorio(int eventoId, List<int> musicaIds) async {
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
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar setlist';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar repertório: ${e.message}';
      AppLogger.error('Erro ao atualizar repertório do evento $eventoId', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar repertório: $e';
      AppLogger.error('Erro ao atualizar repertório do evento $eventoId', e, stackTrace);
      rethrow;
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
        final evento = Evento.fromJson(response.data);
        AppLogger.info('Evento encontrado: ID $id');
        return evento;
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('Erro ao buscar evento ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar evento ID $id', e, stackTrace);
      rethrow;
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
      throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
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
