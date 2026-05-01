import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/musica_detalhes_controller.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/services/musicas_service.dart';
import 'package:sggm/util/modo_cifra.dart';
import 'package:sggm/views/widgets/cifra_nativa_tab.dart';
import 'package:sggm/views/widgets/cifra_web_tab.dart';
import 'package:sggm/views/widgets/youtube_tab.dart';

class MusicaDetalhesPage extends StatelessWidget {
  final Musica musica;

  const MusicaDetalhesPage({super.key, required this.musica});

  @override
  Widget build(BuildContext context) {
    final musicasService = context.read<MusicasService>();

    return ChangeNotifierProvider(
      create: (_) => MusicaDetalhesController(musica)..carregarDetalhes(musicasService),
      child: const _MusicaDetalhesView(),
    );
  }
}

class _MusicaDetalhesView extends StatefulWidget {
  const _MusicaDetalhesView();

  @override
  State<_MusicaDetalhesView> createState() => _MusicaDetalhesViewState();
}

class _MusicaDetalhesViewState extends State<_MusicaDetalhesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final c = context.read<MusicaDetalhesController>();
    final tabCount = [c.hasCifra, c.hasYoutube].where((v) => v).length;

    _tabController = TabController(
      length: tabCount > 0 ? tabCount : 1,
      vsync: this,
    )..addListener(() {
        if (!_tabController.indexIsChanging) return;
        context.read<MusicaDetalhesController>().setTabIndex(_tabController.index);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MusicaDetalhesController>();
    final temConteudo = c.hasYoutube || c.hasCifra;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(c),
        bottom: temConteudo ? _buildTabBar(c) : null,
      ),
      body: temConteudo ? _buildBody(c) : _buildSemConteudo(c),
    );
  }

  Widget _buildTitle(MusicaDetalhesController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(c.musica.titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        Text(c.musica.artistaNome,
            style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  PreferredSizeWidget _buildTabBar(MusicaDetalhesController c) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(44),
      child: TabBar(
        controller: _tabController,
        indicatorWeight: 2,
        tabs: [
          if (c.hasCifra)
            const Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.music_note, size: 16),
              SizedBox(width: 6),
              Text('Cifra', style: TextStyle(fontSize: 13)),
            ])),
          if (c.hasYoutube)
            const Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_circle, size: 16),
              SizedBox(width: 6),
              Text('Vídeo', style: TextStyle(fontSize: 13)),
            ])),
        ],
      ),
    );
  }

  Widget _buildBody(MusicaDetalhesController c) {
    if (c.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final abas = <Widget>[
      if (c.hasCifra) _buildCifraTab(c),
      if (c.hasYoutube) YoutubeTab(controller: c),
    ];
    return IndexedStack(index: c.tabIndex, children: abas);
  }

  Widget _buildCifraTab(MusicaDetalhesController c) {
    if (c.hasCifraNativa && !c.hasCifraWeb) return CifraNativaTab(controller: c);
    if (!c.hasCifraNativa && c.hasCifraWeb) return CifraWebTab(controller: c);
    return c.modoCifra == ModoCifra.nativa ? CifraNativaTab(controller: c) : CifraWebTab(controller: c);
  }

  Widget _buildSemConteudo(MusicaDetalhesController c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Nenhum conteúdo disponível', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Esta música não possui cifra ou vídeo cadastrado',
              style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoRow(Icons.music_note, 'Tom', c.musica.tom ?? 'Não informado'),
                const Divider(),
                _InfoRow(Icons.person, 'Artista', c.musica.artistaNome),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.grey))),
      ],
    );
  }
}
