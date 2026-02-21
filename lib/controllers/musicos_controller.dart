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
        throw _exceptionFromStatus(response.statusCode, 'Erro ao listar músicos');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
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
        throw _exceptionFromStatus(response.statusCode, 'Músico não encontrado');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
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
        AppLogger.info('Músico adicionado com sucesso');
        await listarMusicos();
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao adicionar músico');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
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
        AppLogger.info('Músico atualizado: ID $id');
        await listarMusicos();
        return true;
      } else {
        throw _exceptionFromStatus(response.statusCode, 'Falha ao atualizar músico');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
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
        throw _exceptionFromStatus(response.statusCode, 'Falha ao deletar músico');
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      _errorMessage = appException.message;
      AppLogger.error('deletarMusico $id', e);
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

    return resultsList.map((json) => Musico.fromJson(json as Map<String, dynamic>)).toList();
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
