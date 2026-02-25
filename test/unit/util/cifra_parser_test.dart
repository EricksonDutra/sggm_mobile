import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/util/cifra_parser.dart';

void main() {
  group('CifraParser.parsearLinha', () {
    test('extrai acordes e letra de uma linha simples', () {
      final resultado = CifraParser.parsearLinha('[G]    [A]');

      expect(resultado.acordes.length, equals(resultado.letra.length));
      expect(resultado.acordes.trimRight(), equals('G   A'));
    });

    test('linha sem acordes retorna apenas letra', () {
      const linha = 'Eu me prostro a Ti';
      final resultado = CifraParser.parsearLinha(linha);

      expect(resultado.acordes, isEmpty);
      expect(resultado.letra, equals('Eu me prostro a Ti'));
    });

    test('linha apenas com acordes retorna acordes e letra vazia', () {
      const linha = '[D] [D5-] [D4]';
      final resultado = CifraParser.parsearLinha(linha);

      expect(resultado.acordes, isNotEmpty);
      expect(resultado.letra.trim(), isEmpty);
    });
  });

  group('CifraParser.transporAcorde', () {
    test('transpõe C para D com 2 semitons', () {
      expect(CifraParser.transporAcorde('C', 2), equals('D'));
    });

    test('transpõe G para A com 2 semitons', () {
      expect(CifraParser.transporAcorde('G', 2), equals('A'));
    });

    test('transpõe B para C com 1 semitom (wrap around)', () {
      expect(CifraParser.transporAcorde('B', 1), equals('C'));
    });

    test('transpõe acorde com sufixo: Am para Bm com 2 semitons', () {
      expect(CifraParser.transporAcorde('Am', 2), equals('Bm'));
    });

    test('transpõe acorde suspenso: D5- permanece com sufixo', () {
      expect(CifraParser.transporAcorde('D5-', 2), equals('E5-'));
    });

    test('transpõe negativamente: D para C com -2 semitons', () {
      expect(CifraParser.transporAcorde('D', -2), equals('C'));
    });
  });

  group('CifraParser.parsearSecoes', () {
    test('detecta secao de verso corretamente', () {
      const cifra = '''
{start_of_verse}
[D]Santo, santo, poderoso
{end_of_verse}
''';
      final secoes = CifraParser.parsearSecoes(cifra);
      expect(secoes.length, equals(1));
      expect(secoes.first.tipo, equals(TipoSecao.verso));
    });

    test('detecta secao de refrão corretamente', () {
      const cifra = '''
{start_of_chorus}
[A]Santo é o Teu nome [G][D]
{end_of_chorus}
''';
      final secoes = CifraParser.parsearSecoes(cifra);
      expect(secoes.first.tipo, equals(TipoSecao.refrao));
    });

    test('detecta múltiplas seções na ordem correta', () {
      const cifra = '''
{start_of_intro}
[D]
{end_of_intro}
{start_of_verse}
linha verso
{end_of_verse}
{start_of_chorus}
linha refrão
{end_of_chorus}
''';
      final secoes = CifraParser.parsearSecoes(cifra);
      expect(secoes.length, equals(3));
      expect(secoes[0].tipo, equals(TipoSecao.intro));
      expect(secoes[1].tipo, equals(TipoSecao.verso));
      expect(secoes[2].tipo, equals(TipoSecao.refrao));
    });

    test('retorna lista vazia para conteúdo sem seções', () {
      final secoes = CifraParser.parsearSecoes('');
      expect(secoes, isEmpty);
    });
  });

  group('CifraParser.transporCifra', () {
    test('transpõe todos os acordes de uma cifra completa', () {
      const cifra = '{start_of_verse}\n[D]Santo [G]poderoso\n{end_of_verse}';
      final resultado = CifraParser.transporCifra(cifra, 2);
      expect(resultado, contains('[E]'));
      expect(resultado, contains('[A]'));
    });
  });
}
