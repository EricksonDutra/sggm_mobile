import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/views/widgets/dialogs/adicionar_escala_dialog.dart';
import 'package:sggm/views/widgets/escalas/escala_card.dart';
import 'package:sggm/views/widgets/escalas/escala_filtros_sheet.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';

class EscalasPage extends StatefulWidget {
  const EscalasPage({super.key});

  @override
  State<EscalasPage> createState() => _EscalasPageState();
}

class _EscalasPageState extends State<EscalasPage> {
  String _filtro = 'todas';
  final _filtroAvancado = EscalaFiltro();
  Map<int, Evento> _eventosMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarTudo());
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
          SnackBar(
            content: Text('Erro ao carregar escalas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      if (_filtroAvancado.instrumentoNome != null) {
        final nomeEscala = (e.instrumentoNome ?? '').toLowerCase();
        final filtro = _filtroAvancado.instrumentoNome!.toLowerCase();
        if (!nomeEscala.contains(filtro)) return false;
      }
      return true;
    }).toList();
  }

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
                itemBuilder: (context, index) => EscalaCard(
                  escala: porEvento[eventoId]![index],
                  isLider: isLider,
                  currentUserId: currentUserId,
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
              onPressed: () => EscalaFiltrosSheet.show(
                context: context,
                filtro: _filtroAvancado,
                eventosMap: _eventosMap,
                onAplicar: () => setState(() {}),
              ),
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
                onPressed: () => AdicionarEscalaDialog.show(context),
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
                            _filtroAvancado.descricao,
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
}
