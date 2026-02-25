import 'package:flutter/material.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/util/cifra_parser.dart';
import 'package:sggm/util/cifra_scroll_controller.dart';
import 'package:sggm/views/widgets/cifra_floating_controls.dart';
import 'package:sggm/views/widgets/cifra_secao_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum ModoCifra { nativa, web }

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class MusicaDetalhesPage extends StatefulWidget {
  final Musica musica;

  const MusicaDetalhesPage({super.key, required this.musica});

  @override
  State<MusicaDetalhesPage> createState() => _MusicaDetalhesPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _MusicaDetalhesPageState extends State<MusicaDetalhesPage> with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late TabController _tabController;
  YoutubePlayerController? _youtubeController;
  WebViewController? _webViewController;
  final ScrollController _scrollController = ScrollController();

  // ── Flags de conteúdo ──────────────────────────────────────────────────────
  bool _hasYoutube = false;
  bool _hasCifraNativa = false;
  bool _hasCifraWeb = false;
  bool _hasCifra = false;

  // ── Estado da WebView ──────────────────────────────────────────────────────
  bool _webViewInitialized = false;
  bool _isLoadingWebView = false;

  // ── Estado da cifra nativa ─────────────────────────────────────────────────
  int _semitonsDelta = 0;
  String? _tomAtualDisplay;
  CifraScrollConfig _scrollConfig = const CifraScrollConfig();
  bool _autoScrollAtivo = false;

  // ── Modo de exibição da cifra ──────────────────────────────────────────────
  late ModoCifra _modoCifra;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initFlags();
    _initTabController();
    _initYoutube();
    _initWebViewSeNecessario();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Inicialização
  // ─────────────────────────────────────────────────────────────────────────

  void _initFlags() {
    _hasYoutube = widget.musica.linkYoutube != null && widget.musica.linkYoutube!.isNotEmpty;
    _hasCifraNativa = widget.musica.conteudoCifra != null && widget.musica.conteudoCifra!.isNotEmpty;
    _hasCifraWeb = widget.musica.linkCifra != null && widget.musica.linkCifra!.isNotEmpty;
    _hasCifra = _hasCifraNativa || _hasCifraWeb;

    _tomAtualDisplay = widget.musica.tom;
    _modoCifra = _hasCifraNativa ? ModoCifra.nativa : ModoCifra.web;
  }

  void _initTabController() {
    final tabCount = [_hasYoutube, _hasCifra].where((v) => v).length;
    _tabController = TabController(
      length: tabCount > 0 ? tabCount : 1,
      vsync: this,
    );
  }

  void _initYoutube() {
    if (!_hasYoutube) return;
    final videoId = YoutubePlayer.convertUrlToId(widget.musica.linkYoutube!);
    if (videoId == null) return;
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  /// Inicializa a WebView apenas se não há cifra nativa (eager)
  /// ou de forma lazy quando o usuário trocar para o modo web.
  void _initWebViewSeNecessario() {
    if (_hasCifraWeb && !_hasCifraNativa) {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    if (_webViewInitialized || !_hasCifraWeb) return;

    setState(() => _isLoadingWebView = true);

    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.grey[100]!)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              _webViewController?.runJavaScript('''
                document.body.style.backgroundColor = '#f5f5f5';
                document.body.style.color = '#000000';
              ''');
              if (mounted) setState(() => _isLoadingWebView = false);
            },
            onWebResourceError: (_) {
              if (!mounted) return;
              setState(() => _isLoadingWebView = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao carregar a cifra'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            onNavigationRequest: (_) => NavigationDecision.navigate,
          ),
        )
        ..loadRequest(Uri.parse(widget.musica.linkCifra!));

      setState(() => _webViewInitialized = true);
    } catch (_) {
      if (mounted) setState(() => _isLoadingWebView = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lógica de transposição
  // ─────────────────────────────────────────────────────────────────────────

  static const _tons = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  void _transporTom(int delta) {
    setState(() {
      _semitonsDelta += delta;
      final tomOriginal = widget.musica.tom;
      if (tomOriginal != null && _tons.contains(tomOriginal)) {
        final novoIndex = ((_tons.indexOf(tomOriginal) + _semitonsDelta) % 12 + 12) % 12;
        _tomAtualDisplay = _tons[novoIndex];
      }
    });
  }

  void _resetarTom() {
    setState(() {
      _semitonsDelta = 0;
      _tomAtualDisplay = widget.musica.tom;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lógica de auto-scroll
  // ─────────────────────────────────────────────────────────────────────────

  void _toggleAutoScroll() {
    setState(() => _autoScrollAtivo = !_autoScrollAtivo);
    if (_autoScrollAtivo) _iniciarAutoScroll();
  }

  Future<void> _iniciarAutoScroll() async {
    while (_autoScrollAtivo && mounted) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final atual = _scrollController.offset;

        if (atual >= maxExtent) {
          setState(() => _autoScrollAtivo = false);
          break;
        }

        await _scrollController.animateTo(
          atual + 1,
          duration: Duration(
            milliseconds: (1000 ~/ _scrollConfig.velocidade * 10),
          ),
          curve: Curves.linear,
        );
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build principal
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final temConteudo = _hasYoutube || _hasCifra;

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        bottom: temConteudo ? _buildTabBar() : null,
      ),
      body: temConteudo ? _buildTabBarView() : _buildSemConteudo(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.musica.titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          widget.musica.artistaNome,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        if (_hasYoutube) const Tab(icon: Icon(Icons.play_circle), text: 'Vídeo'),
        if (_hasCifra) const Tab(icon: Icon(Icons.music_note), text: 'Cifra'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (_hasYoutube) _buildYoutubeTab(),
        if (_hasCifra) _buildCifraTab(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: YouTube
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildYoutubeTab() {
    if (_youtubeController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Link do YouTube inválido',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.music_note,
                  'Tom',
                  widget.musica.tom ?? 'Não informado',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Artista', widget.musica.artistaNome),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir no YouTube'),
                    onPressed: () => _abrirLink(widget.musica.linkYoutube!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: Cifra (roteador)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCifraTab() {
    // Apenas uma opção disponível — abre direto sem seletor
    if (_hasCifraNativa && !_hasCifraWeb) return _buildCifraNativa();
    if (!_hasCifraNativa && _hasCifraWeb) return _buildCifraWebView();

    // Ambas disponíveis — exibe seletor
    return Column(
      children: [
        _buildSeletorModoCifra(),
        Expanded(
          child: _modoCifra == ModoCifra.nativa ? _buildCifraNativa() : _buildCifraWebView(),
        ),
      ],
    );
  }

  // ── Seletor local / web ────────────────────────────────────────────────────

  Widget _buildSeletorModoCifra() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChipModo(
            label: 'Local',
            icon: Icons.phonelink_outlined,
            modo: ModoCifra.nativa,
          ),
          const SizedBox(width: 8),
          _buildChipModo(
            label: 'Web',
            icon: Icons.language,
            modo: ModoCifra.web,
          ),
        ],
      ),
    );
  }

  Widget _buildChipModo({
    required String label,
    required IconData icon,
    required ModoCifra modo,
  }) {
    final selecionado = _modoCifra == modo;

    return GestureDetector(
      onTap: () {
        if (_modoCifra == modo) return;
        setState(() => _modoCifra = modo);
        if (modo == ModoCifra.web) _initializeWebView();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.presbyterianoVerde : AppTheme.backgroundTerciario,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? AppTheme.presbyterianoVerde : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selecionado ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w400,
                color: selecionado ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cifra nativa (ChordPro)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCifraNativa() {
    final conteudo = CifraParser.transporCifra(
      widget.musica.conteudoCifra!,
      _semitonsDelta,
    );
    final secoes = CifraParser.parsearSecoes(conteudo);

    return Stack(
      children: [
        Column(
          children: [
            _buildBarraTom(),
            Expanded(child: _buildConteudoCifra(secoes)),
          ],
        ),
        _buildControlesFixos(),
      ],
    );
  }

  Widget _buildBarraTom() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.music_note,
            size: 16,
            color: AppTheme.presbyterianoVerdeClaro,
          ),
          const SizedBox(width: 4),
          Text(
            'Tom: ${_tomAtualDisplay ?? widget.musica.tom ?? "?"}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (_semitonsDelta != 0) ...[
            const SizedBox(width: 6),
            _buildBadgeSemitons(),
          ],
          const Spacer(),
          _buildBotaoTom(Icons.remove_circle_outline, () => _transporTom(-1)),
          _buildBotaoTom(Icons.add_circle_outline, () => _transporTom(1)),
          if (_semitonsDelta != 0) _buildBotaoTom(Icons.refresh, _resetarTom, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildBadgeSemitons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.presbyterianoVerde.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${_semitonsDelta > 0 ? "+" : ""}$_semitonsDelta',
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.presbyterianoVerdeClaro,
        ),
      ),
    );
  }

  Widget _buildBotaoTom(
    IconData icon,
    VoidCallback onPressed, {
    Color color = AppTheme.presbyterianoVerdeClaro,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: color,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildConteudoCifra(List<dynamic> secoes) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 72, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...secoes.map(
            (s) => CifraSecaoWidget(secao: s, fontSize: _scrollConfig.fontSize),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildControlesFixos() {
    return CifraFloatingControls(
      config: _scrollConfig,
      autoScrollAtivo: _autoScrollAtivo,
      onToggleScroll: _toggleAutoScroll,
      onFonteMais: () => setState(() => _scrollConfig = _scrollConfig.aumentarFonte()),
      onFonteMenos: () => setState(() => _scrollConfig = _scrollConfig.diminuirFonte()),
      onVelocidadeMais: () => setState(() => _scrollConfig = _scrollConfig.aumentarVelocidade()),
      onVelocidadeMenos: () => setState(() => _scrollConfig = _scrollConfig.diminuirVelocidade()),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cifra Web (WebView)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCifraWebView() {
    if (_webViewController == null) {
      return const Center(
        child: Text(
          'Não foi possível carregar a cifra',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        _buildBarraCifraWeb(),
        Expanded(child: _buildWebViewContent()),
      ],
    );
  }

  Widget _buildBarraCifraWeb() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tom: ${widget.musica.tom ?? "Não informado"}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (_isLoadingWebView)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.black87),
            tooltip: 'Abrir no navegador',
            onPressed: () => _abrirLink(widget.musica.linkCifra!),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewContent() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        if (_isLoadingWebView) const LinearProgressIndicator(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sem conteúdo
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSemConteudo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum conteúdo disponível',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta música não possui cifra ou vídeo cadastrado',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.music_note,
              'Tom',
              widget.musica.tom ?? 'Não informado',
            ),
            const Divider(),
            _buildInfoRow(Icons.person, 'Artista', widget.musica.artistaNome),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
