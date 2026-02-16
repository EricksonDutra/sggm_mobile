import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/constants.dart';

class EventoProvider with ChangeNotifier {
  List<Evento> _eventos = [];
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = AppConstants.eventosEndpoint;

  List<Evento> get eventos => _eventos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listar todos os eventos
  Future<void> listarEventos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 Listando eventos...');
      print('🌐 URL: $apiUrl');

      final response = await ApiService.get(apiUrl);

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = response.data;

        print('📡 Data type: ${decodedData.runtimeType}');

        // ✅ Detectar paginação do DRF
        List<dynamic> resultsList;

        if (decodedData is Map && decodedData.containsKey('results')) {
          resultsList = decodedData['results'] as List<dynamic>;
          print('✅ Formato paginado detectado');
          print('   Total: ${decodedData['count']} eventos');
        } else if (decodedData is List) {
          resultsList = decodedData;
          print('✅ Formato lista detectado');
        } else {
          throw Exception('Formato inesperado: ${decodedData.runtimeType}');
        }

        _eventos = resultsList.map((item) => Evento.fromJson(item as Map<String, dynamic>)).toList();

        print('✅ ${_eventos.length} eventos carregados');

        for (var evento in _eventos) {
          print('   📅 ${evento.nome} - ${evento.dataEvento}');
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Erro ${response.statusCode}';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao listar eventos: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar eventos: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adicionar novo evento
  Future<void> adicionarEvento(Evento evento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Adicionando evento...');

      final response = await ApiService.post(
        apiUrl,
        body: evento.toJson(),
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final novo = Evento.fromJson(response.data);
        _eventos.add(novo);
        print('✅ Evento adicionado: ${novo.nome}');
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao criar evento: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao adicionar evento: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar evento: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar evento existente
  Future<void> atualizarEvento(int id, Evento novoEvento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando evento $id...');

      final response = await ApiService.put(
        '$apiUrl$id/',
        body: novoEvento.toJson(),
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        final index = _eventos.indexWhere((evento) => evento.id == id);
        if (index != -1) {
          final eventoAtualizado = Evento.fromJson(response.data);
          _eventos[index] = eventoAtualizado;
          print('✅ Evento atualizado: ${eventoAtualizado.nome}');
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar evento: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar evento: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar evento: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletar evento
  Future<void> deletarEvento(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deletando evento $id...');

      final response = await ApiService.delete('$apiUrl$id/');

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        _eventos.removeWhere((evento) => evento.id == id);
        print('✅ Evento deletado');
        notifyListeners();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao deletar evento: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao deletar evento: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar evento: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar repertório de um evento
  Future<void> atualizarRepertorio(int eventoId, List<int> musicaIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando repertório do evento $eventoId...');
      print('   Músicas: $musicaIds');

      final response = await ApiService.post(
        '$apiUrl$eventoId/adicionar_repertorio/',
        body: {'musicas': musicaIds},
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! <= 299) {
        print('✅ Repertório atualizado');
        await listarEventos();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Não autorizado. Faça login novamente.';
        print('❌ $_errorMessage');
        print('📡 Response: ${response.data}');
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Falha ao atualizar setlist: ${response.data}';
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _errorMessage = 'Erro ao atualizar repertório: ${e.message}';
      print('❌ $_errorMessage');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar repertório: $e';
      print('❌ $_errorMessage');
      print('📍 $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar um evento específico por ID
  Future<Evento?> buscarEvento(int id) async {
    try {
      print('📥 Buscando evento $id...');

      final response = await ApiService.get('$apiUrl$id/');

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final evento = Evento.fromJson(response.data);
        print('✅ Evento encontrado: ${evento.nome}');
        return evento;
      } else if (response.statusCode == 401) {
        print('❌ Não autorizado ao buscar evento');
        print('📡 Response: ${response.data}');
        throw Exception('Não autorizado. Faça login novamente.');
      }
      return null;
    } on DioException catch (e) {
      print('❌ Erro ao buscar evento: ${e.message}');
      print('📝 Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar evento: $e');
      print('📍 $stackTrace');
      rethrow;
    }
  }

  /// Limpar mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpar lista (útil no logout)
  void limpar() {
    _eventos = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
