import 'package:flutter/material.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/util/cifra_parser.dart';

class CifraLinhaWidget extends StatelessWidget {
  final String linha;
  final double fontSize;

  const CifraLinhaWidget({
    super.key,
    required this.linha,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = CifraParser.parsearLinha(linha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed.acordes.trim().isNotEmpty)
          Text(
            parsed.acordes,
            style: TextStyle(
              color: AppTheme.presbyterianoVerdeClaro,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              height: 1.4,
            ),
          ),
        if (parsed.letra.trim().isNotEmpty)
          Text(
            parsed.letra,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: fontSize,
              color: Colors.white,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}
