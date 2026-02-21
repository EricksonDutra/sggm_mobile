import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/constants.dart';

class MusicasProvider extends ChangeNotifier {
  List<Musica> _musicas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.musicasEndpoint;

  List<Musica> get musicas => _musicas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> listarMusicas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(apiUrl);

      AppLogger.debug('listarMusicas status: ${response.statusCode}');

      if (response.statusCode! == 200) {
        _musicas = _parseMusicasList(response.data);
        AppLogger.info('${_musicas.length} músicas carregadas');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar músicas: ${e.message}';
      AppLogger.error('Erro ao listar músicas', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar músicas: $e';
      AppLogger.error('Erro ao listar músicas', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarMusica(Musica musica) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(apiUrl, body: musica.toJson());

      AppLogger.debug('adicionarMusica status: ${response.statusCode}');

      if (response.statusCode! == 201 || response.statusCode! == 200) {
        final novaMusica = Musica.fromJson(response.data);
        _musicas.add(novaMusica);
        AppLogger.info('Música adicionada: ID ${novaMusica.id}');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao adicionar música';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar música: ${e.message}';
      AppLogger.error('Erro ao adicionar música', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar música: $e';
      AppLogger.error('Erro ao adicionar música', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarMusica(int id, Musica musica) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.put('$apiUrl$id/', body: musica.toJson());

      AppLogger.debug('atualizarMusica status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _musicas.indexWhere((m) => m.id == id);
        if (index != -1) {
          _musicas[index] = Musica.fromJson(response.data);
          AppLogger.info('Música atualizada: ID $id');
          notifyListeners();
        }
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar música';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar música: ${e.message}';
      AppLogger.error('Erro ao atualizar música ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar música: $e';
      AppLogger.error('Erro ao atualizar música ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletarMusica(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('$apiUrl$id/');

      AppLogger.debug('deletarMusica status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _musicas.removeWhere((m) => m.id == id);
        AppLogger.info('Música deletada: ID $id');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar música';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar música: ${e.message}';
      AppLogger.error('Erro ao deletar música ID $id', e);
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar música: $e';
      AppLogger.error('Erro ao deletar música ID $id', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Musica?> buscarMusica(int id) async {
    try {
      final response = await ApiService.get('$apiUrl$id/');

      AppLogger.debug('buscarMusica status: ${response.statusCode}');

      if (response.statusCode! == 200) {
        final musica = Musica.fromJson(response.data);
        AppLogger.info('Música encontrada: ID $id');
        return musica;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('Erro ao buscar música ID $id', e);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar música ID $id', e, stackTrace);
      return null;
    }
  }

  List<Musica> pesquisarMusicas(String query) {
    if (query.isEmpty) return _musicas;

    final queryLower = query.toLowerCase();
    return _musicas.where((musica) {
      return musica.titulo.toLowerCase().contains(queryLower) || musica.artistaNome.toLowerCase().contains(queryLower);
    }).toList();
  }

  List<Musica> _parseMusicasList(dynamic data) {
    final List<dynamic> resultsList;

    if (data is Map && data.containsKey('results')) {
      resultsList = data['results'] as List<dynamic>;
      AppLogger.debug('Formato paginado — total: ${data['count']}');
    } else if (data is List) {
      resultsList = data;
    } else {
      throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
    }

    return resultsList.map((item) => Musica.fromJson(item as Map<String, dynamic>)).toList();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpar() {
    _musicas = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
