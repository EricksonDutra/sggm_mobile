import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/views/comentarios_page.dart';
import 'package:sggm/views/musica_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/gerenciar_setlist_dialog.dart';

class EventoSetlistTab extends StatelessWidget {
  const EventoSetlistTab({super.key, required this.evento, required this.isLider});

  final Evento evento;
  final bool isLider;

  bool get _eventoJaAconteceu {
    try {
      return DateTime.parse(evento.dataEvento).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoProvider>(
      builder: (context, provider, _) {
        final eventoAtual = provider.eventos.firstWhere(
          (e) => e.id == evento.id,
          orElse: () => evento,
        );
        final musicas = eventoAtual.repertorio ?? [];

        return Column(
          children: [
            Expanded(
              child: musicas.isEmpty
                  ? const Center(child: Text('Nenhuma música selecionada'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: musicas.length,
                      itemBuilder: (context, index) {
                        final musica = musicas[index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                musica.tom ?? '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(musica.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(musica.artistaNome),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (musica.linkYoutube != null && musica.linkYoutube!.isNotEmpty)
                                  const Icon(Icons.play_circle, color: Colors.red, size: 20),
                                const SizedBox(width: 4),
                                if (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                                  const Icon(Icons.music_note, color: Colors.blue, size: 20),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20,
                                    color: _eventoJaAconteceu ? Colors.teal : Colors.grey[600],
                                  ),
                                  tooltip: _eventoJaAconteceu ? 'Comentários' : 'Disponível após o evento',
                                  onPressed: _eventoJaAconteceu
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComentariosPage(
                                                eventoId: eventoAtual.id!,
                                                eventoNome: eventoAtual.nome,
                                                eventoDataEvento: eventoAtual.dataEvento,
                                                musica: musica,
                                              ),
                                            ),
                                          )
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MusicaDetalhesPage(musica: musica)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (isLider)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('GERENCIAR MÚSICAS'),
                  onPressed: () => GerenciarSetlistDialog.show(context, eventoAtual),
                ),
              ),
            const Padding(padding: EdgeInsets.only(bottom: 16)),
          ],
        );
      },
    );
  }
}
