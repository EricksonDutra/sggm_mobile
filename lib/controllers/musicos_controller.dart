import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/models/musicos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/constants.dart';

class MusicosProvider extends ChangeNotifier {
  List<Musico> _musicos = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.musicosEndpoint;

  List<Musico> get musicos => _musicos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listar todos os músicos
  Future<void> listarMusicos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 Listando músicos...');

      final response = await ApiService.get(apiUrl);

      print('📡 Status: ${response.statusCode}');
      print('📡 Data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ Detectar paginação do DRF
        List<dynamic> resultsList;

        if (data is Map && data.containsKey('results')) {
          resultsList = data['results'] as List<dynamic>;
          print('✅ Formato paginado detectado');
          print('   Total: ${data['count']} músicos');
        } else if (data is List) {
          resultsList = data;
          print('✅ Formato lista detectado');
        } else {
          throw Exception('Formato inesperado: ${data.runtimeType}');
        }

        _musicos = resultsList.map((json) => Musico.fromJson(json as Map<String, dynamic>)).toList();

        print('✅ ${_musicos.length} músicos carregados');

        for (var musico in _musicos) {
          print('   👤 ${musico.nome} - ${musico.email}');
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}: ${response.statusMessage}';
        print('❌ $_errorMessage');
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar músicos: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar músicos: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar músico por ID
  Future<Musico?> buscarMusico(int id) async {
    try {
      print('📥 Buscando músico $id...');

      final response = await ApiService.get('$apiUrl$id/');

      if (response.statusCode == 200) {
        print('✅ Músico encontrado');
        return Musico.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      } else {
        print('❌ Erro ao buscar músico: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('❌ Erro ao buscar músico: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar músico: $e');
      return null;
    }
  }

  /// Adicionar novo músico
  Future<bool> adicionarMusico(Map<String, dynamic> musicoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Adicionando músico...');
      print('   Dados: $musicoData');

      final response = await ApiService.post(
        apiUrl,
        body: musicoData,
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Músico adicionado com sucesso');
        await listarMusicos(); // Recarregar lista
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        return false;
      } else {
        _errorMessage = 'Erro ao adicionar músico: ${response.data}';
        print('❌ $_errorMessage');
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar músico: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar músico: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar músico existente
  Future<bool> atualizarMusico(int id, Map<String, dynamic> musicoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando músico $id...');
      print('   Dados: $musicoData');

      final response = await ApiService.put(
        '$apiUrl$id/',
        body: musicoData,
      );

      if (response.statusCode == 200) {
        print('✅ Músico atualizado com sucesso');
        await listarMusicos(); // Recarregar lista
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        return false;
      } else {
        _errorMessage = 'Erro ao atualizar músico: ${response.data}';
        print('❌ $_errorMessage');
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar músico: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar músico: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletar músico
  Future<bool> deletarMusico(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deletando músico $id...');

      final response = await ApiService.delete('$apiUrl$id/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Músico deletado com sucesso');

        // Remover da lista local
        _musicos.removeWhere((musico) => musico.id == id);
        notifyListeners();

        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        return false;
      } else {
        _errorMessage = 'Erro ao deletar músico: ${response.data}';
        print('❌ $_errorMessage');
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar músico: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar músico: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpar mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpar lista (útil no logout)
  void limpar() {
    _musicos = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
