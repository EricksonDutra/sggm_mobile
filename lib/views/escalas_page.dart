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
// ✅ REMOVIDO: import de Instrumento — não é mais necessário após migração M2M
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';

// ── Modelo de filtro avançado ─────────────────────────────────────────────────

class _EscalaFiltro {
  int? ano;
  int? mes;
  String? musicoNome;
  String? instrumentoNome;

  bool get ativo => ano != null || mes != null || musicoNome != null || instrumentoNome != null;

  void limpar() {
    ano = null;
    mes = null;
    musicoNome = null;
    instrumentoNome = null;
  }
}

// ── Widget principal ──────────────────────────────────────────────────────────

class EscalasPage extends StatefulWidget {
  const EscalasPage({super.key});

  @override
  State<EscalasPage> createState() => _EscalasPageState();
}

class _EscalasPageState extends State<EscalasPage> {
  String _filtro = 'todas';
  final _filtroAvancado = _EscalaFiltro();
  Map<int, Evento> _eventosMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarTudo());
  }

  // ── carregamento ──────────────────────────────────────────────────────────

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
          SnackBar(
            content: Text('Erro ao carregar escalas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── helpers de data ───────────────────────────────────────────────────────

  DateTime? _parseDataEvento(String raw) {
    if (raw.trim().isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final partes = raw.split('T').first.split('-');
    if (partes.length == 3) {
      final y = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final d = int.tryParse(partes[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    return null;
  }

  String _formatarData(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  String _formatarHora(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  bool _eventoEhPassado(DateTime dataEvento) {
    final temHorario = dataEvento.hour != 0 || dataEvento.minute != 0;
    final corte = temHorario
        ? dataEvento.add(const Duration(hours: 3))
        : DateTime(dataEvento.year, dataEvento.month, dataEvento.day + 1, 3, 0);
    return DateTime.now().isAfter(corte);
  }

  // ── filtros ───────────────────────────────────────────────────────────────

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

  List<Escala> _aplicarFiltroAvancado(List<Escala> escalas, Map<int, Evento> eventosMap) {
    if (!_filtroAvancado.ativo) return escalas;

    return escalas.where((e) {
      final ev = eventosMap[e.eventoId];
      final dt = ev != null ? _parseDataEvento(ev.dataEvento) : null;

      if (_filtroAvancado.ano != null && dt?.year != _filtroAvancado.ano) {
        return false;
      }
      if (_filtroAvancado.mes != null && dt?.month != _filtroAvancado.mes) {
        return false;
      }
      if (_filtroAvancado.musicoNome != null &&
          !(e.musicoNome ?? '').toLowerCase().contains(_filtroAvancado.musicoNome!.toLowerCase())) {
        return false;
      }
      // ✅ CORRIGIDO: instrumentoNome agora é multi-valor "Violão • Vocalista"
      // Usa contains() em vez de == para filtrar corretamente
      if (_filtroAvancado.instrumentoNome != null) {
        final nomeEscala = (e.instrumentoNome ?? '').toLowerCase();
        final filtro = _filtroAvancado.instrumentoNome!.toLowerCase();
        if (!nomeEscala.contains(filtro)) return false;
      }
      return true;
    }).toList();
  }

  // ── bottom sheet de filtros ───────────────────────────────────────────────

  void _abrirFiltros(BuildContext context) {
    final anos = _eventosMap.values.map((e) => _parseDataEvento(e.dataEvento)?.year).whereType<int>().toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    const mesesNomes = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          setSheet(() => _filtroAvancado.limpar());
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Limpar tudo'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // ── Ano ──────────────────────────────────────────────────
                  const Text('Ano', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  anos.isEmpty
                      ? const Text('Nenhum ano disponível', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: anos
                              .map((ano) => ChoiceChip(
                                    label: Text('$ano'),
                                    selected: _filtroAvancado.ano == ano,
                                    onSelected: (v) => setSheet(() => _filtroAvancado.ano = v ? ano : null),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),

                  // ── Mês ──────────────────────────────────────────────────
                  const Text('Mês', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: List.generate(12, (i) {
                      final mes = i + 1;
                      return ChoiceChip(
                        label: Text(mesesNomes[i]),
                        selected: _filtroAvancado.mes == mes,
                        onSelected: (v) => setSheet(() => _filtroAvancado.mes = v ? mes : null),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ── Músico ───────────────────────────────────────────────
                  const Text('Músico', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Consumer<MusicosProvider>(
                    builder: (context, provider, _) {
                      final nomes = provider.musicos.map((m) => m.nome).toList();
                      return Autocomplete<String>(
                        initialValue: TextEditingValue(text: _filtroAvancado.musicoNome ?? ''),
                        optionsBuilder: (TextEditingValue v) {
                          if (v.text.isEmpty) return nomes;
                          return nomes.where((nome) => nome.toLowerCase().contains(v.text.toLowerCase()));
                        },
                        onSelected: (valor) => setSheet(() => _filtroAvancado.musicoNome = valor),
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Digite o nome do músico',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: _filtroAvancado.musicoNome != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        setSheet(() => _filtroAvancado.musicoNome = null);
                                      },
                                    )
                                  : const Icon(Icons.search, size: 18),
                            ),
                            onChanged: (v) {
                              if (v.isEmpty) {
                                setSheet(() => _filtroAvancado.musicoNome = null);
                              }
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final nome = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.person_outline, size: 20),
                                      title: Text(nome),
                                      onTap: () => onSelected(nome),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Instrumento ──────────────────────────────────────────
                  const Text('Instrumento', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  // ✅ Hint de que o filtro faz busca parcial (M2M)
                  Text(
                    'Selecione para filtrar escalas que contenham este instrumento',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 10),
                  Consumer<InstrumentosProvider>(
                    builder: (context, provider, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _filtroAvancado.instrumentoNome == null,
                            onSelected: (_) => setSheet(() => _filtroAvancado.instrumentoNome = null),
                          ),
                          ...provider.instrumentos.map(
                            (inst) => ChoiceChip(
                              label: Text(inst.nome),
                              selected: _filtroAvancado.instrumentoNome == inst.nome,
                              onSelected: (v) => setSheet(() => _filtroAvancado.instrumentoNome = v ? inst.nome : null),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar filtros'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── chips de status ───────────────────────────────────────────────────────

  Widget _buildFiltrosStatus() {
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

  // ── ações ─────────────────────────────────────────────────────────────────

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
          const SnackBar(
            content: Text('Erro ao confirmar presença'),
            backgroundColor: Colors.red,
          ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            ok ? '✅ Escala publicada! Músicos notificados.' : (provider.errorMessage ?? 'Erro ao publicar escala')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ── diálogo adicionar rascunho ────────────────────────────────────────────

  void _mostrarDialogoAdicionar(BuildContext context) {
    final obsController = TextEditingController();

    int? selectedMusicoId;
    String? selectedMusicoNome;
    int? selectedEventoId;
    String? selectedEventoNome;

    // ✅ CORRIGIDO: M2M — lista de IDs em vez de ID único + nome livre
    final List<int> selectedInstrumentosIds = [];

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

                    // ── Músico ────────────────────────────────────────────
                    Consumer<MusicosProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Músico *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true,
                          value: selectedMusicoId,
                          items: provider.musicos
                              .map((musico) => DropdownMenuItem<int>(
                                    value: musico.id,
                                    child: Text(musico.nome, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedMusicoId = valor;
                              if (valor != null) {
                                final musico = provider.musicos.firstWhere((m) => m.id == valor);
                                selectedMusicoNome = musico.nome;

                                // ✅ Pré-seleciona instrumento principal do músico
                                // se ele tiver e existir na lista de instrumentos
                                final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
                                final principal = musico.instrumentoPrincipal?.toString();
                                if (principal != null && principal.isNotEmpty) {
                                  final match = instProvider.instrumentos.where((i) => i.nome == principal).firstOrNull;
                                  if (match?.id != null && !selectedInstrumentosIds.contains(match!.id)) {
                                    selectedInstrumentosIds.add(match.id);
                                  }
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Evento (somente futuros, pré-selecionado o mais próximo) ──
                    Consumer<EventoProvider>(
                      builder: (context, provider, child) {
                        // ✅ Filtra apenas eventos futuros e ordena do mais próximo
                        final eventosFuturos = provider.eventos.where((e) {
                          final dt = _parseDataEvento(e.dataEvento);
                          return dt != null && !_eventoEhPassado(dt);
                        }).toList()
                          ..sort((a, b) {
                            final da = _parseDataEvento(a.dataEvento);
                            final db = _parseDataEvento(b.dataEvento);
                            if (da == null) return 1;
                            if (db == null) return -1;
                            return da.compareTo(db);
                          });

                        // Pré-seleciona o evento mais próximo ao abrir o diálogo
                        if (selectedEventoId == null && eventosFuturos.isNotEmpty) {
                          // usa addPostFrameCallback para não chamar setState durante build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setStateDialog(() {
                              selectedEventoId = eventosFuturos.first.id;
                              selectedEventoNome = eventosFuturos.first.nome;
                            });
                          });
                        }

                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Evento *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true,
                          value: selectedEventoId,
                          items: eventosFuturos
                              .map((evento) => DropdownMenuItem<int>(
                                    value: evento.id,
                                    child: Text(
                                      '${evento.nome} (${evento.dataEvento.split('T')[0].split('-').reversed.join('/')})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
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

                    // ── Instrumentos (M2M via FilterChip) ─────────────────
                    const Text(
                      'Instrumentos *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Consumer<InstrumentosProvider>(
                      builder: (context, provider, _) {
                        if (provider.instrumentos.isEmpty) {
                          return const Text(
                            'Nenhum instrumento cadastrado',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: provider.instrumentos.map((inst) {
                            final selecionado = selectedInstrumentosIds.contains(inst.id);
                            return FilterChip(
                              label: Text(inst.nome),
                              selected: selecionado,
                              // ✅ FilterChip com setStateDialog para rebuild local
                              onSelected: (v) => setStateDialog(() {
                                if (v) {
                                  selectedInstrumentosIds.add(inst.id);
                                } else {
                                  selectedInstrumentosIds.remove(inst.id);
                                }
                              }),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Observação ────────────────────────────────────────
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

                    // ── Ações ─────────────────────────────────────────────
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
                            // Validações
                            if (selectedMusicoId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selecione um músico!')),
                              );
                              return;
                            }
                            if (selectedEventoId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selecione um evento!')),
                              );
                              return;
                            }
                            // ✅ CORRIGIDO: valida lista de IDs, não string única
                            if (selectedInstrumentosIds.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selecione ao menos um instrumento!')),
                              );
                              return;
                            }

                            // ✅ CORRIGIDO: Escala com instrumentos (List<int>)
                            // Removido: instrumentoNoEvento (FK antiga)
                            // Removido: instrumentoNome manual — backend computa
                            final novaEscala = Escala(
                              musicoId: selectedMusicoId!,
                              eventoId: selectedEventoId!,
                              musicoNome: selectedMusicoNome,
                              eventoNome: selectedEventoNome,
                              instrumentos: List<int>.from(selectedInstrumentosIds),
                              observacao: obsController.text.trim().isNotEmpty ? obsController.text.trim() : null,
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

  // ── card de escala ────────────────────────────────────────────────────────

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
                // ✅ Exibe instrumentoNome diretamente — já formatado pelo backend
                // Para rascunhos locais, mostra os IDs selecionados como fallback
                if (escala.instrumentoNome != null && escala.instrumentoNome!.isNotEmpty)
                  Text('🎵 ${escala.instrumentoNome}')
                else if (escala.instrumentos != null && escala.instrumentos!.isNotEmpty)
                  // Fallback para rascunho local: backend ainda não processou
                  Text('🎵 ${escala.instrumentos!.length} instrumento(s) selecionado(s)'),
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
      message: 'Deseja remover ${escala.musicoNome ?? "este músico"} da escala?\n'
          'Esta ação não pode ser desfeita.',
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

  // ── cabeçalho de evento ───────────────────────────────────────────────────

  Widget _buildEventoHeader({
    required BuildContext context,
    required int eventoId,
    required List<Escala> escalasDoEvento,
    required Evento? evento,
    required bool isLider,
  }) {
    final provider = context.read<EscalasProvider>();
    final rascunhos = provider.getRascunhos(eventoId);
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

  // ── lista agrupada por evento ─────────────────────────────────────────────

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPassadas ? Icons.history : Icons.event_available,
              size: 52,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 12),
            Text(
              isPassadas ? 'Nenhuma escala passada' : 'Nenhuma escala próxima',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_filtroAvancado.ativo) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() => _filtroAvancado.limpar());
                },
                icon: const Icon(Icons.filter_list_off),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    final Map<int, List<Escala>> porEvento = {};
    for (final e in escalas) {
      porEvento.putIfAbsent(e.eventoId, () => []);
      porEvento[e.eventoId]!.add(e);
    }

    final eventoIds = porEvento.keys.toList()
      ..sort((a, b) {
        final da = eventosMap[a] != null ? _parseDataEvento(eventosMap[a]!.dataEvento) : null;
        final db = eventosMap[b] != null ? _parseDataEvento(eventosMap[b]!.dataEvento) : null;
        if (da == null && db == null) return a.compareTo(b);
        if (da == null) return 1;
        if (db == null) return -1;
        final cmp = da.compareTo(db);
        return isPassadas ? -cmp : cmp;
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
            initiallyExpanded: !isPassadas,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Builder(builder: (_) {
              final ev = eventosMap[eventoId];
              if (ev == null) return const SizedBox.shrink();
              final dt = _parseDataEvento(ev.dataEvento);
              if (dt == null) return const SizedBox.shrink();
              final temHora = ev.dataEvento.contains('T') && (dt.hour != 0 || dt.minute != 0);
              final horaStr = temHora ? ' • ${_formatarHora(dt)}' : '';
              return Text(
                '${_formatarData(dt)}$horaStr',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
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

  // ── build principal ───────────────────────────────────────────────────────

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
              tooltip: 'Filtrar',
              icon: Badge(
                isLabelVisible: _filtroAvancado.ativo,
                child: const Icon(Icons.filter_list),
              ),
              onPressed: () => _abrirFiltros(context),
            ),
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

            _eventosMap = {
              for (final ev in eventosProvider.eventos)
                if (ev.id != null) ev.id!: ev,
            };

            final todas = <Escala>[
              ...escalasProvider.listarRascunhos(),
              ...escalasProvider.escalas,
            ];

            final filtradas = _aplicarFiltroAvancado(
              _filtrarPorStatus(todas),
              _eventosMap,
            );

            final proximas = <Escala>[];
            final passadas = <Escala>[];

            for (final e in filtradas) {
              final ev = _eventosMap[e.eventoId];
              final dt = ev != null ? _parseDataEvento(ev.dataEvento) : null;
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
                if (_filtroAvancado.ativo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _descricaoFiltroAtivo(),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _filtroAvancado.limpar()),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                _buildFiltrosStatus(),
                Expanded(
                  child: TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _carregarTudo,
                        child: _buildListaAgrupada(
                          context: context,
                          escalas: proximas,
                          eventosMap: _eventosMap,
                          isLider: isLider,
                          currentUserId: currentUserId,
                          isPassadas: false,
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _carregarTudo,
                        child: _buildListaAgrupada(
                          context: context,
                          escalas: passadas,
                          eventosMap: _eventosMap,
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

  String _descricaoFiltroAtivo() {
    final partes = <String>[];
    if (_filtroAvancado.ano != null) partes.add('${_filtroAvancado.ano}');
    if (_filtroAvancado.mes != null) {
      const nomes = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      partes.add(nomes[_filtroAvancado.mes! - 1]);
    }
    if (_filtroAvancado.musicoNome != null) {
      partes.add(_filtroAvancado.musicoNome!);
    }
    if (_filtroAvancado.instrumentoNome != null) {
      partes.add(_filtroAvancado.instrumentoNome!);
    }
    return 'Filtro: ${partes.join(' • ')}';
  }
}
