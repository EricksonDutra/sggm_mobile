class CifraScrollConfig {
  static const double velocidadePadrao = 30.0;
  static const double velocidadeMin = 10.0;
  static const double velocidadeMax = 100.0;
  static const double velocidadeStep = 10.0;

  static const double fontSizePadrao = 14.0;
  static const double fontSizeMin = 10.0;
  static const double fontSizeMax = 22.0;
  static const double fontSizeStep = 1.0;

  final double velocidade;
  final double fontSize;

  const CifraScrollConfig({
    this.velocidade = velocidadePadrao,
    this.fontSize = fontSizePadrao,
  });

  CifraScrollConfig aumentarFonte() => CifraScrollConfig(
        velocidade: velocidade,
        fontSize: (fontSize + fontSizeStep).clamp(fontSizeMin, fontSizeMax),
      );

  CifraScrollConfig diminuirFonte() => CifraScrollConfig(
        velocidade: velocidade,
        fontSize: (fontSize - fontSizeStep).clamp(fontSizeMin, fontSizeMax),
      );

  CifraScrollConfig aumentarVelocidade() => CifraScrollConfig(
        velocidade: (velocidade + velocidadeStep).clamp(velocidadeMin, velocidadeMax),
        fontSize: fontSize,
      );

  CifraScrollConfig diminuirVelocidade() => CifraScrollConfig(
        velocidade: (velocidade - velocidadeStep).clamp(velocidadeMin, velocidadeMax),
        fontSize: fontSize,
      );
}
