import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/models/escalas.dart';

void main() {
  group('Escala.fromJson', () {
    test('deserializa data_hora_ensaio quando presente', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
        'musico_nome': 'Erickson',
        'evento_nome': 'Culto',
        'confirmado': false,
        'data_hora_ensaio': '2026-03-10T18:00:00',
      };

      final escala = Escala.fromJson(json);

      expect(escala.dataHoraEnsaio, isNotNull);
      expect(escala.dataHoraEnsaio, equals(DateTime.parse('2026-03-10T18:00:00')));
    });

    test('data_hora_ensaio fica null quando ausente no JSON', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
        'musico_nome': 'Erickson',
        'evento_nome': 'Culto',
        'confirmado': false,
      };

      final escala = Escala.fromJson(json);

      expect(escala.dataHoraEnsaio, isNull);
    });

    test('data_hora_ensaio fica null quando valor é null no JSON', () {
      final json = {
        'id': 1,
        'musico': 10,
        'evento': 20,
        'confirmado': false,
        'data_hora_ensaio': null,
      };

      final escala = Escala.fromJson(json);

      expect(escala.dataHoraEnsaio, isNull);
    });
  });

  group('Escala.toJson', () {
    test('serializa data_hora_ensaio no formato ISO 8601 quando preenchido', () {
      final dataEnsaio = DateTime(2026, 3, 10, 18, 0, 0);
      final escala = Escala(
        musicoId: 10,
        eventoId: 20,
        dataHoraEnsaio: dataEnsaio,
      );

      final json = escala.toJson();

      expect(json['data_hora_ensaio'], isNotNull);
      expect(json['data_hora_ensaio'], equals(dataEnsaio.toIso8601String()));
    });

    test('não inclui data_hora_ensaio no JSON quando null', () {
      final escala = Escala(
        musicoId: 10,
        eventoId: 20,
      );

      final json = escala.toJson();

      expect(json.containsKey('data_hora_ensaio'), isFalse);
    });
  });

  group('Escala - estado inicial', () {
    test('dataHoraEnsaio é null por padrão', () {
      final escala = Escala(musicoId: 1, eventoId: 2);
      expect(escala.dataHoraEnsaio, isNull);
    });
  });
}
