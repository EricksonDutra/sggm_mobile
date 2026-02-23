import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/models/escalas.dart';

void main() {
  group('Escala.fromJson', () {
    test('deserializa campos básicos corretamente', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
        'musico_nome': 'Erickson',
        'evento_nome': 'Culto',
        'confirmado': false,
        'observacao': 'Teste',
        'instrumento_nome': 'Violão',
      };

      final escala = Escala.fromJson(json);

      expect(escala.id, equals(1));
      expect(escala.musicoId, equals(10));
      expect(escala.eventoId, equals(20));
      expect(escala.musicoNome, equals('Erickson'));
      expect(escala.eventoNome, equals('Culto'));
      expect(escala.confirmado, isFalse);
      expect(escala.observacao, equals('Teste'));
    });

    test('confirmado usa false como padrão quando ausente', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
      };

      final escala = Escala.fromJson(json);

      expect(escala.confirmado, isFalse);
    });

    test('não contém dataHoraEnsaio', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
        'confirmado': false,
      };

      final escala = Escala.fromJson(json);

      // dataHoraEnsaio foi movido para Evento
      expect(escala.toJson().containsKey('data_hora_ensaio'), isFalse);
    });
  });

  group('Escala.toJson', () {
    test('serializa campos obrigatórios corretamente', () {
      final escala = Escala(
        musicoId: 10,
        eventoId: 20,
        observacao: 'Obs',
      );

      final json = escala.toJson();

      expect(json['musico'], equals(10));
      expect(json['evento'], equals(20));
      expect(json['observacao'], equals('Obs'));
      expect(json.containsKey('data_hora_ensaio'), isFalse);
    });

    test('não inclui id quando null', () {
      final escala = Escala(musicoId: 1, eventoId: 2);
      expect(escala.toJson().containsKey('id'), isFalse);
    });
  });

  group('Escala - estado inicial', () {
    test('confirmado é false por padrão', () {
      final escala = Escala(musicoId: 1, eventoId: 2);
      expect(escala.confirmado, isFalse);
    });
  });
}
