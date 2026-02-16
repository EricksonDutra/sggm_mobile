import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/musicas.dart';

class Evento {
  final int? id;
  final String nome;
  final String tipo;
  final String dataEvento;
  final String local;
  final String? descricao;
  final List<Musica>? repertorio;
  final List<Escala>? escalas;
  final DateTime? criadoEm;

  Evento({
    this.id,
    required this.nome,
    required this.dataEvento,
    required this.local,
    this.criadoEm,
    this.escalas,
    this.tipo = 'evento',
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
      tipo: json['tipo'] ?? 'CULTO',
      escalas: (json['escalas'] as List?)?.map((e) => Escala.fromJson(e)).toList(),
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
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
