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

  // Rascunhos locais por evento — nunca enviados ao backend até publicar
  final Map<int, List<Escala>> _rascunhosPorEvento = {};

  // Contador regressivo para IDs temporários de rascunho
  // IDs negativos = rascunhos locais; IDs positivos = registros do backend
  int _proximoIdRascunho = -1;

  final String apiUrl = AppConstants.escalasEndpoint;

  List<Escala> get escalas => _escalas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── RASCUNHOS ────────────────────────────────────────────────────────────

  List<Escala> getRascunhos(int eventoId) => _rascunhosPorEvento[eventoId] ?? [];

  /// Lista todos os rascunhos de todos os eventos (útil para badges na UI).
  List<Escala> listarRascunhos() => _rascunhosPorEvento.values.expand((e) => e).toList();

  /// Retorna total de rascunhos pendentes (útil para badge no AppBar).
  int get totalRascunhosPendentes => listarRascunhos().length;

  // ✅ CORRIGIDO: removido 'instrumentoNoEvento', usa copyWith + _proximoIdRascunho
  void adicionarRascunho(Escala escala) {
    final lista = _rascunhosPorEvento.putIfAbsent(escala.eventoId, () => []);
    lista.add(escala.copyWith(id: _proximoIdRascunho--));
    notifyListeners();
  }

  void removerRascunho(int eventoId, int tempId) {
    _rascunhosPorEvento[eventoId]?.removeWhere((e) => e.id == tempId);
    notifyListeners();
  }

  /// Limpa todos os rascunhos de um evento sem publicar (ex: cancelar edição).
  void descartarRascunhos(int eventoId) {
    _rascunhosPorEvento.remove(eventoId);
    notifyListeners();
  }

  Future<bool> publicarEscalas(int eventoId) async {
    final rascunhos = List<Escala>.from(
      _rascunhosPorEvento[eventoId] ?? [],
    );
    if (rascunhos.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final escala in rascunhos) {
        final response = await ApiService.post(apiUrl, body: escala.toJson());
        if (response.statusCode == 201 || response.statusCode == 200) {
          _escalas.add(Escala.fromJson(response.data));
        } else {
          throw _exceptionFromStatus(response.statusCode, 'Falha ao publicar escala');
        }
      }
      _rascunhosPorEvento.remove(eventoId); // limpa após publicar com sucesso
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('publicarEscalas', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

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
      _errorMessage = ErrorHandler.handle(e).message;
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
      _errorMessage = ErrorHandler.handle(e).message;
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
      _errorMessage = ErrorHandler.handle(e).message;
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
      _errorMessage = ErrorHandler.handle(e).message;
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
      _errorMessage = ErrorHandler.handle(e).message;
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
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('buscarEscalasPorMusico $musicoId', e);
      return [];
    }
  }

// lib/controllers/escalas_controller.dart

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
          // ✅ Tenta parsear o response, mas se falhar usa copyWith local
          // Evita crash quando backend retorna musico como nome em vez de ID
          try {
            if (response.data != null && response.data is Map<String, dynamic>) {
              _escalas[index] = Escala.fromJson(response.data as Map<String, dynamic>);
            } else {
              _escalas[index] = _escalas[index].copyWith(confirmado: confirmado);
            }
          } catch (parseError) {
            // Backend retornou formato inesperado (ex: musico como String)
            // Atualiza apenas o campo confirmado localmente
            AppLogger.warning(
              'confirmarPresenca: response inválido, usando fallback local. '
              'Erro: $parseError',
            );
            _escalas[index] = _escalas[index].copyWith(confirmado: confirmado);
          }

          AppLogger.info(
            'Presença ${confirmado ? "confirmada" : "desconfirmada"} '
            'na escala $escalaId',
          );
        }
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Erro ao confirmar presença');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
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

    // ✅ Filtra itens com musico/evento nulos antes de parsear
    final validos = resultsList.where((item) {
      if (item is! Map<String, dynamic>) return false;
      return item['musico'] != null && item['evento'] != null;
    }).toList();

    if (validos.length != resultsList.length) {
      AppLogger.warning(
        '${resultsList.length - validos.length} escalas ignoradas por dados incompletos',
      );
    }

    return validos.map((item) => Escala.fromJson(item as Map<String, dynamic>)).toList();
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
