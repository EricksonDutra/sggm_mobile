import 'package:flutter/material.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';
import 'package:sggm/models/musicos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class MusicosProvider extends ChangeNotifier {
  List<Musico> _musicos = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.musicosEndpoint;

  List<Musico> get musicos => _musicos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarMusicos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(apiUrl);
      AppLogger.debug('listarMusicos status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _musicos = _parseMusicosList(response.data);
        AppLogger.info('${_musicos.length} músicos carregados');
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Erro ao listar músicos');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('listarMusicos', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Musico?> buscarMusico(int id) async {
    try {
      final response = await ApiService.get('$apiUrl$id/');
      AppLogger.debug('buscarMusico status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Músico encontrado: ID $id');
        return Musico.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Músico não encontrado');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('buscarMusico $id', e);
      return null;
    }
  }

  Future<bool> adicionarMusico(Map<String, dynamic> musicoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: musicoData);
      AppLogger.debug('adicionarMusico status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final novoMusico = Musico.fromJson(response.data as Map<String, dynamic>);
        _musicos.add(novoMusico);
        AppLogger.info('Músico adicionado: ID ${novoMusico.id}');
        return true;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao adicionar músico');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('adicionarMusico', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarMusico(int id, Map<String, dynamic> musicoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: musicoData);
      AppLogger.debug('atualizarMusico status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final index = _musicos.indexWhere((m) => m.id == id);
        if (index != -1) {
          _musicos[index] = Musico.fromJson(response.data as Map<String, dynamic>);
        }
        AppLogger.info('Músico atualizado: ID $id');
        return true;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao atualizar músico');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('atualizarMusico $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletarMusico(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');
      AppLogger.debug('deletarMusico status: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        _musicos.removeWhere((musico) => musico.id == id);
        AppLogger.info('Músico deletado: ID $id');
        return true;
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao deletar músico');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;

      AppLogger.error('deletarMusico $id', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  List<Musico> _parseMusicosList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw UnknownException(details: 'Formato inesperado: ${data.runtimeType}');
    }

    return resultsList.map((musicoJson) => Musico.fromJson(musicoJson as Map<String, dynamic>)).toList();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpar() {
    _musicos = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
