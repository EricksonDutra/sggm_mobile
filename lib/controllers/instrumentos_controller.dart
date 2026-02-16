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

  /// Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
