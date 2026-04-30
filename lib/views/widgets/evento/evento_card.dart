import 'package:flutter/material.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/util/date_formatter.dart';
import 'package:sggm/views/evento_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/evento_form_dialog.dart';

class EventoCard extends StatelessWidget {
  const EventoCard({super.key, required this.evento, required this.isLider});

  final Evento evento;
  final bool isLider;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.event, color: Colors.white),
        ),
        title: Text(evento.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(DateFormatter.fromIso(evento.dataEvento)),
            ]),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(evento.local),
            ]),
            if (evento.dataHoraEnsaio != null)
              Row(children: [
                const Icon(Icons.event_available, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Ensaio: ${DateFormatter.dataHora(evento.dataHoraEnsaio!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
          ],
        ),
        trailing: isLider
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'editar') {
                    EventoFormDialog.showEditar(context, evento);
                  } else if (value == 'detalhes') {
                    _abrirDetalhes(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'detalhes',
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Ver detalhes'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Editar evento', style: TextStyle(color: Colors.teal)),
                    ]),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _abrirDetalhes(context),
      ),
    );
  }

  void _abrirDetalhes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventoDetalhesPage(evento: evento)),
    );
  }
}
