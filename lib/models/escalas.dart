class Escala {
  final int? id;
  final int musicoId; // Para envio ao Backend (FK)
  final int eventoId; // Para envio ao Backend (FK)
  final String? musicoNome; // Apenas leitura (vem do Serializer)
  final String? eventoNome; // Apenas leitura (vem do Serializer)
  final String instrumentoNoEvento;
  final String? observacao;

  Escala({
    this.id,
    required this.musicoId,
    required this.eventoId,
    this.musicoNome,
    this.eventoNome,
    this.instrumentoNoEvento = '',
    this.observacao,
  });

  factory Escala.fromJson(Map<String, dynamic> json) {
    return Escala(
      id: json['id'],
      // O Backend envia 'musico' e 'evento' como IDs (Foreign Keys)
      musicoId: json['musico'],
      eventoId: json['evento'],

      // Campos extras que adicionamos no Serializer (read_only)
      musicoNome: json['musico_nome'],
      eventoNome: json['evento_nome'],

      // Snake case padrão Python
      instrumentoNoEvento: json['instrumento_no_evento'] ?? '',
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'musico': musicoId,
      'evento': eventoId,
      'instrumento_no_evento': instrumentoNoEvento,
      'observacao': observacao ?? '',
    };
  }
}
