import 'package:flutter/material.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';

class EventoHeaderTile extends StatelessWidget {
  const EventoHeaderTile({
    super.key,
    required this.eventoId,
    required this.escalasDoEvento,
    required this.evento,
    required this.isLider,
    required this.qtdRascunhos,
    required this.onPublicar,
  });

  final int eventoId;
  final List<Escala> escalasDoEvento;
  final Evento? evento;
  final bool isLider;
  final int qtdRascunhos;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final publicadas = escalasDoEvento.where((e) => (e.id ?? 0) >= 0).toList();
    final confirmadas = publicadas.where((e) => e.confirmado).length;
    final pendentes = publicadas.length - confirmadas;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              evento?.nome ?? escalasDoEvento.first.eventoNome ?? 'Evento #$eventoId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (publicadas.isNotEmpty)
            Text(
              '$confirmadas✅  $pendentes⏳',
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
          if (isLider && qtdRascunhos > 0) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send, size: 16),
              label: Text('Publicar ($qtdRascunhos)'),
              onPressed: onPublicar,
            ),
          ],
        ],
      ),
    );
  }
}
