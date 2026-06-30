import 'package:flutter/material.dart';
import 'package:sggm/core/errors/app_exception.dart';
import 'package:sggm/core/errors/error_handler.dart';
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

      if (response.statusCode == 200) {
        _musicas = _parseMusicasList(response.data);
        AppLogger.info('${_musicas.length} músicas carregadas');
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Erro ao listar músicas');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('listarMusicas', e);
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        final novaMusica = Musica.fromJson(response.data);
        _musicas.add(novaMusica);
        AppLogger.info('Música adicionada: ID ${novaMusica.id}');
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao adicionar música');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('adicionarMusica', e);
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
        }
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao atualizar música');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('atualizarMusica $id', e);
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
      } else {
        throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Falha ao deletar música');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      AppLogger.error('deletarMusica $id', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Musica?> buscarMusica(int id) async {
    try {
      final response = await ApiService.get('$apiUrl$id/');
      AppLogger.debug('buscarMusica status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final musica = Musica.fromJson(response.data);
        AppLogger.info('Música encontrada: ID $id');
        return musica;
      }
      throw ErrorHandler.fromStatusCode(response.statusCode, fallback: 'Erro ao buscar música');
    } catch (e) {
      AppLogger.error('buscarMusica $id', e);
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
      throw UnknownException(details: 'Formato inesperado: ${data.runtimeType}');
    }

    return resultsList.map((musicaJson) => Musica.fromJson(musicaJson as Map<String, dynamic>)).toList();
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
