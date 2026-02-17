class Musica {
  final int? id;
  final String titulo;
  final int artistaId; // ✅ ID do artista (ForeignKey)
  final String artistaNome;
  final String? tom;
  final String? linkCifra;
  final String? linkYoutube;

  Musica({
    this.id,
    required this.titulo,
    required this.artistaId,
    required this.artistaNome,
    this.tom,
    this.linkCifra,
    this.linkYoutube,
  });

  factory Musica.fromJson(Map<String, dynamic> json) {
    return Musica(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sem Título',
      artistaId: json['artista'] as int, // ✅ ID do artista
      artistaNome: json['artista_nome'] as String,
      tom: json['tom'], // Pode ser null
      linkCifra: json['link_cifra'],
      linkYoutube: json['link_youtube'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'artista': artistaId,
      'tom': tom,
      'link_cifra': (linkCifra != null && linkCifra!.isEmpty) ? null : linkCifra,
      'link_youtube': (linkYoutube != null && linkYoutube!.isEmpty) ? null : linkYoutube,
    };
  }

  String get tituloCompleto => '$titulo - $artistaNome';
}
