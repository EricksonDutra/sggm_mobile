import 'package:flutter/material.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/services/api_service.dart';

class InstrumentosProvider extends ChangeNotifier {
  List<Instrumento> _instrumentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Instrumento> get instrumentos => _instrumentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listar instrumentos
  Future<void> listarInstrumentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 Listando instrumentos...');

      final response = await ApiService.get(
        '/api/instrumentos/',
        useAuth: true,
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Data type: ${response.data.runtimeType}');
      print('📡 Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ Extrair lista de results (paginação do DRF)
        List<dynamic> resultsList;

        if (data is Map && data.containsKey('results')) {
          resultsList = data['results'] as List<dynamic>;
        } else if (data is List) {
          resultsList = data;
        } else {
          throw Exception('Formato de resposta inesperado: ${data.runtimeType}');
        }

        // ✅ Converter para modelo tipado
        _instrumentos = resultsList.map((json) => Instrumento.fromJson(json as Map<String, dynamic>)).toList();

        print('✅ ${_instrumentos.length} instrumentos carregados');

        // Debug: mostrar instrumentos
        for (var inst in _instrumentos) {
          print('   🎸 ${inst.nome} (ID: ${inst.id})');
        }
      } else {
        _errorMessage = 'Erro ${response.statusCode}: ${response.statusMessage}';
        print('❌ $_errorMessage');
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao listar instrumentos: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NOVO: Adicionar instrumento
  Future<Instrumento?> adicionarInstrumento(Map<String, dynamic> instrumentoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Adicionando instrumento...');
      print('   Dados: $instrumentoData');

      final response = await ApiService.post(
        '/api/instrumentos/',
        body: instrumentoData,
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.data}');

      if (response.statusCode == 201) {
        // ✅ Instrumento criado com sucesso
        final novoInstrumento = Instrumento.fromJson(response.data as Map<String, dynamic>);

        print('✅ Instrumento criado: ${novoInstrumento.nome} (ID: ${novoInstrumento.id})');

        // ✅ Adicionar à lista local
        _instrumentos.add(novoInstrumento);
        _instrumentos.sort((a, b) => a.nome.compareTo(b.nome)); // Ordenar alfabeticamente

        notifyListeners();
        return novoInstrumento;
      } else {
        _errorMessage = 'Erro ${response.statusCode}: ${response.data}';
        print('❌ $_errorMessage');
        notifyListeners();
        return null;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao adicionar instrumento: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NOVO: Atualizar instrumento
  Future<bool> atualizarInstrumento(int id, Map<String, dynamic> instrumentoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Atualizando instrumento $id...');
      print('   Dados: $instrumentoData');

      final response = await ApiService.put(
        '/api/instrumentos/$id/',
        body: instrumentoData,
      );

      if (response.statusCode == 200) {
        print('✅ Instrumento atualizado com sucesso');

        // Recarregar lista
        await listarInstrumentos();
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar instrumento: ${response.data}';
        print('❌ $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao atualizar instrumento: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NOVO: Deletar instrumento
  Future<bool> deletarInstrumento(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deletando instrumento $id...');

      final response = await ApiService.delete('/api/instrumentos/$id/');

      if (response.statusCode == 204) {
        print('✅ Instrumento deletado com sucesso');

        // ✅ Remover da lista local
        _instrumentos.removeWhere((inst) => inst.id == id);

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao deletar instrumento: ${response.data}';
        print('❌ $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Erro ao deletar instrumento: $e';
      print('❌ $_errorMessage');
      print('📍 Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
