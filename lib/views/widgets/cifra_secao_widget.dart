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

    // Linha puramente de letra — sem acordes
    if (parseada.acordes.trim().isEmpty) {
      return _buildTextoLetra(parseada.letra.isEmpty ? '' : parseada.letra);
    }

    // Linha com acordes: empilha acordes sobre letra com fonte mono
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextoAcordes(parseada.acordes),
        if (parseada.letra.trim().isNotEmpty) _buildTextoLetra(parseada.letra),
      ],
    );
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
