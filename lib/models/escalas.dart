class Escala {
  final int? id;
  final int musicoId;
  final int eventoId;
  final String? musicoNome;
  final String? eventoNome;
  final List<int>? instrumentos;
  final String? instrumentoNome;
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

  // ✅ Só converte tipos — NUNCA retorna 0 como fallback silencioso
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value); // lança exceção se inválido
    throw FormatException('Esperado int, recebido: ${value.runtimeType} = $value');
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory Escala.fromJson(Map<String, dynamic> json) {
    List<int>? instrumentos;
    final raw = json['instrumentos'];
    if (raw is List) {
      instrumentos = raw.map((e) => _toIntNullable(e)).whereType<int>().toList();
    }

    return Escala(
      id: _toIntNullable(json['id']),
      musicoId: _toInt(json['musico']),
      eventoId: _toInt(json['evento']),
      musicoNome: json['musico_nome'],
      eventoNome: json['evento_nome'],
      observacao: json['observacao'],
      instrumentos: instrumentos,
      instrumentoNome: json['instrumento_nome'],
      confirmado: json['confirmado'] ?? false,
      criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id! > 0) 'id': id,
      'musico': musicoId,
      'evento': eventoId,
      'instrumentos': instrumentos ?? [],
      'observacao': observacao ?? '',
    };
  }

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
