import 'package:sggm/models/comentario.dart';
import 'package:sggm/services/api_service.dart';

class ComentarioService {
  static const String _base = '/api/comentarios/';

  static Future<List<ComentarioPerformance>> listarPorEvento(int eventoId) async {
    final response = await ApiService.get(
      _base,
      queryParameters: {'evento': eventoId},
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final List items = data is Map ? data['results'] ?? [] : data;
      return items.map((e) => ComentarioPerformance.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar comentários');
  }

  // ← recebe eventoId E musicaId para filtrar corretamente
  static Future<List<ComentarioPerformance>> listarPorMusica(
    int eventoId,
    int musicaId,
  ) async {
    final response = await ApiService.get(
      _base,
      queryParameters: {
        'evento': eventoId,
        'musica': musicaId,
      },
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final List items = data is Map ? data['results'] ?? [] : data;
      return items.map((e) => ComentarioPerformance.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar comentários');
  }

  static Future<ComentarioPerformance> criar({
    required int eventoId,
    int? musicaId,
    required String texto,
  }) async {
    final response = await ApiService.post(
      _base,
      body: {
        'evento': eventoId,
        if (musicaId != null) 'musica': musicaId,
        'texto': texto,
      },
    );

    if (response.statusCode == 201) {
      return ComentarioPerformance.fromJson(response.data);
    }

    // ── Extrair mensagem de erro do DRF ──
    final data = response.data;
    String mensagem = 'Erro ao criar comentário';

    if (data is Map) {
      if (data.containsKey('detail')) {
        mensagem = data['detail'].toString();
      } else if (data.containsKey('non_field_errors')) {
        final erros = data['non_field_errors'];
        if (erros is List && erros.isNotEmpty) {
          mensagem = erros.first.toString();
        }
      } else {
        for (final valor in data.values) {
          if (valor is List && valor.isNotEmpty) {
            mensagem = valor.first.toString();
            break;
          } else if (valor is String) {
            mensagem = valor;
            break;
          }
        }
      }
    } else if (data is List && data.isNotEmpty) {
      mensagem = data.first.toString();
    }

    throw Exception(mensagem);
  }

  static Future<ComentarioPerformance> editar(int id, String novoTexto) async {
    final response = await ApiService.patch(
      '$_base$id/',
      body: {'texto': novoTexto},
    );
    if (response.statusCode == 200) {
      return ComentarioPerformance.fromJson(response.data);
    }
    throw Exception(response.data['detail'] ?? 'Erro ao editar comentário');
  }

  static Future<void> deletar(int id) async {
    final response = await ApiService.delete('$_base$id/');
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar comentário');
    }
  }

  static Future<Map<String, dynamic>> reagir(int id) async {
    final response = await ApiService.post('$_base$id/reagir/');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'status': response.data['status'],
        'total_reacoes': response.data['total_reacoes'],
        'adicionada': response.statusCode == 201,
      };
    }
    throw Exception('Erro ao reagir ao comentário');
  }
}
