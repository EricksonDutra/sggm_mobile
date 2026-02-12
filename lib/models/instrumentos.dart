class Instrumento {
  final int id;
  final String nome;

  Instrumento({required this.id, required this.nome});

  factory Instrumento.fromJson(Map<String, dynamic> json) {
    return Instrumento(
      id: json['id'],
      nome: json['nome'],
    );
  }
}
