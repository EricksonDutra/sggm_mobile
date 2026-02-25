import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/util/cifra_scroll_controller.dart';

void main() {
  group('CifraScrollConfig', () {
    test('velocidade inicial é o valor padrão', () {
      final config = CifraScrollConfig();
      expect(config.velocidade, equals(CifraScrollConfig.velocidadePadrao));
    });

    test('fontSize inicial é o valor padrão', () {
      final config = CifraScrollConfig();
      expect(config.fontSize, equals(CifraScrollConfig.fontSizePadrao));
    });

    test('aumentar fonte respeita o limite máximo', () {
      final config = CifraScrollConfig(fontSize: CifraScrollConfig.fontSizeMax);
      final nova = config.aumentarFonte();
      expect(nova.fontSize, equals(CifraScrollConfig.fontSizeMax));
    });

    test('diminuir fonte respeita o limite mínimo', () {
      final config = CifraScrollConfig(fontSize: CifraScrollConfig.fontSizeMin);
      final nova = config.diminuirFonte();
      expect(nova.fontSize, equals(CifraScrollConfig.fontSizeMin));
    });

    test('aumentar fonte incrementa 1.0', () {
      final config = CifraScrollConfig(fontSize: 14.0);
      expect(config.aumentarFonte().fontSize, equals(15.0));
    });

    test('diminuir fonte decrementa 1.0', () {
      final config = CifraScrollConfig(fontSize: 14.0);
      expect(config.diminuirFonte().fontSize, equals(13.0));
    });

    test('aumentar velocidade respeita o limite máximo', () {
      final config = CifraScrollConfig(velocidade: CifraScrollConfig.velocidadeMax);
      final nova = config.aumentarVelocidade();
      expect(nova.velocidade, equals(CifraScrollConfig.velocidadeMax));
    });

    test('diminuir velocidade respeita o limite mínimo', () {
      final config = CifraScrollConfig(velocidade: CifraScrollConfig.velocidadeMin);
      final nova = config.diminuirVelocidade();
      expect(nova.velocidade, equals(CifraScrollConfig.velocidadeMin));
    });
  });
}
