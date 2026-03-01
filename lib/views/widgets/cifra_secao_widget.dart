import 'package:flutter/material.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/util/cifra_parser.dart';

class CifraSecaoWidget extends StatelessWidget {
  final SecaoCifra secao;
  final double fontSize;

  const CifraSecaoWidget({
    super.key,
    required this.secao,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitulo(),
        const SizedBox(height: 4),
        ...secao.linhas.map(_buildLinha),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTitulo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.presbyterianoVerde),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labelSecao(secao.tipo),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.presbyterianoVerde,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLinha(String linha) {
    final parseada = CifraParser.parsearLinha(linha);

    // Linha SEM acordes — texto simples, deixa o Flutter quebrar normalmente
    if (parseada.acordes.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          parseada.letra.isEmpty ? ' ' : parseada.letra,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'RobotoMono',
            color: Colors.white,
            height: 1.4,
          ),
          // ✅ SoftWrap padrão do Flutter — quebra entre palavras
          softWrap: true,
        ),
      );
    }

    // Linha COM acordes — usa Wrap por palavras
    final blocos = _parsearBlocosEmPalavras(linha);

    if (blocos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextoAcordes(parseada.acordes),
          if (parseada.letra.trim().isNotEmpty) _buildTextoLetra(parseada.letra),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 4,
        children: blocos.map(_buildBlocoWidget).toList(),
      ),
    );
  }

  Widget _buildBlocoWidget(_BlocoAcorde bloco) {
    final temAcorde = bloco.acorde.isNotEmpty;

    return IntrinsicWidth(
      child: Padding(
        padding: EdgeInsets.only(right: bloco.silaba.endsWith(' ') ? 0 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linha do acorde (ou espaço transparente para manter altura)
            Text(
              temAcorde ? bloco.acorde : ' ',
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'RobotoMono',
                color: temAcorde ? AppTheme.presbyterianoVerdeClaro : Colors.transparent,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0.5,
              ),
            ),
            // Linha da sílaba/palavra
            Text(
              bloco.silaba.isEmpty ? ' ' : bloco.silaba,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'RobotoMono',
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Divide em blocos no nível da PALAVRA para que o Wrap quebre corretamente
  List<_BlocoAcorde> _parsearBlocosEmPalavras(String linha) {
    final blocos = <_BlocoAcorde>[];
    final acordeRegex = RegExp(r'\[([^\]]*)\]');

    // Substitui [ACORDE] por um marcador e reconstrói com posições
    final partes = <_ParteLinha>[];
    int cursor = 0;

    for (final match in acordeRegex.allMatches(linha)) {
      if (match.start > cursor) {
        partes.add(_ParteLinha(texto: linha.substring(cursor, match.start), acorde: null));
      }
      partes.add(_ParteLinha(texto: '', acorde: match.group(1)!));
      cursor = match.end;
    }
    if (cursor < linha.length) {
      partes.add(_ParteLinha(texto: linha.substring(cursor), acorde: null));
    }

    // Monta blocos: acorde fica com a palavra imediatamente seguinte
    String acordePendente = '';
    String textoPendente = '';

    for (final parte in partes) {
      if (parte.acorde != null) {
        // Flush do texto acumulado antes de novo acorde
        if (textoPendente.isNotEmpty) {
          // Quebra por espaço: cada "palavra " vira um bloco
          final palavras = _dividirEmPalavras(textoPendente);
          for (final p in palavras) {
            blocos.add(_BlocoAcorde(acorde: acordePendente, silaba: p));
            acordePendente = '';
          }
          textoPendente = '';
        }
        acordePendente = parte.acorde!;
      } else {
        textoPendente += parte.texto;
      }
    }

    // Flush final
    if (textoPendente.isNotEmpty || acordePendente.isNotEmpty) {
      final palavras = _dividirEmPalavras(textoPendente);
      if (palavras.isEmpty) {
        blocos.add(_BlocoAcorde(acorde: acordePendente, silaba: ''));
      } else {
        for (int i = 0; i < palavras.length; i++) {
          blocos.add(_BlocoAcorde(
            acorde: i == 0 ? acordePendente : '',
            silaba: palavras[i],
          ));
        }
      }
    }

    return blocos;
  }

  /// Divide texto em palavras preservando o espaço como parte da palavra
  /// Ex: "nossas mãos, e " → ["nossas ", "mãos, ", "e "]
  List<String> _dividirEmPalavras(String texto) {
    final resultado = <String>[];
    final regex = RegExp(r'\S+\s*');
    for (final m in regex.allMatches(texto)) {
      resultado.add(m.group(0)!);
    }
    return resultado;
  }

  Widget _buildTextoAcordes(String acordes) {
    return Text(
      acordes,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'RobotoMono',
        color: AppTheme.presbyterianoVerdeClaro,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 1.0, // ✅ espaço extra entre caracteres = acordes respiram
      ),
    );
  }

  Widget _buildTextoLetra(String letra) {
    return Text(
      letra.isEmpty ? ' ' : letra,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'RobotoMono',
        color: Colors.white,
        height: 1.4,
        letterSpacing: 1.0, // ✅ mantém alinhamento com a linha de acordes
      ),
    );
  }

  String _labelSecao(TipoSecao tipo) => switch (tipo) {
        TipoSecao.intro => 'INTRO',
        TipoSecao.verso => 'VERSO',
        TipoSecao.refrao => 'REFRÃO',
        TipoSecao.ponte => 'PONTE',
        TipoSecao.outro => 'OUTRO',
      };
}

class _BlocoAcorde {
  final String acorde;
  final String silaba;
  const _BlocoAcorde({required this.acorde, required this.silaba});
}

class _ParteLinha {
  final String texto;
  final String? acorde;
  const _ParteLinha({required this.texto, required this.acorde});
}
