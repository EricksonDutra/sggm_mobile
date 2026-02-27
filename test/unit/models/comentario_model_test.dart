import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/models/comentario.dart';

void main() {
  // ── Fixture reutilizável ──
  Map<String, dynamic> jsonCompleto() => {
        'id': 1,
        'evento': 10,
        'musica': 5,
        'autor': 3,
        'autor_nome': 'João Silva',
        'texto': 'Ótima performance!',
        'criado_em': '2026-02-24T10:00:00.000Z',
        'editado_em': '2026-02-24T11:00:00.000Z',
        'total_reacoes': 4,
        'eu_curto': true,
        'pode_editar': true,
      };

  // =====================================================
  group('ComentarioPerformance.fromJson', () {
    test('desserializa todos os campos corretamente', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());

      expect(c.id, equals(1));
      expect(c.evento, equals(10));
      expect(c.musica, equals(5));
      expect(c.autor, equals(3));
      expect(c.autorNome, equals('João Silva'));
      expect(c.texto, equals('Ótima performance!'));
      expect(c.totalReacoes, equals(4));
      expect(c.euCurto, isTrue);
      expect(c.podeEditar, isTrue);
    });

    test('parseia criado_em como DateTime corretamente', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      expect(c.criadoEm, isA<DateTime>());
      expect(c.criadoEm.year, equals(2026));
      expect(c.criadoEm.month, equals(2));
      expect(c.criadoEm.day, equals(24));
    });

    test('parseia editado_em quando presente', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      expect(c.editadoEm, isNotNull);
      expect(c.editadoEm!.hour, equals(11));
    });

    test('editado_em é null quando ausente no JSON', () {
      final json = jsonCompleto()..remove('editado_em');
      final c = ComentarioPerformance.fromJson(json);
      expect(c.editadoEm, isNull);
    });

    test('musica é null quando ausente no JSON', () {
      final json = jsonCompleto()..['musica'] = null;
      final c = ComentarioPerformance.fromJson(json);
      expect(c.musica, isNull);
    });

    test('total_reacoes usa 0 como padrão quando ausente', () {
      final json = jsonCompleto()..remove('total_reacoes');
      final c = ComentarioPerformance.fromJson(json);
      expect(c.totalReacoes, equals(0));
    });

    test('eu_curto usa false como padrão quando ausente', () {
      final json = jsonCompleto()..remove('eu_curto');
      final c = ComentarioPerformance.fromJson(json);
      expect(c.euCurto, isFalse);
    });

    test('pode_editar usa false como padrão quando ausente', () {
      final json = jsonCompleto()..remove('pode_editar');
      final c = ComentarioPerformance.fromJson(json);
      expect(c.podeEditar, isFalse);
    });

    test('autor_nome usa string vazia como padrão quando ausente', () {
      final json = jsonCompleto()..remove('autor_nome');
      final c = ComentarioPerformance.fromJson(json);
      expect(c.autorNome, equals(''));
    });
  });

  // =====================================================
  group('ComentarioPerformance.toJson', () {
    test('serializa evento, musica e texto corretamente', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final json = c.toJson();

      expect(json['evento'], equals(10));
      expect(json['musica'], equals(5));
      expect(json['texto'], equals('Ótima performance!'));
    });

    test('não inclui campos readonly no toJson', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final json = c.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('autor'), isFalse);
      expect(json.containsKey('autor_nome'), isFalse);
      expect(json.containsKey('criado_em'), isFalse);
      expect(json.containsKey('total_reacoes'), isFalse);
    });

    test('não inclui musica quando null', () {
      final json = jsonCompleto()..['musica'] = null;
      final c = ComentarioPerformance.fromJson(json);
      final resultado = c.toJson();
      expect(resultado['musica'], isNull);
    });
  });

  // =====================================================
  group('ComentarioPerformance.copyWith', () {
    test('atualiza totalReacoes mantendo outros campos', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final novo = c.copyWith(totalReacoes: 10);

      expect(novo.totalReacoes, equals(10));
      expect(novo.id, equals(c.id));
      expect(novo.texto, equals(c.texto));
      expect(novo.autorNome, equals(c.autorNome));
    });

    test('atualiza euCurto para false (toggle off)', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final novo = c.copyWith(euCurto: false, totalReacoes: 3);

      expect(novo.euCurto, isFalse);
      expect(novo.totalReacoes, equals(3));
    });

    test('atualiza texto mantendo outros campos', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final novo = c.copyWith(texto: 'Editado!');

      expect(novo.texto, equals('Editado!'));
      expect(novo.id, equals(c.id));
      expect(novo.euCurto, equals(c.euCurto));
    });

    test('sem argumentos retorna objeto com mesmos valores', () {
      final c = ComentarioPerformance.fromJson(jsonCompleto());
      final novo = c.copyWith();

      expect(novo.id, equals(c.id));
      expect(novo.texto, equals(c.texto));
      expect(novo.totalReacoes, equals(c.totalReacoes));
      expect(novo.euCurto, equals(c.euCurto));
    });
  });
}
