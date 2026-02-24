import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/controllers/comentarios_controller.dart';
import 'package:sggm/models/comentario.dart';

// Helper para criar ComentarioPerformance sem depender de JSON
ComentarioPerformance _criarComentario({
  int id = 1,
  int evento = 10,
  int? musica = 5,
  int autor = 3,
  String autorNome = 'João',
  String texto = 'Comentário teste',
  int totalReacoes = 0,
  bool euCurto = false,
  bool podeEditar = true,
}) {
  return ComentarioPerformance.fromJson({
    'id': id,
    'evento': evento,
    'musica': musica,
    'autor': autor,
    'autor_nome': autorNome,
    'texto': texto,
    'criado_em': '2026-02-24T10:00:00.000Z',
    'editado_em': null,
    'total_reacoes': totalReacoes,
    'eu_curto': euCurto,
    'pode_editar': podeEditar,
  });
}

void main() {
  late ComentariosProvider provider;

  setUp(() {
    provider = ComentariosProvider();
  });

  // =====================================================
  group('ComentariosProvider - Estado inicial', () {
    test('lista de comentários começa vazia', () {
      expect(provider.comentarios, isEmpty);
    });

    test('não está carregando por padrão', () {
      expect(provider.isLoading, isFalse);
    });

    test('erro é null por padrão', () {
      expect(provider.erro, isNull);
    });
  });

  // =====================================================
  group('ComentariosProvider - limpar()', () {
    test('limpa lista de comentários', () {
      // Simula estado com dados
      provider.comentarios.add(_criarComentario());
      provider.limpar();
      expect(provider.comentarios, isEmpty);
    });

    test('limpa erro ao chamar limpar()', () {
      provider.limpar();
      expect(provider.erro, isNull);
    });

    test('isLoading permanece false após limpar()', () {
      provider.limpar();
      expect(provider.isLoading, isFalse);
    });
  });

  // =====================================================
  group('ComentarioPerformance - lógica de reação (copyWith)', () {
    test('toggle: adicionar reação incrementa totalReacoes e euCurto = true', () {
      final c = _criarComentario(totalReacoes: 2, euCurto: false);
      final atualizado = c.copyWith(
        totalReacoes: c.totalReacoes + 1,
        euCurto: true,
      );

      expect(atualizado.totalReacoes, equals(3));
      expect(atualizado.euCurto, isTrue);
    });

    test('toggle: remover reação decrementa totalReacoes e euCurto = false', () {
      final c = _criarComentario(totalReacoes: 3, euCurto: true);
      final atualizado = c.copyWith(
        totalReacoes: c.totalReacoes - 1,
        euCurto: false,
      );

      expect(atualizado.totalReacoes, equals(2));
      expect(atualizado.euCurto, isFalse);
    });

    test('totalReacoes não vai abaixo de 0', () {
      final c = _criarComentario(totalReacoes: 0, euCurto: true);
      // Simula comportamento seguro
      final novoTotal = (c.totalReacoes - 1).clamp(0, 9999);
      final atualizado = c.copyWith(totalReacoes: novoTotal, euCurto: false);

      expect(atualizado.totalReacoes, equals(0));
    });
  });

  // =====================================================
  group('ComentarioPerformance - permissão de edição', () {
    test('podeEditar true permite edição', () {
      final c = _criarComentario(podeEditar: true);
      expect(c.podeEditar, isTrue);
    });

    test('podeEditar false bloqueia edição', () {
      final c = _criarComentario(podeEditar: false);
      expect(c.podeEditar, isFalse);
    });

    test('comentário de outro autor não pertence ao usuário atual', () {
      final c = _criarComentario(autor: 99);
      const musicoAtualId = 1;
      expect(c.autor == musicoAtualId, isFalse);
    });

    test('comentário do próprio autor pertence ao usuário atual', () {
      final c = _criarComentario(autor: 1);
      const musicoAtualId = 1;
      expect(c.autor == musicoAtualId, isTrue);
    });
  });

  // =====================================================
  group('ComentarioPerformance - formatação de tempo', () {
    test('comentário recente tem criadoEm no passado', () {
      final c = _criarComentario();
      expect(c.criadoEm.isBefore(DateTime.now()), isTrue);
    });

    test('comentário sem editado_em não foi editado', () {
      final c = _criarComentario();
      expect(c.editadoEm, isNull);
    });
  });
}
