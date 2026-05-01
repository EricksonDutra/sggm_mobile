import 'package:sggm/models/musicas.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';

class MusicasService {
  Future<List<Musica>> listarMusicas({String? busca}) async {
    try {
      final response = await ApiService.get('/api/musicas/');
      final data = response.data;

      List<Musica> musicas = [];

      if (data is Map && data.containsKey('results')) {
        musicas = (data['results'] as List).map((json) => Musica.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is List) {
        musicas = data.map((json) => Musica.fromJson(json as Map<String, dynamic>)).toList();
      }

      if (busca != null && busca.isNotEmpty) {
        musicas = musicas.where((m) => m.titulo.toLowerCase().contains(busca.toLowerCase())).toList();
      }

      return musicas;
    } catch (e) {
      AppLogger.error('❌ Erro ao listar músicas: $e');
      rethrow;
    }
  }

  /// Busca a música completa por ID — inclui conteudo_cifra
  Future<Musica?> buscarPorId(int id) async {
    try {
      final response = await ApiService.get('/api/musicas/$id/');
      final data = response.data;
      if (data is Map<String, dynamic>) return Musica.fromJson(data);
      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar música por ID: $e');
      return null;
    }
  }
}
