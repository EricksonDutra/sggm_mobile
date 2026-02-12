class Musico {
  final int? id; // Backend envia 'id', não 'musicoId'
  final String nome;
  final String telefone;
  final String email;
  final String? endereco;
  final String? instrumentoPrincipal; // Novo campo que criamos no Django

  Musico({
    this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    this.endereco,
    this.instrumentoPrincipal,
  });

  // Mapeia do Python (snake_case) para Dart
  factory Musico.fromJson(Map<String, dynamic> json) {
    return Musico(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      endereco: json['endereco'],
      // Mapeia o campo novo se existir
      instrumentoPrincipal: json['instrumento_principal'],
    );
  }

  // Mapeia do Dart para Python (snake_case)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      // Envia no formato que o Django espera
      'instrumento_principal': instrumentoPrincipal,
    };
  }
}
