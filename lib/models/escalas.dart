class Escala {
  final int? id;
  final int musicoId;
  final int eventoId;
  final String? musicoNome;
  final String? eventoNome;
  final int? instrumentoNoEvento;
  final String? instrumentoNome;
  final String? observacao;
  final bool confirmado;
  final DateTime? criadoEm;
  final DateTime? dataHoraEnsaio;

  Escala({
    this.id,
    required this.musicoId,
    required this.eventoId,
    this.musicoNome,
    this.eventoNome,
    this.instrumentoNoEvento,
    this.observacao,
    this.confirmado = false,
    this.criadoEm,
    this.instrumentoNome,
    this.dataHoraEnsaio,
  });

  factory Escala.fromJson(Map<String, dynamic> json) {
    return Escala(
      id: json['id'],
      musicoId: json['musico'],
      eventoId: json['evento'],
      musicoNome: json['musico_nome'],
      eventoNome: json['evento_nome'],
      observacao: json['observacao'],
      instrumentoNoEvento: json['instrumento_no_evento'],
      instrumentoNome: json['instrumento_nome'],
      confirmado: json['confirmado'] ?? false,
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
      dataHoraEnsaio: json['data_hora_ensaio'] != null ? DateTime.parse(json['data_hora_ensaio']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'musico': musicoId,
      'evento': eventoId,
      'instrumento_no_evento': instrumentoNoEvento != null ? instrumentoNoEvento.toString() : '',
      'observacao': observacao ?? '',
      if (dataHoraEnsaio != null) 'data_hora_ensaio': dataHoraEnsaio!.toIso8601String(),
    };
  }
}
