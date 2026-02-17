class Artista {
  final int id;
  final String nome;
  final int? totalMusicas;
  final DateTime? criadoEm;

  Artista({
    required this.id,
    required this.nome,
    this.totalMusicas,
    this.criadoEm,
  });

  factory Artista.fromJson(Map<String, dynamic> json) {
    return Artista(
      id: json['id'],
      nome: json['nome'],
      totalMusicas: json['total_musicas'],
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
