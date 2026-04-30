import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/views/widgets/dialogs/evento_form_dialog.dart';
import 'package:sggm/views/widgets/evento/evento_card.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarEventos());
  }

  Future<void> _carregarEventos() async {
    try {
      await Provider.of<EventoProvider>(context, listen: false).listarEventos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar eventos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLider = Provider.of<AuthProvider>(context).isLider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarEventos),
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => EventoFormDialog.showAdicionar(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<EventoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 5,
              itemBuilder: (_, __) => const ShimmerCard(),
            );
          }

          if (provider.eventos.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum evento encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _carregarEventos,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.eventos.length,
              itemBuilder: (context, index) => EventoCard(
                evento: provider.eventos[index],
                isLider: isLider,
              ),
            ),
          );
        },
      ),
    );
  }
}
