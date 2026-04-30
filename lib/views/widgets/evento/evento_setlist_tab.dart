import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/views/comentarios_page.dart';
import 'package:sggm/views/musica_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/gerenciar_setlist_dialog.dart';

class EventoSetlistTab extends StatefulWidget {
  const EventoSetlistTab({
    super.key,
    required this.evento,
    required this.isLider,
  });

  final Evento evento;
  final bool isLider;

  @override
  State<EventoSetlistTab> createState() => _EventoSetlistTabState();
}

class _EventoSetlistTabState extends State<EventoSetlistTab> {
  bool _salvandoOrdem = false;

  bool get _eventoJaAconteceu {
    try {
      return DateTime.parse(widget.evento.dataEvento).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _onReorder(
    BuildContext context,
    List musicas,
    int oldIndex,
    int newIndex,
    EventoProvider provider,
  ) async {
    // Ajuste padrão do ReorderableListView
    if (newIndex > oldIndex) newIndex -= 1;

    // Reordena localmente primeiro (feedback imediato)
    final item = musicas.removeAt(oldIndex);
    musicas.insert(newIndex, item);
    setState(() {});

    // Persiste no backend
    setState(() => _salvandoOrdem = true);
    final ids = musicas.map<int>((m) => m.id as int).toList();
    final sucesso = await provider.atualizarRepertorio(widget.evento.id!, ids);
    setState(() => _salvandoOrdem = false);

    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar a nova ordem'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoProvider>(
      builder: (context, provider, _) {
        final eventoAtual = provider.eventos.firstWhere(
          (e) => e.id == widget.evento.id,
          orElse: () => widget.evento,
        );
        final musicas = List.from(eventoAtual.repertorio ?? []);

        return Column(
          children: [
            // Indicador de salvamento
            if (_salvandoOrdem)
              Container(
                color: Colors.teal.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Salvando ordem...',
                      style: TextStyle(fontSize: 12, color: Colors.teal),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: musicas.isEmpty
                  ? const Center(child: Text('Nenhuma música selecionada'))
                  : widget.isLider
                      ? ReorderableListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: musicas.length,
                          onReorder: (oldIndex, newIndex) => _onReorder(
                            context,
                            musicas,
                            oldIndex,
                            newIndex,
                            provider,
                          ),
                          itemBuilder: (context, index) {
                            final musica = musicas[index];
                            return _MusicaSetlistCard(
                              key: ValueKey(musica.id),
                              musica: musica,
                              index: index,
                              isLider: widget.isLider,
                              eventoJaAconteceu: _eventoJaAconteceu,
                              evento: eventoAtual,
                              showDragHandle: true,
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: musicas.length,
                          itemBuilder: (context, index) {
                            final musica = musicas[index];
                            return _MusicaSetlistCard(
                              key: ValueKey(musica.id),
                              musica: musica,
                              index: index,
                              isLider: widget.isLider,
                              eventoJaAconteceu: _eventoJaAconteceu,
                              evento: eventoAtual,
                              showDragHandle: false,
                            );
                          },
                        ),
            ),

            if (widget.isLider)
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

/// Card individual da música no setlist
class _MusicaSetlistCard extends StatelessWidget {
  const _MusicaSetlistCard({
    super.key,
    required this.musica,
    required this.index,
    required this.isLider,
    required this.eventoJaAconteceu,
    required this.evento,
    required this.showDragHandle,
  });

  final dynamic musica;
  final int index;
  final bool isLider;
  final bool eventoJaAconteceu;
  final Evento evento;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        // Número de posição no setlist
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          musica.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${musica.artistaNome}${musica.tom != null ? '  •  Tom: ${musica.tom}' : ''}',
        ),
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
                color: eventoJaAconteceu ? Colors.teal : Colors.grey[600],
              ),
              tooltip: eventoJaAconteceu ? 'Comentários' : 'Disponível após o evento',
              onPressed: eventoJaAconteceu
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComentariosPage(
                            eventoId: evento.id!,
                            eventoNome: evento.nome,
                            eventoDataEvento: evento.dataEvento,
                            musica: musica,
                          ),
                        ),
                      )
                  : null,
            ),
            const SizedBox(width: 4),
            // Handle de arrastar (só para líderes, substituindo a seta)
            if (showDragHandle)
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_handle,
                  color: Colors.grey,
                  size: 22,
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MusicaDetalhesPage(musica: musica)),
        ),
      ),
    );
  }
}
