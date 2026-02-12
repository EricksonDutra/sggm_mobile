import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'evento_detalhes_page.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarEventos();
    });
  }

  Future<void> _carregarEventos() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<EventoProvider>(context, listen: false).listarEventos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Função auxiliar para exibir um formulário simples de adição (para teste rápido)
  void _mostrarDialogoAdicionar(BuildContext context) {
    final nomeController = TextEditingController();
    final localController = TextEditingController();
    final dataController = TextEditingController(text: DateTime.now().toIso8601String());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: localController, decoration: const InputDecoration(labelText: 'Local')),
            TextField(controller: dataController, decoration: const InputDecoration(labelText: 'Data (ISO)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              String dataFinal = dataController.text;
              final novoEvento = Evento(
                nome: nomeController.text,
                local: localController.text,
                dataEvento: dataFinal,
                descricao: 'Criado via App',
              );

              // Chama o provider para salvar no Django
              Provider.of<EventoProvider>(context, listen: false)
                  .adicionarEvento(novoEvento)
                  .then((_) => Navigator.of(ctx).pop())
                  .catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLider = Provider.of<AuthProvider>(context).isLider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEventos,
          )
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoAdicionar(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<EventoProvider>(
              builder: (context, provider, child) {
                if (provider.eventos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum evento encontrado.\nVerifique a conexão com o Django.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _carregarEventos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: provider.eventos.length,
                    itemBuilder: (context, index) {
                      final evento = provider.eventos[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.event, color: Colors.white),
                          ),
                          title: Text(
                            evento.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  // Exibindo apenas o início da string de data para simplificar
                                  Text(evento.dataEvento.split('T')[0]),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(evento.local),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventoDetalhesPage(evento: evento),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
