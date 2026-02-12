import 'package:sggm/models/musicas.dart';

class Evento {
  final int? id;
  final String nome;
  final String dataEvento;
  final String local;
  final String? descricao;
  // NOVO: Lista de objetos Música completa (para exibição)
  final List<Musica>? repertorio;

  Evento({
    this.id,
    required this.nome,
    required this.dataEvento,
    required this.local,
    this.descricao,
    this.repertorio,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    var list = json['repertorio'] as List?;
    List<Musica>? repertorioList;

    if (list != null) {
      repertorioList = list.map((i) => Musica.fromJson(i)).toList();
    }

    return Evento(
      id: json['id'],
      nome: json['nome'],
      dataEvento: json['data_evento'] ?? '',
      local: json['local'],
      descricao: json['descricao'],
      repertorio: repertorioList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'data_evento': dataEvento,
      'local': local,
      'descricao': descricao,
    };
  }
}
