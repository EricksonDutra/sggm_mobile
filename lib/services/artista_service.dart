import 'package:sggm/models/artista.dart';
import 'package:sggm/services/api_service.dart';
import 'package:sggm/util/app_logger.dart';

class ArtistaService {
  Future<List<Artista>> listarArtistas({String? busca}) async {
    String endpoint = '/api/artistas/';

    try {
      final response = await ApiService.get(endpoint);

      // Com Dio, os dados estão em response.data (já decodificado)
      final data = response.data;

      // Verificar se tem paginação (results)
      if (data is Map && data.containsKey('results')) {
        List<Artista> artistas =
            (data['results'] as List).map((json) => Artista.fromJson(json as Map<String, dynamic>)).toList();

        // Filtrar por nome se houver busca
        if (busca != null && busca.isNotEmpty) {
          artistas = artistas.where((a) => a.nome.toLowerCase().contains(busca.toLowerCase())).toList();
        }

        return artistas;
      }

      // Se for uma lista direta
      if (data is List) {
        List<Artista> artistas = data.map((json) => Artista.fromJson(json as Map<String, dynamic>)).toList();

        if (busca != null && busca.isNotEmpty) {
          artistas = artistas.where((a) => a.nome.toLowerCase().contains(busca.toLowerCase())).toList();
        }

        return artistas;
      }

      return [];
    } catch (e) {
      AppLogger.error('❌ Erro ao listar artistas: $e');
      rethrow;
    }
  }

  Future<Artista> criarArtista(String nome) async {
    try {
      final body = {'nome': nome};

      final response = await ApiService.post('/api/artistas/', body: body);

      // Com Dio, response.data já vem decodificado
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return Artista.fromJson(data);
      }

      throw Exception('Formato de resposta inválido');
    } catch (e) {
      AppLogger.error('❌ Erro ao criar artista: $e');
      rethrow;
    }
  }

  Future<Artista> buscarOuCriar(String nome) async {
    try {
      // Tenta buscar artista existente
      final artistas = await listarArtistas(busca: nome);

      // Buscar match exato (case-insensitive)
      final artistaExato = artistas.firstWhere(
        (a) => a.nome.toLowerCase() == nome.toLowerCase(),
        orElse: () => throw Exception('Não encontrado'),
      );

      return artistaExato;
    } catch (e) {
      // Se não existe, cria novo
      AppLogger.warning('⚠️ Artista não encontrado, criando novo...');
      return await criarArtista(nome);
    }
  }

  Future<Artista?> buscarPorId(int id) async {
    try {
      final response = await ApiService.get('/api/artistas/$id/');

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return Artista.fromJson(data);
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar artista por ID: $e');
      return null;
    }
  }

  Future<bool> atualizarArtista(int id, String novoNome) async {
    try {
      final body = {'nome': novoNome};

      final response = await ApiService.put('/api/artistas/$id/', body: body);

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar artista: $e');
      return false;
    }
  }

  Future<bool> deletarArtista(int id) async {
    try {
      final response = await ApiService.delete('/api/artistas/$id/');

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Erro ao deletar artista: $e');
      return false;
    }
  }
}
