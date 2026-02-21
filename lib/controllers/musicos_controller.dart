import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar músicos: ${e.message}';
      AppLogger.error('Erro ao listar músicos', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar músicos: $e';
      AppLogger.error('Erro ao listar músicos', e, stackTrace);
      rethrow;
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
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('Erro ao buscar músico ID $id', e);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar músico ID $id', e, stackTrace);
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
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        return false;
      } else {
        _errorMessage = 'Erro ao adicionar músico';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar músico: ${e.message}';
      AppLogger.error('Erro ao adicionar músico', e);
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar músico: $e';
      AppLogger.error('Erro ao adicionar músico', e, stackTrace);
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
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        return false;
      } else {
        _errorMessage = 'Erro ao atualizar músico';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar músico: ${e.message}';
      AppLogger.error('Erro ao atualizar músico ID $id', e);
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar músico: $e';
      AppLogger.error('Erro ao atualizar músico ID $id', e, stackTrace);
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
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        return false;
      } else {
        _errorMessage = 'Erro ao deletar músico';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar músico: ${e.message}';
      AppLogger.error('Erro ao deletar músico ID $id', e);
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar músico: $e';
      AppLogger.error('Erro ao deletar músico ID $id', e, stackTrace);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
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
