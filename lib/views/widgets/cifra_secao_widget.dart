import 'package:flutter/material.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/util/cifra_parser.dart';
import 'package:sggm/views/widgets/cifra_linha_widget.dart';

class CifraSecaoWidget extends StatelessWidget {
  final SecaoCifra secao;
  final double fontSize;

  const CifraSecaoWidget({super.key, required this.secao, this.fontSize = 14});

  String get _labelSecao {
    switch (secao.tipo) {
      case TipoSecao.intro:
        return 'INTRO';
      case TipoSecao.verso:
        return 'VERSO';
      case TipoSecao.refrao:
        return 'REFRÃO';
      case TipoSecao.ponte:
        return 'PONTE';
      case TipoSecao.outro:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_labelSecao.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.presbyterianoVerde.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.presbyterianoVerde, width: 1),
              ),
              child: Text(
                _labelSecao,
                style: const TextStyle(
                  color: AppTheme.presbyterianoVerdeClaro,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...secao.linhas.map((l) => CifraLinhaWidget(linha: l, fontSize: fontSize)),
        ],
      ),
    );
  }
}
