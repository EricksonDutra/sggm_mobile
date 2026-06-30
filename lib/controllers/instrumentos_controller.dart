import 'package:flutter/material.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class InstrumentosProvider extends ChangeNotifier {
  List<Instrumento> _instrumentos = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String apiUrl = AppConstants.instrumentosEndpoint;

  List<Instrumento> get instrumentos => _instrumentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarInstrumentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(apiUrl);
      AppLogger.debug('listarInstrumentos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _instrumentos = _parseInstrumentosList(response.data);
        AppLogger.info('${_instrumentos.length} instrumentos carregados');
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Erro ao listar instrumentos');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('listarInstrumentos', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Instrumento?> adicionarInstrumento(Map<String, dynamic> instrumentoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: instrumentoData);
      AppLogger.debug('adicionarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final novoInstrumento = Instrumento.fromJson(response.data as Map<String, dynamic>);
        _instrumentos.add(novoInstrumento);
        _instrumentos.sort((a, b) => a.nome.compareTo(b.nome));
        AppLogger.info('Instrumento adicionado: ID ${novoInstrumento.id}');
        return novoInstrumento;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao criar instrumento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('adicionarInstrumento', e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarInstrumento(int id, Map<String, dynamic> instrumentoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: instrumentoData);
      AppLogger.debug('atualizarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final atualizado = Instrumento.fromJson(response.data as Map<String, dynamic>);
        final index = _instrumentos.indexWhere((i) => i.id == id);
        if (index != -1) _instrumentos[index] = atualizado;
        _instrumentos.sort((a, b) => a.nome.compareTo(b.nome));
        AppLogger.info('Instrumento atualizado: ID $id');
        return true;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao atualizar instrumento');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('atualizarInstrumento $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletarInstrumento(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');
      AppLogger.debug('deletarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 204) {
        _instrumentos.removeWhere((inst) => inst.id == id);
        AppLogger.info('Instrumento deletado: ID $id');
        return true;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao deletar instrumento');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('deletarInstrumento $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────



  List<Instrumento> _parseInstrumentosList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw UnknownException(details: 'Formato inesperado: ${data.runtimeType}');
    }

    return resultsList.map((instrumentoJson) => Instrumento.fromJson(instrumentoJson as Map<String, dynamic>)).toList();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
