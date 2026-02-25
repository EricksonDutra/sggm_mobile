import 'package:flutter/material.dart';
import 'package:sggm/models/musicas.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sggm/util/cifra_parser.dart';
import 'package:sggm/views/widgets/cifra_secao_widget.dart';
import 'package:sggm/theme/app_theme.dart';

class MusicaDetalhesPage extends StatefulWidget {
  final Musica musica;

  const MusicaDetalhesPage({super.key, required this.musica});

  @override
  State<MusicaDetalhesPage> createState() => _MusicaDetalhesPageState();
}

class _MusicaDetalhesPageState extends State<MusicaDetalhesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  YoutubePlayerController? _youtubeController;
  WebViewController? _webViewController;
  final bool _hasYoutube = false;
  bool _hasCifra = false;
  bool _webViewInitialized = false;
  bool _isLoadingWebView = false;
  String? _tomAtual;
  int _semitonsDelta = 0;
  String? _tomAtualDisplay;
  bool _hasCifraNativa = false;

  @override
  void initState() {
    super.initState();
    _tomAtual = widget.musica.tom;
    _tomAtualDisplay = widget.musica.tom;
    _hasCifraNativa = widget.musica.conteudoCifra != null && widget.musica.conteudoCifra!.isNotEmpty;
    _hasCifra = _hasCifraNativa || (widget.musica.linkCifra != null && widget.musica.linkCifra!.isNotEmpty);

    int tabCount = 0;
    if (_hasYoutube) tabCount++;
    if (_hasCifra) tabCount++;
    _tabController = TabController(length: tabCount > 0 ? tabCount : 1, vsync: this);

    if (_hasYoutube) {
      final videoId = YoutubePlayer.convertUrlToId(widget.musica.linkYoutube!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
          ),
        );
      }
    }

    if (_hasCifra && widget.musica.linkCifra != null) {
      _initializeWebView();
    }
  }

  void _transporTom(int delta) {
    final tons = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    setState(() {
      _semitonsDelta += delta;
      if (widget.musica.tom != null && tons.contains(widget.musica.tom)) {
        final index = tons.indexOf(widget.musica.tom!);
        final novoIndex = ((index + _semitonsDelta) % 12 + 12) % 12;
        _tomAtualDisplay = tons[novoIndex];
      }
    });
  }

  Widget _buildCifraTab() {
    if (_hasCifraNativa) return _buildCifraNativa();
    if (_webViewController != null) return _buildCifraWebView();
    return const Center(child: Text('Cifra não disponível'));
  }

  Widget _buildCifraWebView() {
    if (_webViewController == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text(
            'Não foi possível carregar a cifra',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _mostrarSeletorTom,
                    child: Row(
                      children: [
                        Text(
                          'Tom: ${widget.musica.tom ?? "Não informado"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingWebView)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
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
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                if (_isLoadingWebView)
                  Container(
                    color: Colors.grey[100],
                    child: const LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSeletorTom() {
    final tons = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Tom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tom original:'),
            Text(
              widget.musica.tom ?? 'Não informado',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tons
                  .map((tom) => ChoiceChip(
                        label: Text(tom),
                        selected: _tomAtual == tom,
                        onSelected: (selected) {
                          setState(() {
                            _tomAtual = selected ? tom : widget.musica.tom;
                          });
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeWebView() {
    if (_webViewInitialized || !_hasCifra || widget.musica.linkCifra == null) return;

    setState(() => _isLoadingWebView = true);

    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.grey[100]!)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _webViewController?.runJavaScript('''
                document.body.style.backgroundColor = '#f5f5f5';
                document.body.style.color = '#000000';
              ''');
              if (mounted) setState(() => _isLoadingWebView = false);
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() => _isLoadingWebView = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao carregar a cifra'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            onNavigationRequest: (_) => NavigationDecision.navigate,
          ),
        )
        ..loadRequest(Uri.parse(widget.musica.linkCifra!));

      setState(() => _webViewInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _isLoadingWebView = false);
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
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
        ),
        bottom: _hasYoutube || _hasCifra
            ? TabBar(
                controller: _tabController,
                tabs: [
                  if (_hasYoutube) const Tab(icon: Icon(Icons.play_circle), text: 'Vídeo'),
                  if (_hasCifra) const Tab(icon: Icon(Icons.music_note), text: 'Cifra'),
                ],
              )
            : null,
      ),
      body: _hasYoutube || _hasCifra
          ? TabBarView(
              controller: _tabController,
              children: [
                if (_hasYoutube) _buildYoutubeTab(),
                if (_hasCifra) _buildCifraTab(),
              ],
            )
          : _buildSemConteudo(),
    );
  }

  Widget _buildYoutubeTab() {
    if (_youtubeController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Link do YouTube inválido', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.music_note, 'Tom', widget.musica.tom ?? 'Não informado'),
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

  Widget _buildCifraNativa() {
    final conteudo = CifraParser.transporCifra(widget.musica.conteudoCifra!, _semitonsDelta);
    final secoes = CifraParser.parsearSecoes(conteudo);

    return Column(
      children: [
        // Barra de controles
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.music_note, size: 18, color: AppTheme.presbyterianoVerdeClaro),
              const SizedBox(width: 6),
              Text(
                'Tom: ${_tomAtualDisplay ?? widget.musica.tom ?? "?"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(width: 8),
              if (_semitonsDelta != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.presbyterianoVerde.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_semitonsDelta > 0 ? "+" : ""}$_semitonsDelta',
                    style: const TextStyle(fontSize: 11, color: AppTheme.presbyterianoVerdeClaro),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _transporTom(-1),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.presbyterianoVerdeClaro,
                tooltip: 'Diminuir tom',
              ),
              IconButton(
                onPressed: () => _transporTom(1),
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.presbyterianoVerdeClaro,
                tooltip: 'Aumentar tom',
              ),
              if (_semitonsDelta != 0)
                IconButton(
                  onPressed: () => setState(() {
                    _semitonsDelta = 0;
                    _tomAtualDisplay = widget.musica.tom;
                  }),
                  icon: const Icon(Icons.refresh),
                  color: Colors.white54,
                  tooltip: 'Resetar tom',
                ),
            ],
          ),
        ),
        // Conteúdo da cifra
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: secoes.map((s) => CifraSecaoWidget(secao: s)).toList(),
            ),
          ),
        ),
      ],
    );
  }

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.music_note, 'Tom', widget.musica.tom ?? 'Não informado'),
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

  Future<void> _abrirLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
