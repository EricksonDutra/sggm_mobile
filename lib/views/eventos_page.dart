import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';
import 'evento_detalhes_page.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarEventos();
    });
  }

  Future<void> _carregarEventos() async {
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
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final nomeController = TextEditingController(text: 'Culto');
    final localController = TextEditingController(text: 'IPB Ponta Porã');
    DateTime? dataHoraEnsaio;
    DateTime dataSelecionada = DateTime.now();
    TimeOfDay horarioSelecionado = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: localController,
                  decoration: const InputDecoration(
                    labelText: 'Local',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('pt', 'BR'),
                      helpText: 'Selecione a data do evento',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (picked != null && picked != dataSelecionada) {
                      setState(() => dataSelecionada = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do Evento',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: horarioSelecionado,
                      helpText: 'Selecione o horário',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (picked != null) {
                      setState(() => horarioSelecionado = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataHoraEnsaio ?? dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      helpText: 'Data do ensaio',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (data == null) return;
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: dataHoraEnsaio != null ? TimeOfDay.fromDateTime(dataHoraEnsaio!) : TimeOfDay.now(),
                    );
                    if (hora == null) return;
                    setState(() {
                      dataHoraEnsaio = DateTime(
                        data.year,
                        data.month,
                        data.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data e hora do ensaio (opcional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.event_available),
                      // botão para limpar
                      suffix: dataHoraEnsaio != null
                          ? GestureDetector(
                              onTap: () => setState(() => dataHoraEnsaio = null),
                              child: const Icon(Icons.close, size: 18),
                            )
                          : null,
                    ),
                    child: Text(
                      dataHoraEnsaio != null
                          ? '${dataHoraEnsaio!.day.toString().padLeft(2, '0')}/'
                              '${dataHoraEnsaio!.month.toString().padLeft(2, '0')}/'
                              '${dataHoraEnsaio!.year}  '
                              '${dataHoraEnsaio!.hour.toString().padLeft(2, '0')}:'
                              '${dataHoraEnsaio!.minute.toString().padLeft(2, '0')}'
                          : 'Toque para selecionar (opcional)',
                      style: TextStyle(
                        color: dataHoraEnsaio != null ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty || localController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha todos os campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final dataComHorario = DateTime(
                  dataSelecionada.year,
                  dataSelecionada.month,
                  dataSelecionada.day,
                  horarioSelecionado.hour,
                  horarioSelecionado.minute,
                );

                final novoEvento = Evento(
                  nome: nomeController.text,
                  local: localController.text,
                  dataEvento: dataComHorario.toIso8601String(),
                  descricao: 'Criado via App',
                  dataHoraEnsaio: dataHoraEnsaio,
                );

                // ✅ CORREÇÃO: captura o bool retornado
                final provider = Provider.of<EventoProvider>(context, listen: false);
                final sucesso = await provider.adicionarEvento(novoEvento);

                if (!ctx.mounted) return;

                if (sucesso) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento criado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // ✅ Mostra a mensagem de erro real do backend
                  final erro = provider.errorMessage ?? 'Erro ao criar evento';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(erro),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, Evento evento) {
    final nomeController = TextEditingController(text: evento.nome);
    final localController = TextEditingController(text: evento.local);

    // Pré-preencher data e horário a partir do dataEvento
    final dataAtual = DateTime.parse(evento.dataEvento);
    DateTime dataSelecionada = dataAtual;
    TimeOfDay horarioSelecionado = TimeOfDay(
      hour: dataAtual.hour,
      minute: dataAtual.minute,
    );
    DateTime? dataHoraEnsaio = evento.dataHoraEnsaio;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: localController,
                  decoration: const InputDecoration(
                    labelText: 'Local',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('pt', 'BR'),
                      helpText: 'Selecione a data do evento',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (picked != null) setState(() => dataSelecionada = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do Evento',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: horarioSelecionado,
                      helpText: 'Selecione o horário',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (picked != null) setState(() => horarioSelecionado = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataHoraEnsaio ?? dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      helpText: 'Data do ensaio',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );
                    if (data == null) return;
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: dataHoraEnsaio != null ? TimeOfDay.fromDateTime(dataHoraEnsaio!) : TimeOfDay.now(),
                    );
                    if (hora == null) return;
                    setState(() {
                      dataHoraEnsaio = DateTime(
                        data.year,
                        data.month,
                        data.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data e hora do ensaio (opcional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.event_available),
                      suffix: dataHoraEnsaio != null
                          ? GestureDetector(
                              onTap: () => setState(() => dataHoraEnsaio = null),
                              child: const Icon(Icons.close, size: 18),
                            )
                          : null,
                    ),
                    child: Text(
                      dataHoraEnsaio != null
                          ? '${dataHoraEnsaio!.day.toString().padLeft(2, '0')}/'
                              '${dataHoraEnsaio!.month.toString().padLeft(2, '0')}/'
                              '${dataHoraEnsaio!.year}  '
                              '${dataHoraEnsaio!.hour.toString().padLeft(2, '0')}:'
                              '${dataHoraEnsaio!.minute.toString().padLeft(2, '0')}'
                          : 'Toque para selecionar (opcional)',
                      style: TextStyle(
                        color: dataHoraEnsaio != null ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty || localController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha todos os campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final dataComHorario = DateTime(
                  dataSelecionada.year,
                  dataSelecionada.month,
                  dataSelecionada.day,
                  horarioSelecionado.hour,
                  horarioSelecionado.minute,
                );

                final eventoAtualizado = Evento(
                  id: evento.id,
                  nome: nomeController.text,
                  local: localController.text,
                  dataEvento: dataComHorario.toIso8601String(),
                  descricao: evento.descricao,
                  dataHoraEnsaio: dataHoraEnsaio,
                );

                final provider = Provider.of<EventoProvider>(context, listen: false);
                final sucesso = await provider.atualizarEvento(evento.id!, eventoAtualizado);

                if (!ctx.mounted) return;

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sucesso
                        ? 'Evento atualizado com sucesso!'
                        : provider.errorMessage ?? 'Erro ao atualizar evento'),
                    backgroundColor: sucesso ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
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
          ),
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoAdicionar(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<EventoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
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
                        if (evento.dataHoraEnsaio != null)
                          Row(
                            children: [
                              const Icon(Icons.event_available, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Ensaio: '
                                '${evento.dataHoraEnsaio!.day.toString().padLeft(2, '0')}/'
                                '${evento.dataHoraEnsaio!.month.toString().padLeft(2, '0')}/'
                                '${evento.dataHoraEnsaio!.year}  '
                                '${evento.dataHoraEnsaio!.hour.toString().padLeft(2, '0')}:'
                                '${evento.dataHoraEnsaio!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: isLider
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'editar') {
                                _mostrarDialogoEditar(context, evento);
                              } else if (value == 'detalhes') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventoDetalhesPage(evento: evento),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'detalhes',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Ver detalhes'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                                    SizedBox(width: 8),
                                    Text('Editar evento', style: TextStyle(color: Colors.teal)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
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
