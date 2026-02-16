import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/constants.dart';

class EscalasProvider extends ChangeNotifier {
  List<Escala> _escalas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.escalasEndpoint;

  List<Escala> get escalas => _escalas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listar todas as escalas
  Future<void> listarEscalas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 Listando escalas...');

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
          print('   Total: ${decodedData['count']} escalas');
        } else if (decodedData is List) {
          resultsList = decodedData;
          print('✅ Formato lista detectado');
        } else {
          throw Exception('Formato inesperado: ${decodedData.runtimeType}');
        }

        _escalas = resultsList.map((item) => Escala.fromJson(item as Map<String, dynamic>)).toList();

        print('✅ ${_escalas.length} escalas carregadas');

        for (var escala in _escalas) {
          print('   📋 Escala ID ${escala.id}');
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
      _errorMessage = 'Erro ao listar escalas: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar escalas: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adicionar nova escala
  Future<void> adicionarEscala(Escala escala) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Adicionando escala...');
      print('   Dados: ${escala.toJson()}');

      final response = await ApiService.post(
        apiUrl,
        body: escala.toJson(),
      );

      print('📡 Status: ${response.statusCode!}');
      print('📡 Response: ${response.data}');

      if (response.statusCode! == 201 || response.statusCode! == 200) {
        final novaEscala = Escala.fromJson(response.data);
        _escalas.add(novaEscala);
        print('✅ Escala adicionada: ID ${novaEscala.id}');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao criar escala: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar escala: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar escala: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar escala existente
  Future<void> atualizarEscala(int id, Escala escala) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando escala $id...');

      final response = await ApiService.put(
        '$apiUrl$id/',
        body: escala.toJson(),
      );

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _escalas.indexWhere((e) => e.id == id);
        if (index != -1) {
          final escalaAtualizada = Escala.fromJson(response.data);
          _escalas[index] = escalaAtualizada;
          print('✅ Escala atualizada: ID $id');
          notifyListeners();
        }
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar escala: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar escala: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar escala: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletar escala
  Future<void> deletarEscala(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deletando escala $id...');

      final response = await ApiService.delete('$apiUrl$id/');

      print('📡 Status: ${response.statusCode!}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _escalas.removeWhere((escala) => escala.id == id);
        print('✅ Escala deletada: ID $id');
        notifyListeners();
      } else if (response.statusCode! == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar escala: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar escala: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar escala: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar escalas de um evento específico
  Future<List<Escala>> buscarEscalasPorEvento(int eventoId) async {
    try {
      print('📥 Buscando escalas do evento $eventoId...');

      final response = await ApiService.get('$apiUrl?evento=$eventoId');

      if (response.statusCode! == 200) {
        final decodedData = response.data;

        List<dynamic> resultsList;

        if (decodedData is Map && decodedData.containsKey('results')) {
          resultsList = decodedData['results'] as List<dynamic>;
        } else if (decodedData is List) {
          resultsList = decodedData;
        } else {
          throw Exception('Formato inesperado');
        }

        final escalas = resultsList.map((item) => Escala.fromJson(item as Map<String, dynamic>)).toList();

        print('✅ ${escalas.length} escalas encontradas');
        return escalas;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return [];
    } on DioException catch (e) {
      print('❌ Erro ao buscar escalas do evento: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar escalas do evento: $e');
      print('📍 $stackTrace');
      return [];
    }
  }

  /// Buscar escalas de um músico específico
  Future<List<Escala>> buscarEscalasPorMusico(int musicoId) async {
    try {
      print('📥 Buscando escalas do músico $musicoId...');

      final response = await ApiService.get('$apiUrl?musico=$musicoId');

      if (response.statusCode! == 200) {
        final decodedData = response.data;

        List<dynamic> resultsList;

        if (decodedData is Map && decodedData.containsKey('results')) {
          resultsList = decodedData['results'] as List<dynamic>;
        } else if (decodedData is List) {
          resultsList = decodedData;
        } else {
          throw Exception('Formato inesperado');
        }

        final escalas = resultsList.map((item) => Escala.fromJson(item as Map<String, dynamic>)).toList();

        print('✅ ${escalas.length} escalas encontradas');
        return escalas;
      } else if (response.statusCode! == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return [];
    } on DioException catch (e) {
      print('❌ Erro ao buscar escalas do músico: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar escalas do músico: $e');
      print('📍 $stackTrace');
      return [];
    }
  }

  /// Limpar mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpar lista (útil no logout)
  void limpar() {
    _escalas = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
