import 'package:flutter/material.dart';
import 'package:sggm/models/musicas.dart';

class MusicaListTile extends StatelessWidget {
  const MusicaListTile({
    super.key,
    required this.musica,
    required this.isLider,
    required this.onTap,
    required this.onEditar,
    required this.onExcluir,
    required this.onAbrirCifra,
  });

  final Musica musica;
  final bool isLider;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onAbrirCifra;

  bool get _temCifra => musica.linkCifra != null && musica.linkCifra!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            musica.tom?.isNotEmpty == true ? musica.tom! : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(musica.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(musica.artistaNome),
            if (_temCifra)
              const Row(
                children: [
                  Icon(Icons.link, size: 12, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Cifra disponível', style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
          ],
        ),
        trailing: isLider
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') onEditar();
                  if (value == 'cifra') onAbrirCifra();
                  if (value == 'excluir') onExcluir();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar', style: TextStyle(color: Colors.blue)),
                    ]),
                  ),
                  if (_temCifra)
                    const PopupMenuItem(
                      value: 'cifra',
                      child: Row(children: [
                        Icon(Icons.open_in_browser, size: 18),
                        SizedBox(width: 8),
                        Text('Abrir Cifra'),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              )
            : _temCifra
                ? IconButton(
                    icon: const Icon(Icons.open_in_browser, color: Colors.blue),
                    tooltip: 'Abrir Cifra',
                    onPressed: onAbrirCifra,
                  )
                : null,
        onTap: onTap,
      ),
    );
  }
}
