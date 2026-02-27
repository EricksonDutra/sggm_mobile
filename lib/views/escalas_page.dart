// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';

class EscalasPage extends StatefulWidget {
  const EscalasPage({super.key});

  @override
  State<EscalasPage> createState() => _EscalasPageState();
}

class _EscalasPageState extends State<EscalasPage> {
  String _filtro = 'todas';

  // Evento selecionado no diálogo de adicionar — usado para controlar rascunhos
  int? _eventoRascunhoAtivo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTudo();
    });
  }

  Future<void> _carregarTudo() async {
    try {
      await Future.wait([
        Provider.of<EscalasProvider>(context, listen: false).listarEscalas(),
        Provider.of<MusicosProvider>(context, listen: false).listarMusicos(),
        Provider.of<EventoProvider>(context, listen: false).listarEventos(),
        Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar escalas: $e'), backgroundColor: Colors.red),
        );
      }
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
            content: Text(confirmado ? 'Presença confirmada!' : 'Presença desmarcada'),
            backgroundColor: confirmado ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao confirmar presença'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final obsController = TextEditingController();
    final outroInstrumentoController = TextEditingController();

    int? selectedMusicoId;
    String? selectedMusicoNome;
    int? selectedEventoId;
    String? selectedEventoNome;
    String? selectedInstrumento;
    String? selectedInstrumentoNome;
    bool mostrarCampoOutro = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Escala',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
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
                              child: Text(musico.nome, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedMusicoId = valor;
                              if (valor != null) {
                                final musico = provider.musicos.firstWhere((m) => m.id == valor);
                                selectedMusicoNome = musico.nome;
                                final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
                                if (musico.instrumentoPrincipal != null &&
                                    musico.instrumentoPrincipal.toString().isNotEmpty) {
                                  final existeNaLista = instProvider.instrumentos
                                      .any((i) => i.nome == musico.instrumentoPrincipal.toString());
                                  if (existeNaLista) {
                                    selectedInstrumento = musico.instrumentoPrincipal.toString();
                                    selectedInstrumentoNome = selectedInstrumento;
                                    mostrarCampoOutro = false;
                                  } else {
                                    selectedInstrumento = 'Outro';
                                    mostrarCampoOutro = true;
                                    outroInstrumentoController.text = musico.instrumentoPrincipal.toString();
                                    selectedInstrumentoNome = outroInstrumentoController.text;
                                  }
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
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
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedEventoId = valor;
                              if (valor != null) {
                                final evento = provider.eventos.firstWhere((e) => e.id == valor);
                                selectedEventoNome = evento.nome;
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<InstrumentosProvider>(
                      builder: (context, provider, child) {
                        final listaOpcoes = [
                          ...provider.instrumentos.map((i) => i.nome),
                          'Outro',
                        ];
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
                              child: Text(nome, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedInstrumento = valor;
                              mostrarCampoOutro = (valor == 'Outro');
                              if (!mostrarCampoOutro) {
                                outroInstrumentoController.clear();
                                selectedInstrumentoNome = valor;
                              }
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
                        onChanged: (v) => selectedInstrumentoNome = v,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedMusicoId == null || selectedEventoId == null || selectedInstrumento == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Preencha os campos obrigatórios!')),
                              );
                              return;
                            }

                            if (selectedInstrumento == 'Outro' && outroInstrumentoController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Digite o instrumento!')),
                              );
                              return;
                            }

                            int? instrumentoIdFinal;
                            if (selectedInstrumento != 'Outro') {
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
                              musicoNome: selectedMusicoNome,
                              eventoNome: selectedEventoNome,
                              instrumentoNoEvento: instrumentoIdFinal,
                              instrumentoNome: selectedInstrumentoNome,
                              observacao: obsController.text,
                            );

                            // Adiciona ao rascunho local — NÃO envia ao backend ainda
                            Provider.of<EscalasProvider>(context, listen: false).adicionarRascunho(novaEscala);

                            setState(() => _eventoRascunhoAtivo = selectedEventoId);

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✏️ Músico adicionado ao rascunho. Publique a escala para notificar.',
                                  ),
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _publicarEscala(BuildContext context, int eventoId) async {
    final provider = Provider.of<EscalasProvider>(context, listen: false);
    final qtd = provider.getRascunhos(eventoId).length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar Escala'),
        content: Text(
          'Isso enviará $qtd ${qtd == 1 ? "músico" : "músicos"} para o servidor e '
          'disparará as notificações push para cada um. Confirmar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await provider.publicarEscalas(eventoId);

    if (!mounted) return;

    if (ok) {
      setState(() => _eventoRascunhoAtivo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Escala publicada! Músicos foram notificados.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Erro ao publicar escala.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final isMinhaEscala = currentUserId != null && escala.musicoId == currentUserId;
    final isRascunho = (escala.id ?? 0) < 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRascunho ? const BorderSide(color: Colors.blue, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de rascunho
            if (isRascunho)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '✏️ Rascunho — não publicado',
                  style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            Row(
              children: [
                Icon(
                  isRascunho
                      ? Icons.edit_note
                      : escala.confirmado
                          ? Icons.check_circle
                          : Icons.pending,
                  color: isRascunho
                      ? Colors.blue
                      : escala.confirmado
                          ? Colors.green
                          : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escala.eventoNome ?? 'Evento #${escala.eventoId}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isRascunho
                            ? 'Aguardando publicação'
                            : escala.confirmado
                                ? 'Confirmado'
                                : 'Pendente',
                        style: TextStyle(
                          color: isRascunho
                              ? Colors.blue
                              : escala.confirmado
                                  ? Colors.green
                                  : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLider)
                  IconButton(
                    icon: Icon(
                      isRascunho ? Icons.close : Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: isRascunho ? 'Remover do rascunho' : 'Remover escala',
                    onPressed: () {
                      if (isRascunho) {
                        Provider.of<EscalasProvider>(context, listen: false)
                            .removerRascunho(escala.eventoId, escala.id!);
                      } else {
                        _confirmarDelecao(context, escala);
                      }
                    },
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, escala.musicoNome ?? 'Músico #${escala.musicoId}'),
            if (escala.instrumentoNoEvento != null) _buildInfoRow(Icons.music_note, escala.instrumentoNome.toString()),
            if (escala.observacao != null && escala.observacao!.isNotEmpty)
              _buildInfoRow(Icons.note, escala.observacao!),
            // Botão de confirmar presença — apenas em escalas já publicadas
            if (!isRascunho && (isMinhaEscala || isLider)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarPresenca(context, escala, !escala.confirmado),
                  icon: Icon(escala.confirmado ? Icons.cancel : Icons.check),
                  label: Text(escala.confirmado ? 'Desmarcar Presença' : 'Confirmar Presença'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: escala.confirmado ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            child: Text(text, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  void _confirmarDelecao(BuildContext context, Escala escala) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      entityName: escala.musicoNome ?? 'este músico',
      message: 'Deseja remover ${escala.musicoNome ?? "este músico"} da escala?\nEsta ação não pode ser desfeita.',
    );

    if (confirmed && context.mounted && escala.id != null) {
      try {
        await context.read<EscalasProvider>().deletarEscala(escala.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escala removida com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover escala'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
              tooltip: 'Adicionar ao Rascunho',
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<EscalasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(height: 160),
            );
          }

          // Mescla rascunhos + escalas publicadas para exibição
          final todasEscalas = [
            // Rascunhos do evento ativo (se houver) no topo
            if (_eventoRascunhoAtivo != null) ...provider.getRascunhos(_eventoRascunhoAtivo!),
            ...provider.escalas,
          ];

          if (todasEscalas.isEmpty) {
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

          // Filtro não se aplica a rascunhos
          final rascunhosAtivos =
              _eventoRascunhoAtivo != null ? provider.getRascunhos(_eventoRascunhoAtivo!) : <Escala>[];
          final escalasFiltradas = _filtrarEscalas(provider.escalas);
          final listaFinal = [...rascunhosAtivos, ...escalasFiltradas];

          return Column(
            children: [
              _buildFiltros(),

              // Banner de publicação — exibido quando há rascunhos pendentes
              if (isLider && _eventoRascunhoAtivo != null && rascunhosAtivos.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${rascunhosAtivos.length} ${rascunhosAtivos.length == 1 ? "músico aguardando" : "músicos aguardando"} publicação.',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Publicar'),
                        onPressed: () => _publicarEscala(context, _eventoRascunhoAtivo!),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: listaFinal.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma escala $_filtro',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarTudo,
                        child: ListView.builder(
                          itemCount: listaFinal.length,
                          itemBuilder: (context, index) {
                            return _buildEscalaCard(
                              context,
                              listaFinal[index],
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
