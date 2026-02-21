import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

      if (response.statusCode! == 200) {
        _escalas = _parseEscalasList(response.data);
        AppLogger.info('${_escalas.length} escalas carregadas');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar escalas: ${e.message}';
      AppLogger.error('Erro ao listar escalas', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar escalas: $e';
      AppLogger.error('Erro ao listar escalas', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarEscala(Escala escala) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: escala.toJson());

      AppLogger.debug('adicionarEscala status: ${response.statusCode}');

      if (response.statusCode! == 201 || response.statusCode! == 200) {
        final novaEscala = Escala.fromJson(response.data);
        _escalas.add(novaEscala);
        AppLogger.info('Escala adicionada: ID ${novaEscala.id}');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao criar escala';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar escala: ${e.message}';
      AppLogger.error('Erro ao adicionar escala', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar escala: $e';
      AppLogger.error('Erro ao adicionar escala', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarEscala(int id, Escala escala) async {
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
          notifyListeners();
        }
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar escala';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar escala: ${e.message}';
      AppLogger.error('Erro ao atualizar escala ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar escala: $e';
      AppLogger.error('Erro ao atualizar escala ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletarEscala(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');

      AppLogger.debug('deletarEscala status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _escalas.removeWhere((escala) => escala.id == id);
        AppLogger.info('Escala deletada: ID $id');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar escala';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar escala: ${e.message}';
      AppLogger.error('Erro ao deletar escala ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar escala: $e';
      AppLogger.error('Erro ao deletar escala ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Escala>> buscarEscalasPorEvento(int eventoId) async {
    try {
      final response = await ApiService.get('$apiUrl?evento=$eventoId');

      if (response.statusCode! == 200) {
        final escalas = _parseEscalasList(response.data);
        AppLogger.debug('${escalas.length} escalas encontradas para evento $eventoId');
        return escalas;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('Erro ao buscar escalas do evento $eventoId', e);
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar escalas do evento $eventoId', e, stackTrace);
      return [];
    }
  }

  Future<List<Escala>> buscarEscalasPorMusico(int musicoId) async {
    try {
      final response = await ApiService.get('$apiUrl?musico=$musicoId');

      if (response.statusCode! == 200) {
        final escalas = _parseEscalasList(response.data);
        AppLogger.debug('${escalas.length} escalas encontradas para músico $musicoId');
        return escalas;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('Erro ao buscar escalas do músico $musicoId', e);
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar escalas do músico $musicoId', e, stackTrace);
      return [];
    }
  }

  Future<void> confirmarPresenca(int escalaId, bool confirmado) async {
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
        notifyListeners();
      } else {
        _errorMessage = 'Erro ao confirmar presença';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao confirmar presença: ${e.message}';
      AppLogger.error('Erro ao confirmar presença na escala $escalaId', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao confirmar presença: $e';
      AppLogger.error('Erro ao confirmar presença na escala $escalaId', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
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
