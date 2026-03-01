import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/views/evento_detalhes_page.dart';

class EventoDetalhesLoaderPage extends StatefulWidget {
  final String eventoId;

  const EventoDetalhesLoaderPage({super.key, required this.eventoId});

  @override
  State<EventoDetalhesLoaderPage> createState() => _EventoDetalhesLoaderPageState();
}

class _EventoDetalhesLoaderPageState extends State<EventoDetalhesLoaderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventoProvider>(context, listen: false).listarEventos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Carregando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final evento = provider.eventos.firstWhere(
            (e) => e.id.toString() == widget.eventoId,
          );
          return EventoDetalhesPage(evento: evento);
        } catch (_) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: Center(
              child: Text('Evento ${widget.eventoId} não encontrado.'),
            ),
          );
        }
      },
    );
  }
}
