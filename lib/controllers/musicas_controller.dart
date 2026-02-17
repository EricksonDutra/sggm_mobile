import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/constants.dart';

class MusicasProvider extends ChangeNotifier {
  List<Musica> _musicas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.musicasEndpoint;

  List<Musica> get musicas => _musicas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listar todas as músicas
  Future<void> listarMusicas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 Listando músicas...');

      final response = await ApiService.get(apiUrl);

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! == 200) {
        final decodedData = response.data;

        print('📡 Data type: ${decodedData.runtimeType}');

        // ✅ Detectar paginação do DRF
        List<dynamic> resultsList;

        if (decodedData is Map && decodedData.containsKey('results')) {
          resultsList = decodedData['results'] as List<dynamic>;
          print('✅ Formato paginado detectado');
          print('   Total: ${decodedData['count']} músicas');
        } else if (decodedData is List) {
          resultsList = decodedData;
          print('✅ Formato lista detectado');
        } else {
          throw Exception('Formato inesperado: ${decodedData.runtimeType}');
        }

        _musicas = resultsList.map((item) => Musica.fromJson(item as Map<String, dynamic>)).toList();

        print('✅ ${_musicas.length} músicas carregadas');

        for (var musica in _musicas) {
          print('   🎵 ${musica.titulo} - ${musica.artistaNome}');
        }

        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode!}: ${response.data}';
        print('❌ $_errorMessage');
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar músicas: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar músicas: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adicionar nova música
  Future<void> adicionarMusica(Musica musica) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Adicionando música...');
      print('   Dados: ${musica.toJson()}');

      final response = await ApiService.post(
        apiUrl,
        body: musica.toJson(),
      );

      print('📡 Status: ${response.statusCode!}');
      print('📡 Response: ${response.data}');

      if (response.statusCode! == 201 || response.statusCode! == 200) {
        final novaMusica = Musica.fromJson(response.data);
        _musicas.add(novaMusica);
        print('✅ Música adicionada: ${novaMusica.titulo}');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao adicionar: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar música: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar música: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar música existente
  Future<void> atualizarMusica(int id, Musica musica) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando música $id...');

      final response = await ApiService.put(
        '$apiUrl$id/',
        body: musica.toJson(),
      );

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _musicas.indexWhere((m) => m.id == id);
        if (index != -1) {
          final musicaAtualizada = Musica.fromJson(response.data);
          _musicas[index] = musicaAtualizada;
          print('✅ Música atualizada: ${musicaAtualizada.titulo}');
          notifyListeners();
        }
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar música: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar música: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar música: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletar música
  Future<void> deletarMusica(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deletando música $id...');

      final response = await ApiService.delete('$apiUrl$id/');

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _musicas.removeWhere((m) => m.id == id);
        print('✅ Música deletada: ID $id');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar música: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar música: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar música: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar música por ID
  Future<Musica?> buscarMusica(int id) async {
    try {
      print('📥 Buscando música $id...');

      final response = await ApiService.get('$apiUrl$id/');

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! == 200) {
        final musica = Musica.fromJson(response.data);
        print('✅ Música encontrada: ${musica.titulo}');
        return musica;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return null;
    } on DioException catch (e) {
      print('❌ Erro ao buscar música: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      return null;
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar música: $e');
      print('📍 $stackTrace');
      return null;
    }
  }

  /// Pesquisar músicas (útil para busca local)
  List<Musica> pesquisarMusicas(String query) {
    if (query.isEmpty) return _musicas;

    final queryLower = query.toLowerCase();
    return _musicas.where((musica) {
      return musica.titulo.toLowerCase().contains(queryLower) || musica.artistaNome.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Limpar mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpar lista (útil no logout)
  void limpar() {
    _musicas = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
