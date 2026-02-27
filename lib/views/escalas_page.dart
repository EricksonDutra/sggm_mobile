// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';
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

  // ── helpers de data ──────────────────────────────────────────────────────

  /// Tenta parsear a string de data do evento em [DateTime].
  /// Suporta ISO completo ("2026-03-15T19:00:00") e apenas data ("2026-03-15").
  /// Quando só a data é fornecida, assume hora 00:00.
  DateTime? _parseDataEvento(String raw) {
    if (raw.trim().isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // fallback: "YYYY-MM-DD"
    final partes = raw.split('T').first.split('-');
    if (partes.length == 3) {
      final y = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final d = int.tryParse(partes[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    return null;
  }

  String _formatarData(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }

  String _formatarHora(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Um evento é considerado "passado" somente 3 horas APÓS seu horário de início.
  /// Assim um culto de sábado à noite não some da aba Próximas enquanto ainda está acontecendo.
  /// Se o evento não tiver hora definida, o corte é às 03:00 do dia seguinte.
  bool _eventoEhPassado(DateTime dataEvento) {
    final temHorario = dataEvento.hour != 0 || dataEvento.minute != 0;

    final DateTime corte;
    if (temHorario) {
      // tem hora: passa para Passadas 3h depois do início
      corte = dataEvento.add(const Duration(hours: 3));
    } else {
      // só data: passa para Passadas às 03:00 do dia seguinte
      corte = DateTime(dataEvento.year, dataEvento.month, dataEvento.day + 1, 3, 0);
    }

    return DateTime.now().isAfter(corte);
  }

  // ── filtros de status ────────────────────────────────────────────────────

  List<Escala> _filtrarPorStatus(List<Escala> escalas) {
    switch (_filtro) {
      case 'pendentes':
        return escalas.where((e) => !e.confirmado).toList();
      case 'confirmadas':
        return escalas.where((e) => e.confirmado).toList();
      default:
        return escalas;
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
            onSelected: (v) {
              if (v) setState(() => _filtro = 'todas');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pendentes'),
            selected: _filtro == 'pendentes',
            onSelected: (v) {
              if (v) setState(() => _filtro = 'pendentes');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Confirmadas'),
            selected: _filtro == 'confirmadas',
            onSelected: (v) {
              if (v) setState(() => _filtro = 'confirmadas');
            },
          ),
        ],
      ),
    );
  }

  // ── ações ────────────────────────────────────────────────────────────────

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

  Future<void> _publicarEscala(BuildContext context, int eventoId) async {
    final provider = context.read<EscalasProvider>();
    final qtd = provider.getRascunhos(eventoId).length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar escala'),
        content: Text(
          'Isso enviará $qtd ${qtd == 1 ? "músico" : "músicos"} para o servidor '
          'e disparará as notificações push. Confirmar?',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Escala publicada! Músicos notificados.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao publicar escala'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── diálogo de adicionar rascunho ────────────────────────────────────────

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
                      'Nova Escala (rascunho)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Músico
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

                    // Evento
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

                    // Instrumento
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
                          onPressed: () {
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

                            Provider.of<EscalasProvider>(context, listen: false).adicionarRascunho(novaEscala);

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✏️ Adicionado ao rascunho. Publique a escala para notificar.',
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

  // ── card de escala ───────────────────────────────────────────────────────

  Widget _buildEscalaItem(BuildContext context, Escala escala, bool isLider, int? currentUserId) {
    final isMinhaEscala = currentUserId != null && escala.musicoId == currentUserId;
    final isRascunho = (escala.id ?? 0) < 0;

    final statusIcon = isRascunho
        ? Icons.edit_note
        : escala.confirmado
            ? Icons.check_circle
            : Icons.pending;

    final statusColor = isRascunho
        ? Colors.blue
        : escala.confirmado
            ? Colors.green
            : Colors.orange;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(statusIcon, color: statusColor, size: 30),
            title: Text(escala.musicoNome ?? 'Músico #${escala.musicoId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (escala.instrumentoNome != null && escala.instrumentoNome!.toString().isNotEmpty)
                  Text('🎵 ${escala.instrumentoNome}'),
                if (escala.observacao != null && escala.observacao!.isNotEmpty) Text('📝 ${escala.observacao}'),
                Text(
                  isRascunho ? 'Rascunho (não publicado)' : (escala.confirmado ? 'Confirmado' : 'Pendente'),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: isLider
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: isRascunho ? 'Remover do rascunho' : 'Remover escala',
                    onPressed: () {
                      if (isRascunho) {
                        context.read<EscalasProvider>().removerRascunho(escala.eventoId, escala.id!);
                      } else {
                        _confirmarDelecao(context, escala);
                      }
                    },
                  )
                : null,
          ),
          if (!isRascunho && (isMinhaEscala || isLider))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
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
            const SnackBar(content: Text('Escala removida com sucesso'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao remover escala'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ── cabeçalho de evento ──────────────────────────────────────────────────

  Widget _buildEventoHeader({
    required BuildContext context,
    required int eventoId,
    required List<Escala> escalasDoEvento,
    required Evento? evento,
    required bool isLider,
  }) {
    final provider = context.read<EscalasProvider>();
    final rascunhos = provider.getRascunhos(eventoId);
    final total = escalasDoEvento.where((e) => (e.id ?? 0) >= 0).length;
    final confirmadas = escalasDoEvento.where((e) => e.confirmado).length;
    final pendentes = total - confirmadas;

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
          if (total > 0)
            Text(
              '$confirmadas✅  $pendentes⏳',
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
          if (isLider && rascunhos.isNotEmpty) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send, size: 16),
              label: Text('Publicar (${rascunhos.length})'),
              onPressed: () => _publicarEscala(context, eventoId),
            ),
          ],
        ],
      ),
    );
  }

  // ── lista agrupada ───────────────────────────────────────────────────────

  Widget _buildListaAgrupada({
    required BuildContext context,
    required List<Escala> escalas,
    required Map<int, Evento> eventosMap,
    required bool isLider,
    required int? currentUserId,
    required bool isPassadas,
  }) {
    if (escalas.isEmpty) {
      return Center(
        child: Text(
          isPassadas ? 'Nenhuma escala passada' : 'Nenhuma escala próxima',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Agrupa por eventoId
    final Map<int, List<Escala>> porEvento = {};
    for (final e in escalas) {
      porEvento.putIfAbsent(e.eventoId, () => []);
      porEvento[e.eventoId]!.add(e);
    }

    final eventoIds = porEvento.keys.toList();

    // Próximas: mais próxima primeiro (ASC)
    // Passadas: mais recente primeiro (DESC)
    eventoIds.sort((a, b) {
      final da = eventosMap[a] != null ? _parseDataEvento(eventosMap[a]!.dataEvento) : null;
      final db = eventosMap[b] != null ? _parseDataEvento(eventosMap[b]!.dataEvento) : null;

      if (da == null && db == null) return a.compareTo(b);
      if (da == null) return 1;
      if (db == null) return -1;

      final cmp = da.compareTo(db);
      return isPassadas ? -cmp : cmp; // inverte para passadas
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final eventoId in eventoIds) ...[
          _buildEventoHeader(
            context: context,
            eventoId: eventoId,
            escalasDoEvento: porEvento[eventoId]!,
            evento: eventosMap[eventoId],
            isLider: isLider,
          ),
          ExpansionTile(
            // Próximas abertas por padrão; passadas fechadas
            initiallyExpanded: !isPassadas,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Builder(builder: (_) {
              final ev = eventosMap[eventoId];
              if (ev == null) return const SizedBox.shrink();
              final dt = _parseDataEvento(ev.dataEvento);
              if (dt == null) return const SizedBox.shrink();

              final temHora = ev.dataEvento.contains('T') && (dt.hour != 0 || dt.minute != 0);
              final dataStr = _formatarData(dt);
              final horaStr = temHora ? '• ${_formatarHora(dt)}' : '';
              return Text('$dataStr $horaStr'.trim());
            }),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: porEvento[eventoId]!.length,
                itemBuilder: (context, index) => _buildEscalaItem(
                  context,
                  porEvento[eventoId]![index],
                  isLider,
                  currentUserId,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    );
  }

  // ── build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLider = auth.userData?['is_lider'] ?? false;
    final currentUserId = auth.userData?['musico_id'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Escalas'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _carregarTudo,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.event_available), text: 'Próximas'),
              Tab(icon: Icon(Icons.history), text: 'Passadas'),
            ],
          ),
        ),
        floatingActionButton: isLider
            ? FloatingActionButton(
                onPressed: () => _mostrarDialogoAdicionar(context),
                tooltip: 'Adicionar ao rascunho',
                child: const Icon(Icons.add),
              )
            : null,
        body: Consumer2<EscalasProvider, EventoProvider>(
          builder: (context, escalasProvider, eventosProvider, child) {
            if (escalasProvider.isLoading) {
              return ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => const ShimmerCard(height: 160),
              );
            }

            // Map eventoId → Evento para lookup O(1)
            final eventosMap = <int, Evento>{
              for (final ev in eventosProvider.eventos)
                if (ev.id != null) ev.id!: ev,
            };

            // Mescla publicadas + rascunhos
            final todas = <Escala>[
              ...escalasProvider.listarRascunhos(),
              ...escalasProvider.escalas,
            ];

            final filtradas = _filtrarPorStatus(todas);

            // Separa por aba usando _eventoEhPassado + data do EventoProvider
            final proximas = <Escala>[];
            final passadas = <Escala>[];

            for (final e in filtradas) {
              final ev = eventosMap[e.eventoId];
              final dt = ev != null ? _parseDataEvento(ev.dataEvento) : null;

              // Rascunhos e eventos sem data ficam sempre em Próximas
              if (dt == null || !_eventoEhPassado(dt)) {
                proximas.add(e);
              } else {
                passadas.add(e);
              }
            }

            if (todas.isEmpty) {
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
                      isLider ? 'Toque no + para montar um rascunho' : 'Aguarde ser escalado pelo líder',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildFiltros(),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Aba "Próximas"
                      RefreshIndicator(
                        onRefresh: _carregarTudo,
                        child: _buildListaAgrupada(
                          context: context,
                          escalas: proximas,
                          eventosMap: eventosMap,
                          isLider: isLider,
                          currentUserId: currentUserId,
                          isPassadas: false,
                        ),
                      ),
                      // Aba "Passadas"
                      RefreshIndicator(
                        onRefresh: _carregarTudo,
                        child: _buildListaAgrupada(
                          context: context,
                          escalas: passadas,
                          eventosMap: eventosMap,
                          isLider: isLider,
                          currentUserId: currentUserId,
                          isPassadas: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
