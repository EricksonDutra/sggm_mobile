class ComentarioPerformance {
  final int id;
  final int evento;
  final int? musica;
  final int autor;
  final String autorNome;
  final String texto;
  final DateTime criadoEm;
  final DateTime? editadoEm;
  final int totalReacoes;
  final bool euCurto;
  final bool podeEditar;

  ComentarioPerformance({
    required this.id,
    required this.evento,
    this.musica,
    required this.autor,
    required this.autorNome,
    required this.texto,
    required this.criadoEm,
    this.editadoEm,
    required this.totalReacoes,
    required this.euCurto,
    required this.podeEditar,
  });

  factory ComentarioPerformance.fromJson(Map<String, dynamic> json) {
    return ComentarioPerformance(
      id: json['id'],
      evento: json['evento'],
      musica: json['musica'],
      autor: json['autor'],
      autorNome: json['autor_nome'] ?? '',
      texto: json['texto'],
      criadoEm: DateTime.parse(json['criado_em']),
      editadoEm: json['editado_em'] != null ? DateTime.parse(json['editado_em']) : null,
      totalReacoes: json['total_reacoes'] ?? 0,
      euCurto: json['eu_curto'] ?? false,
      podeEditar: json['pode_editar'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'evento': evento,
        'musica': musica,
        'texto': texto,
      };

  ComentarioPerformance copyWith({
    int? totalReacoes,
    bool? euCurto,
    String? texto,
    bool? podeEditar,
  }) {
    return ComentarioPerformance(
      id: id,
      evento: evento,
      musica: musica,
      autor: autor,
      autorNome: autorNome,
      texto: texto ?? this.texto,
      criadoEm: criadoEm,
      editadoEm: editadoEm,
      totalReacoes: totalReacoes ?? this.totalReacoes,
      euCurto: euCurto ?? this.euCurto,
      podeEditar: podeEditar ?? this.podeEditar,
    );
  }
}
