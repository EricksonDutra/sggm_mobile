// lib/models/escalas.dart
class Escala {
  final int? id;
  final int musicoId;
  final int eventoId;
  final String? musicoNome;
  final String? eventoNome;
  final List<int>? instrumentos; // ← M2M (substitui instrumentoNoEvento)
  final String? instrumentoNome; // ← campo computado read-only do backend
  final String? observacao;
  final bool confirmado;
  final DateTime? criadoEm;

  Escala({
    this.id,
    required this.musicoId,
    required this.eventoId,
    this.musicoNome,
    this.eventoNome,
    this.instrumentos,
    this.instrumentoNome,
    this.observacao,
    this.confirmado = false,
    this.criadoEm,
  });

  factory Escala.fromJson(Map<String, dynamic> json) {
    return Escala(
      id: json['id'],
      musicoId: json['musico'],
      eventoId: json['evento'],
      musicoNome: json['musico_nome'],
      eventoNome: json['evento_nome'],
      observacao: json['observacao'],
      // Suporte a lista de IDs (M2M) — tolerante a null
      instrumentos: json['instrumentos'] != null ? List<int>.from(json['instrumentos'] as List) : null,
      instrumentoNome: json['instrumento_nome'],
      confirmado: json['confirmado'] ?? false,
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'musico': musicoId,
      'evento': eventoId,
      // Só envia se houver instrumentos selecionados
      if (instrumentos != null && instrumentos!.isNotEmpty) 'instrumentos': instrumentos,
      if (observacao != null && observacao!.isNotEmpty) 'observacao': observacao,
    };
  }

  /// Cópia imutável com campos opcionalmente sobrescritos (padrão copyWith)
  Escala copyWith({
    int? id,
    int? musicoId,
    int? eventoId,
    String? musicoNome,
    String? eventoNome,
    List<int>? instrumentos,
    String? instrumentoNome,
    String? observacao,
    bool? confirmado,
    DateTime? criadoEm,
  }) {
    return Escala(
      id: id ?? this.id,
      musicoId: musicoId ?? this.musicoId,
      eventoId: eventoId ?? this.eventoId,
      musicoNome: musicoNome ?? this.musicoNome,
      eventoNome: eventoNome ?? this.eventoNome,
      instrumentos: instrumentos ?? this.instrumentos,
      instrumentoNome: instrumentoNome ?? this.instrumentoNome,
      observacao: observacao ?? this.observacao,
      confirmado: confirmado ?? this.confirmado,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
