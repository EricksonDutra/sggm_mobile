class Instrumento {
  final int id;
  final String nome;

  Instrumento({
    required this.id,
    required this.nome,
  });

  factory Instrumento.fromJson(Map<String, dynamic> json) {
    return Instrumento(
      id: json['id'] as int,
      nome: json['nome'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
