enum TipoSecao { intro, verso, refrao, ponte, outro }

class LinhaParseada {
  final String acordes;
  final String letra;
  const LinhaParseada({required this.acordes, required this.letra});
}

class SecaoCifra {
  final TipoSecao tipo;
  final List<String> linhas;
  const SecaoCifra({required this.tipo, required this.linhas});
}

class CifraParser {
  static const _cromatico = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static final _acordeRegex = RegExp(r'\[([^\]]+)\]');

  static LinhaParseada parsearLinha(String linha) {
    final matches = _acordeRegex.allMatches(linha).toList();
    if (matches.isEmpty) return LinhaParseada(acordes: '', letra: linha);

    final bufAcorde = StringBuffer();
    final bufLetra = StringBuffer();
    int cursorLetra = 0;

    for (final match in matches) {
      final acorde = match.group(1)!;
      final textoAntes = linha.substring(cursorLetra, match.start).replaceAll(_acordeRegex, '');

      bufLetra.write(textoAntes);

      final posicao = bufLetra.length;
      final espacos = posicao - bufAcorde.length;
      if (espacos > 0) bufAcorde.write(' ' * espacos);

      bufAcorde.write(acorde);
      cursorLetra = match.end;
    }

    bufLetra.write(
      linha.substring(cursorLetra).replaceAll(_acordeRegex, ''),
    );

    // Iguala comprimentos: acorde define o tamanho quando maior, letra quando maior
    final diff = bufAcorde.length - bufLetra.length;
    if (diff > 0) bufLetra.write(' ' * diff);
    if (diff < 0) bufAcorde.write(' ' * diff.abs());

    return LinhaParseada(
      acordes: bufAcorde.toString(),
      letra: bufLetra.toString(),
    );
  }

  static String transporAcorde(String acorde, int semitons) {
    for (int i = _cromatico.length - 1; i >= 0; i--) {
      if (acorde.startsWith(_cromatico[i])) {
        final sufixo = acorde.substring(_cromatico[i].length);
        final novoIndex = ((_cromatico.indexOf(_cromatico[i]) + semitons) % 12 + 12) % 12;
        return '${_cromatico[novoIndex]}$sufixo';
      }
    }
    return acorde;
  }

  static String transporCifra(String conteudo, int semitons) {
    if (semitons == 0) return conteudo;
    return conteudo.replaceAllMapped(
      _acordeRegex,
      (m) => '[${transporAcorde(m.group(1)!, semitons)}]',
    );
  }

  static List<SecaoCifra> parsearSecoes(String conteudo) {
    final secoes = <SecaoCifra>[];
    TipoSecao? tipoAtual;
    List<String> linhasAtual = [];

    for (final linha in conteudo.split('\n')) {
      final l = linha.trim();
      if (l == '{start_of_intro}') {
        tipoAtual = TipoSecao.intro;
        linhasAtual = [];
      } else if (l == '{start_of_verse}') {
        tipoAtual = TipoSecao.verso;
        linhasAtual = [];
      } else if (l == '{start_of_chorus}') {
        tipoAtual = TipoSecao.refrao;
        linhasAtual = [];
      } else if (l == '{start_of_bridge}') {
        tipoAtual = TipoSecao.ponte;
        linhasAtual = [];
      } else if (l.startsWith('{end_of_')) {
        if (tipoAtual != null) secoes.add(SecaoCifra(tipo: tipoAtual, linhas: List.from(linhasAtual)));
        tipoAtual = null;
      } else if (tipoAtual != null && l.isNotEmpty) {
        linhasAtual.add(linha);
      }
    }
    return secoes;
  }
}
