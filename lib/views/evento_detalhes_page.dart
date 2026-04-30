import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/escala_texto_builder.dart';
import 'package:sggm/views/widgets/evento/evento_escala_tab.dart';
import 'package:sggm/views/widgets/evento/evento_setlist_tab.dart';
import 'package:url_launcher/url_launcher.dart';

class EventoDetalhesPage extends StatefulWidget {
  const EventoDetalhesPage({super.key, required this.evento});

  final Evento evento;

  @override
  State<EventoDetalhesPage> createState() => _EventoDetalhesPageState();
}

class _EventoDetalhesPageState extends State<EventoDetalhesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        Provider.of<EscalasProvider>(context, listen: false).listarEscalas(),
        Provider.of<MusicasProvider>(context, listen: false).listarMusicas(),
        Provider.of<MusicosProvider>(context, listen: false).listarMusicos(),
        Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos(),
        Provider.of<EventoProvider>(context, listen: false).listarEventos(),
      ]);
    } catch (e) {
      AppLogger.error('Erro ao carregar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarParaGrupoWhatsApp() async {
    final eventoAtual = Provider.of<EventoProvider>(context, listen: false)
        .eventos
        .firstWhere((e) => e.id == widget.evento.id, orElse: () => widget.evento);

    final escalas = Provider.of<EscalasProvider>(context, listen: false)
        .escalas
        .where((e) => e.eventoId == widget.evento.id)
        .toList();

    final texto = EscalaTextoBuilder.gerar(evento: eventoAtual, escalas: escalas);
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  Future<void> _notificarMusico(Escala escala) async {
    final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
    try {
      final musico = musicosProvider.musicos.firstWhere((m) => m.id == escala.musicoId);
      String telefone = musico.telefone.replaceAll(RegExp(r'[^0-9]'), '');
      if (telefone.length <= 11) telefone = '55$telefone';

      final dataFormatada = widget.evento.dataEvento.split('T')[0].split('-').reversed.join('/');
      final instrumento = escala.instrumentoNome ?? 'instrumento não especificado';

      final mensagem = 'Olá *${musico.nome}*! 👋\n'
          'Você foi escalado para o *${widget.evento.nome}* dia $dataFormatada '
          'tocando *$instrumento*.\n\nConfirme sua presença!';

      final url = Uri.parse('https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}');

      if (!await launchUrl(url, mode: LaunchMode.externalApplication) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao notificar músico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isLider = Provider.of<AuthProvider>(context, listen: false).userData?['is_lider'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.evento.nome, style: const TextStyle(fontSize: 18)),
            Text(
              widget.evento.dataEvento.split('T')[0].split('-').reversed.join('/'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          if (isLider)
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Enviar Escala no Grupo',
              onPressed: _enviarParaGrupoWhatsApp,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'SETLIST', icon: Icon(Icons.queue_music)),
            Tab(text: 'ESCALA', icon: Icon(Icons.groups)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EventoSetlistTab(evento: widget.evento, isLider: isLider),
          EventoEscalaTab(
            evento: widget.evento,
            isLider: isLider,
            onNotificarMusico: _notificarMusico,
          ),
        ],
      ),
    );
  }
}
