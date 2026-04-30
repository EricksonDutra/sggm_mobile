import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/views/escalas_page.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';

class EventoEscalaTab extends StatelessWidget {
  const EventoEscalaTab({
    super.key,
    required this.evento,
    required this.isLider,
    required this.onNotificarMusico,
  });

  final Evento evento;
  final bool isLider;
  final Future<void> Function(Escala) onNotificarMusico;

  @override
  Widget build(BuildContext context) {
    return Consumer<EscalasProvider>(
      builder: (context, provider, _) {
        final escalasDoEvento = provider.escalas.where((e) => e.eventoId == evento.id).toList();
        final rascunhos = provider.getRascunhos(evento.id!);
        final todasEscalas = [...escalasDoEvento, ...rascunhos];

        return Stack(
          children: [
            if (todasEscalas.isEmpty)
              const Center(child: Text('Ninguém escalado ainda.'))
            else
              ListView.builder(
                padding: EdgeInsets.only(bottom: isLider ? 80 : 8, top: 8, left: 8, right: 8),
                itemCount: todasEscalas.length,
                itemBuilder: (context, index) {
                  final item = todasEscalas[index];
                  final isRascunho = (item.id ?? 0) < 0;

                  return Card(
                    elevation: 2,
                    shape: isRascunho
                        ? RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.orange, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRascunho ? Colors.orange : Colors.orangeAccent,
                        child: Icon(isRascunho ? Icons.edit_outlined : Icons.person, color: Colors.white),
                      ),
                      title: Text(item.musicoNome ?? 'Músico', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isRascunho
                            ? '🕓 Rascunho — ${item.instrumentoNome ?? "instrumento não definido"}'
                            : 'Toca: ${item.instrumentoNome ?? "Não especificado"}',
                      ),
                      trailing: isLider
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isRascunho)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.orange),
                                    tooltip: 'Remover rascunho',
                                    onPressed: () => provider.removerRascunho(evento.id!, item.id!),
                                  )
                                else ...[
                                  IconButton(
                                    icon: const Icon(Icons.send_to_mobile, color: Colors.green),
                                    tooltip: 'Avisar no WhatsApp',
                                    onPressed: () => onNotificarMusico(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await ConfirmDeleteDialog.show(
                                        context,
                                        entityName: item.musicoNome ?? 'Músico',
                                        message:
                                            'Deseja remover ${item.musicoNome ?? "este músico"} da escala?\nEsta ação não pode ser desfeita.',
                                      );
                                      if (confirmed && context.mounted && item.id != null) {
                                        provider.deletarEscala(item.id!);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),

            // Banner publicar rascunhos
            if (isLider && rascunhos.isNotEmpty)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.orange[50],
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${rascunhos.length} rascunho(s) não publicado(s)',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await provider.publicarEscalas(evento.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok ? 'Escalas publicadas!' : provider.errorMessage ?? 'Erro ao publicar'),
                                backgroundColor: ok ? Colors.green : Colors.red,
                              ));
                            }
                          },
                          child: const Text('PUBLICAR', style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // FAB Escalar
            if (isLider)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EscalasPage()),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Escalar'),
                  backgroundColor: Colors.orangeAccent,
                ),
              ),
          ],
        );
      },
    );
  }
}
