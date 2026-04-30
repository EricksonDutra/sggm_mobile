import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/util/date_formatter.dart';
import 'package:sggm/views/evento_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/evento_form_dialog.dart';
import 'package:sggm/views/widgets/loading/shimmer_card.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarEventos());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Próximos'),
            Tab(text: 'Anteriores'),
          ],
        ),
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
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => const ShimmerCard(),
            );
          }

          final agora = DateTime.now();
          final proximos = provider.eventos
              .where((e) => DateTime.tryParse(e.dataEvento)?.isAfter(agora) ?? false)
              .toList()
            ..sort((a, b) => a.dataEvento.compareTo(b.dataEvento));
          final anteriores = provider.eventos
              .where((e) => !(DateTime.tryParse(e.dataEvento)?.isAfter(agora) ?? false))
              .toList()
            ..sort((a, b) => b.dataEvento.compareTo(a.dataEvento));

          return TabBarView(
            controller: _tabController,
            children: [
              _EventosList(
                eventos: proximos,
                isLider: isLider,
                onRefresh: _carregarEventos,
                emptyMessage: 'Nenhum evento próximo.',
                destacarPrimeiro: true,
              ),
              _EventosList(
                eventos: anteriores,
                isLider: isLider,
                onRefresh: _carregarEventos,
                emptyMessage: 'Nenhum evento anterior.',
                destacarPrimeiro: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Lista com agrupamento por mês ───────────────────────────────────────────

class _EventosList extends StatelessWidget {
  const _EventosList({
    required this.eventos,
    required this.isLider,
    required this.onRefresh,
    required this.emptyMessage,
    required this.destacarPrimeiro,
  });

  final List<Evento> eventos;
  final bool isLider;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final bool destacarPrimeiro;

  /// Agrupa eventos por "Mês Ano" ex: "Abril 2026"
  List<_ListItem> _buildItems() {
    final items = <_ListItem>[];
    String? mesAtual;

    for (var i = 0; i < eventos.length; i++) {
      final evento = eventos[i];
      final data = DateTime.tryParse(evento.dataEvento);
      final mesLabel = data != null ? '${_nomeMes(data.month)} ${data.year}' : 'Data inválida';

      if (mesLabel != mesAtual) {
        items.add(_ListItem.header(mesLabel));
        mesAtual = mesLabel;
      }
      items.add(_ListItem.evento(evento, destaque: destacarPrimeiro && i == 0));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }

    final items = _buildItems();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isHeader) {
            return _MesHeader(label: item.header!);
          }
          return _EventoCardNovo(
            evento: item.evento!,
            isLider: isLider,
            destaque: item.destaque,
          );
        },
      ),
    );
  }

  static String _nomeMes(int mes) => const [
        '',
        'Janeiro',
        'Fevereiro',
        'Março',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro'
      ][mes];
}

// ─── Modelo auxiliar para itens da lista ─────────────────────────────────────

class _ListItem {
  final String? header;
  final Evento? evento;
  final bool destaque;

  bool get isHeader => header != null;

  _ListItem.header(this.header)
      : evento = null,
        destaque = false;

  _ListItem.evento(this.evento, {this.destaque = false}) : header = null;
}

// ─── Cabeçalho de mês ────────────────────────────────────────────────────────

class _MesHeader extends StatelessWidget {
  const _MesHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card do evento redesenhado ──────────────────────────────────────────────

class _EventoCardNovo extends StatelessWidget {
  const _EventoCardNovo({
    required this.evento,
    required this.isLider,
    required this.destaque,
  });

  final Evento evento;
  final bool isLider;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final data = DateTime.tryParse(evento.dataEvento);
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventoDetalhesPage(evento: evento),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              destaque ? Border.all(color: primaryColor, width: 1.5) : Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: destaque ? primaryColor.withOpacity(0.12) : Colors.black.withOpacity(0.05),
              blurRadius: destaque ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Bloco de data
              Container(
                width: 46,
                decoration: BoxDecoration(
                  color: destaque ? primaryColor : primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data != null ? '${data.day}' : '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: destaque ? Colors.white : primaryColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      data != null ? _abrevMes(data.month) : '--',
                      style: TextStyle(
                        fontSize: 11,
                        color: destaque ? Colors.white70 : primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (destaque) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRÓXIMO',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            evento.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            evento.local,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (evento.dataHoraEnsaio != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.event_available, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            'Ensaio: ${DateFormatter.dataHoraFromDateTime(evento.dataHoraEnsaio!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Ações
              if (isLider)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onSelected: (value) {
                    if (value == 'editar') {
                      EventoFormDialog.showEditar(context, evento);
                    } else if (value == 'detalhes') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventoDetalhesPage(evento: evento),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'detalhes',
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Ver detalhes'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Editar', style: TextStyle(color: Colors.teal)),
                      ]),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  static String _abrevMes(int mes) =>
      const ['', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'][mes];
}
