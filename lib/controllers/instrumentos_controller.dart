import 'package:flutter/material.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';

class InstrumentosProvider extends ChangeNotifier {
  List<Instrumento> _instrumentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Instrumento> get instrumentos => _instrumentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarInstrumentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/instrumentos/', useAuth: true);

      AppLogger.debug('listarInstrumentos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _instrumentos = _parseInstrumentosList(response.data);
        AppLogger.info('${_instrumentos.length} instrumentos carregados');
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        AppLogger.warning(_errorMessage!);
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar instrumentos: $e';
      AppLogger.error('Erro ao listar instrumentos', e, stackTrace);
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
      final response = await ApiService.post('/api/instrumentos/', body: instrumentoData);

      AppLogger.debug('adicionarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final novoInstrumento = Instrumento.fromJson(response.data as Map<String, dynamic>);
        _instrumentos.add(novoInstrumento);
        _instrumentos.sort((a, b) => a.nome.compareTo(b.nome));
        AppLogger.info('Instrumento adicionado: ID ${novoInstrumento.id}');
        notifyListeners();
        return novoInstrumento;
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        AppLogger.warning(_errorMessage!);
        notifyListeners();
        return null;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar instrumento: $e';
      AppLogger.error('Erro ao adicionar instrumento', e, stackTrace);
      notifyListeners();
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
      final response = await ApiService.put('/api/instrumentos/$id/', body: instrumentoData);

      AppLogger.debug('atualizarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Instrumento atualizado: ID $id');
        await listarInstrumentos();
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar instrumento';
        AppLogger.warning(_errorMessage!);
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar instrumento: $e';
      AppLogger.error('Erro ao atualizar instrumento ID $id', e, stackTrace);
      notifyListeners();
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
      final response = await ApiService.delete('/api/instrumentos/$id/');

      AppLogger.debug('deletarInstrumento status: ${response.statusCode}');

      if (response.statusCode == 204) {
        _instrumentos.removeWhere((inst) => inst.id == id);
        AppLogger.info('Instrumento deletado: ID $id');
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao deletar instrumento';
        AppLogger.warning(_errorMessage!);
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar instrumento: $e';
      AppLogger.error('Erro ao deletar instrumento ID $id', e, stackTrace);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Instrumento> _parseInstrumentosList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
    }

    return resultsList.map((json) => Instrumento.fromJson(json as Map<String, dynamic>)).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
