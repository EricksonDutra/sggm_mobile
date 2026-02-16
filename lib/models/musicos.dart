class Musico {
  final int? id;
  final String nome;
  final String telefone;
  final String email;
  final String? endereco;
  final int? instrumentoPrincipal;
  final String? instrumentoPrincipalNome;
  final String status; // ATIVO, INATIVO, AFASTADO
  final DateTime? dataInicioInatividade;
  final DateTime? dataFimInatividade;
  final String? motivoInatividade;
  final DateTime? dataCadastro;

  Musico({
    this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    this.endereco,
    this.instrumentoPrincipal,
    this.instrumentoPrincipalNome,
    this.status = 'ATIVO',
    this.dataInicioInatividade,
    this.dataFimInatividade,
    this.motivoInatividade,
    this.dataCadastro,
  });

  factory Musico.fromJson(Map<String, dynamic> json) {
    return Musico(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'] ?? '',
      email: json['email'],
      endereco: json['endereco'],
      instrumentoPrincipal: json['instrumento_principal'],
      instrumentoPrincipalNome: json['instrumento_principal_nome'],
      status: json['status'] ?? 'ATIVO',
      dataInicioInatividade:
          json['data_inicio_inatividade'] != null ? DateTime.parse(json['data_inicio_inatividade']) : null,
      dataFimInatividade: json['data_fim_inatividade'] != null ? DateTime.parse(json['data_fim_inatividade']) : null,
      motivoInatividade: json['motivo_inatividade'],
      dataCadastro: json['data_cadastro'] != null ? DateTime.parse(json['data_cadastro']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'instrumento_principal': instrumentoPrincipal,
      'status': status,
      'data_inicio_inatividade': dataInicioInatividade?.toIso8601String(),
      'data_fim_inatividade': dataFimInatividade?.toIso8601String(),
      'motivo_inatividade': motivoInatividade,
    };
  }
}
