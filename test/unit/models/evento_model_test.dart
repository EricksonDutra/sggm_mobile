import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/models/eventos.dart';

void main() {
  group('Evento.fromJson', () {
    test('deserializa campos básicos corretamente', () {
      final json = {
        'id': 1,
        'nome': 'Culto de Domingo',
        'tipo': 'CULTO',
        'data_evento': '2026-03-15T19:00:00',
        'local': 'Igreja Central',
        'descricao': 'Culto principal',
      };

      final evento = Evento.fromJson(json);

      expect(evento.id, equals(1));
      expect(evento.nome, equals('Culto de Domingo'));
      expect(evento.tipo, equals('CULTO'));
      expect(evento.local, equals('Igreja Central'));
      expect(evento.dataHoraEnsaio, isNull);
    });

    test('deserializa dataHoraEnsaio quando presente', () {
      final json = {
        'id': 1,
        'nome': 'Culto',
        'tipo': 'CULTO',
        'data_evento': '2026-03-15T19:00:00',
        'local': 'Igreja',
        'data_hora_ensaio': '2026-03-13T18:00:00',
      };

      final evento = Evento.fromJson(json);

      expect(evento.dataHoraEnsaio, isNotNull);
      expect(evento.dataHoraEnsaio, equals(DateTime.parse('2026-03-13T18:00:00')));
    });

    test('dataHoraEnsaio fica null quando ausente no JSON', () {
      final json = {
        'id': 1,
        'nome': 'Culto',
        'tipo': 'CULTO',
        'data_evento': '2026-03-15T19:00:00',
        'local': 'Igreja',
      };

      final evento = Evento.fromJson(json);

      expect(evento.dataHoraEnsaio, isNull);
    });

    test('dataHoraEnsaio fica null quando valor é null no JSON', () {
      final json = {
        'id': 1,
        'nome': 'Culto',
        'tipo': 'CULTO',
        'data_evento': '2026-03-15T19:00:00',
        'local': 'Igreja',
        'data_hora_ensaio': null,
      };

      final evento = Evento.fromJson(json);

      expect(evento.dataHoraEnsaio, isNull);
    });

    test('tipo usa CULTO como padrão quando ausente', () {
      final json = {
        'id': 1,
        'nome': 'Culto',
        'data_evento': '2026-03-15T19:00:00',
        'local': 'Igreja',
      };

      final evento = Evento.fromJson(json);

      expect(evento.tipo, equals('CULTO'));
    });
  });

  group('Evento.toJson', () {
    test('serializa dataHoraEnsaio no formato ISO 8601 quando preenchido', () {
      final dataEnsaio = DateTime(2026, 3, 13, 18, 0, 0);
      final evento = Evento(
        nome: 'Culto',
        dataEvento: '2026-03-15T19:00:00',
        local: 'Igreja',
        dataHoraEnsaio: dataEnsaio,
      );

      final json = evento.toJson();

      expect(json['data_hora_ensaio'], isNotNull);
      expect(json['data_hora_ensaio'], equals(dataEnsaio.toIso8601String()));
    });

    test('não inclui dataHoraEnsaio no JSON quando null', () {
      final evento = Evento(
        nome: 'Culto',
        dataEvento: '2026-03-15T19:00:00',
        local: 'Igreja',
      );

      final json = evento.toJson();

      expect(json.containsKey('data_hora_ensaio'), isFalse);
    });

    test('não inclui id quando null', () {
      final evento = Evento(
        nome: 'Culto',
        dataEvento: '2026-03-15T19:00:00',
        local: 'Igreja',
      );

      expect(evento.toJson().containsKey('id'), isFalse);
    });
  });
}
