import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/instrumentos.dart';

class EscalasPage extends StatefulWidget {
  const EscalasPage({super.key});

  @override
  State<EscalasPage> createState() => _EscalasPageState();
}

class _EscalasPageState extends State<EscalasPage> {
  bool _isLoading = true;
  String _filtro = 'todas'; // 'todas', 'pendentes', 'confirmadas'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTudo();
    });
  }

  Future<void> _carregarTudo() async {
    setState(() => _isLoading = true);
    try {
      final escalasProvider = Provider.of<EscalasProvider>(context, listen: false);
      final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
      final eventosProvider = Provider.of<EventoProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      await Future.wait([
        escalasProvider.listarEscalas(),
        musicosProvider.listarMusicos(),
        eventosProvider.listarEventos(),
        instrumentosProvider.listarInstrumentos(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Escala> _filtrarEscalas(List<Escala> escalas) {
    switch (_filtro) {
      case 'pendentes':
        return escalas.where((e) => !e.confirmado).toList();
      case 'confirmadas':
        return escalas.where((e) => e.confirmado).toList();
      default:
        return escalas;
    }
  }

  Future<void> _confirmarPresenca(BuildContext context, Escala escala, bool confirmado) async {
    try {
      await context.read<EscalasProvider>().confirmarPresenca(escala.id!, confirmado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmado ? '✅ Presença confirmada!' : '❌ Presença desmarcada',
            ),
            backgroundColor: confirmado ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final obsController = TextEditingController();
    final outroInstrumentoController = TextEditingController();

    int? selectedMusicoId;
    int? selectedEventoId;
    String? selectedInstrumento;
    bool mostrarCampoOutro = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              // ✅ Usar Dialog ao invés de AlertDialog para mais controle
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'Nova Escala',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- MÚSICO ---
                      Consumer<MusicosProvider>(
                        builder: (context, provider, child) {
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Músico *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            initialValue: selectedMusicoId,
                            items: provider.musicos.map((musico) {
                              return DropdownMenuItem<int>(
                                value: musico.id,
                                child: Text(
                                  musico.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              setStateDialog(() {
                                selectedMusicoId = valor;

                                if (valor != null) {
                                  final musico = provider.musicos.firstWhere((m) => m.id == valor);
                                  final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);

                                  if (musico.instrumentoPrincipal != null &&
                                      musico.instrumentoPrincipal.toString().isNotEmpty) {
                                    bool existeNaLista = instProvider.instrumentos
                                        .any((i) => i.nome == musico.instrumentoPrincipal.toString());

                                    if (existeNaLista) {
                                      selectedInstrumento = musico.instrumentoPrincipal.toString();
                                      mostrarCampoOutro = false;
                                    } else {
                                      selectedInstrumento = 'Outro';
                                      mostrarCampoOutro = true;
                                      outroInstrumentoController.text = musico.instrumentoPrincipal.toString();
                                    }
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- EVENTO ---
                      Consumer<EventoProvider>(
                        builder: (context, provider, child) {
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Evento *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            initialValue: selectedEventoId,
                            items: provider.eventos.map((evento) {
                              return DropdownMenuItem<int>(
                                value: evento.id,
                                child: Text(
                                  '${evento.nome} (${evento.dataEvento.split('T')[0]})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (valor) => setStateDialog(() => selectedEventoId = valor),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- INSTRUMENTOS ---
                      Consumer<InstrumentosProvider>(
                        builder: (context, provider, child) {
                          var listaOpcoes = provider.instrumentos.map((i) => i.nome).toList();
                          listaOpcoes.add('Outro');

                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Instrumento *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            initialValue: selectedInstrumento,
                            items: listaOpcoes.map((nome) {
                              return DropdownMenuItem<String>(
                                value: nome,
                                child: Text(
                                  nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              setStateDialog(() {
                                selectedInstrumento = valor;
                                mostrarCampoOutro = (valor == 'Outro');
                                if (!mostrarCampoOutro) outroInstrumentoController.clear();
                              });
                            },
                          );
                        },
                      ),

                      if (mostrarCampoOutro) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: outroInstrumentoController,
                          decoration: const InputDecoration(
                            labelText: 'Qual instrumento?',
                            hintText: 'Digite o nome',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextField(
                        controller: obsController,
                        decoration: const InputDecoration(
                          labelText: 'Observação (opcional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),

                      // Botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedMusicoId == null || selectedEventoId == null || selectedInstrumento == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Preencha os campos obrigatórios!')),
                                );
                                return;
                              }

                              int? instrumentoIdFinal;

                              if (selectedInstrumento == 'Outro') {
                                if (outroInstrumentoController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Digite o instrumento!')),
                                  );
                                  return;
                                }
                                instrumentoIdFinal = null;
                              } else {
                                final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
                                final instrumento = instProvider.instrumentos.firstWhere(
                                  (i) => i.nome == selectedInstrumento,
                                  orElse: () => Instrumento(id: 0, nome: ''),
                                );
                                instrumentoIdFinal = instrumento.id;
                              }

                              final novaEscala = Escala(
                                musicoId: selectedMusicoId!,
                                eventoId: selectedEventoId!,
                                instrumentoNoEvento: instrumentoIdFinal,
                                observacao: obsController.text,
                              );

                              Provider.of<EscalasProvider>(context, listen: false)
                                  .adicionarEscala(novaEscala)
                                  .then((_) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Escala criada com sucesso!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }).catchError((e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro: $e')),
                                );
                              });
                            },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: _filtro == 'todas',
            onSelected: (selected) {
              if (selected) setState(() => _filtro = 'todas');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pendentes'),
            selected: _filtro == 'pendentes',
            onSelected: (selected) {
              if (selected) setState(() => _filtro = 'pendentes');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Confirmadas'),
            selected: _filtro == 'confirmadas',
            onSelected: (selected) {
              if (selected) setState(() => _filtro = 'confirmadas');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEscalaCard(BuildContext context, Escala escala, bool isLider, int? currentUserId) {
    // Verificar se é a escala do próprio músico
    final isMinhaEscala = currentUserId != null && escala.musicoId == currentUserId;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com status
            Row(
              children: [
                Icon(
                  escala.confirmado ? Icons.check_circle : Icons.pending,
                  color: escala.confirmado ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escala.eventoNome ?? 'Evento #${escala.eventoId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        escala.confirmado ? 'Confirmado' : 'Pendente',
                        style: TextStyle(
                          color: escala.confirmado ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de deletar - Só para líder/admin
                if (isLider)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmarDelecao(context, escala),
                  ),
              ],
            ),

            const Divider(height: 24),

            // Informações - APENAS campos que existem
            _buildInfoRow(Icons.person, escala.musicoNome ?? 'Músico #${escala.musicoId}'),

            if (escala.instrumentoNoEvento != null) _buildInfoRow(Icons.music_note, escala.instrumentoNome.toString()),

            if (escala.observacao != null && escala.observacao!.isNotEmpty)
              _buildInfoRow(Icons.note, escala.observacao!),

            // Botão de confirmar - Apenas para o próprio músico ou líder
            if (isMinhaEscala || isLider) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarPresenca(context, escala, !escala.confirmado),
                  icon: Icon(escala.confirmado ? Icons.cancel : Icons.check),
                  label: Text(
                    escala.confirmado ? 'Desmarcar Presença' : 'Confirmar Presença',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: escala.confirmado ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarDelecao(BuildContext context, Escala escala) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja remover ${escala.musicoNome ?? "este músico"} da escala?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (escala.id != null) {
                context.read<EscalasProvider>().deletarEscala(escala.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLider = auth.userData?['is_lider'] ?? false;
    final currentUserId = auth.userData?['musico_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Escalas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarTudo,
          ),
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoAdicionar(context),
              tooltip: 'Criar Escala',
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<EscalasProvider>(
              builder: (context, provider, child) {
                if (provider.escalas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma escala registrada',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLider ? 'Toque no + para criar uma escala' : 'Aguarde ser escalado pelo líder',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final escalasFiltradas = _filtrarEscalas(provider.escalas);

                return Column(
                  children: [
                    _buildFiltros(),
                    Expanded(
                      child: escalasFiltradas.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma escala $_filtro',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregarTudo,
                              child: ListView.builder(
                                itemCount: escalasFiltradas.length,
                                itemBuilder: (context, index) {
                                  return _buildEscalaCard(
                                    context,
                                    escalasFiltradas[index],
                                    isLider,
                                    currentUserId,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
