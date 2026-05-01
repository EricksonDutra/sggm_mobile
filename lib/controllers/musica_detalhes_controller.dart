import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/services/musicas_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/cifra_scroll_controller.dart';
import 'package:sggm/util/modo_cifra.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MusicaDetalhesController extends ChangeNotifier {
  // final Musica musica;
  bool isLoading = false;
  Musica _musica;
  Musica get musica => _musica;

  MusicaDetalhesController(Musica musica) : _musica = musica {
    _initFlags();
  }

  // ── Flags de conteúdo ──────────────────────────────────────────────────
  late bool hasYoutube;
  late bool hasCifraNativa;
  late bool hasCifraWeb;
  late bool hasCifra;

  // ── YouTube ────────────────────────────────────────────────────────────
  YoutubePlayerController? youtubeController;

  // ── WebView ────────────────────────────────────────────────────────────
  WebViewController? webViewController;
  bool webViewInitialized = false;
  bool isLoadingWebView = false;

  // ── Transposição ───────────────────────────────────────────────────────
  static const _tons = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  int semitonsDelta = 0;
  String? tomAtualDisplay;

  // ── Scroll ─────────────────────────────────────────────────────────────
  final scrollController = ScrollController();
  CifraScrollConfig scrollConfig = const CifraScrollConfig();
  bool autoScrollAtivo = false;
  bool usuarioInteragindo = false;
  Timer? _retomadaTimer;

  // ── Modo cifra ─────────────────────────────────────────────────────────
  late ModoCifra modoCifra;

  // ── Tab ────────────────────────────────────────────────────────────────
  int tabIndex = 0;

  // ─────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────

  void _initFlags() {
    hasYoutube = musica.linkYoutube?.isNotEmpty ?? false;
    hasCifraNativa = musica.conteudoCifra?.isNotEmpty ?? false;
    hasCifraWeb = musica.linkCifra?.isNotEmpty ?? false;
    hasCifra = hasCifraNativa || hasCifraWeb;

    tomAtualDisplay = musica.tom;
    modoCifra = hasCifraNativa ? ModoCifra.nativa : ModoCifra.web;

    _calcularDeltaInicial();
  }

  Future<void> carregarDetalhes(MusicasService service) async {
    if (_musica.id == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final completa = await service.buscarPorId(_musica.id!);
      if (completa != null) {
        _musica = completa;
        _initFlags(); // recalcula hasCifraNativa, hasCifraWeb etc.
        initYoutube();
        initWebViewSeNecessario();
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao carregar detalhes da música: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _calcularDeltaInicial() {
    final tomCifra = _extrairTomOriginalDaCifra();
    final tomAlvo = musica.tom;

    if (tomCifra == null || tomAlvo == null) {
      // Sem info suficiente: mostra como está
      tomAtualDisplay = musica.tom;
      semitonsDelta = 0;
      return;
    }

    final indexOrigem = _tons.indexOf(tomCifra);
    final indexAlvo = _tons.indexOf(tomAlvo);

    if (indexOrigem == -1 || indexAlvo == -1) {
      tomAtualDisplay = musica.tom;
      semitonsDelta = 0;
      return;
    }

    // Delta pode ser negativo (ex: de E para D = -2)
    semitonsDelta = ((indexAlvo - indexOrigem) % 12 + 12) % 12;
    // Prefere o caminho mais curto (ex: +10 vira -2)
    if (semitonsDelta > 6) semitonsDelta -= 12;

    tomAtualDisplay = tomAlvo;
  }

  String? _extrairTomOriginalDaCifra() {
    final conteudo = musica.conteudoCifra;
    if (conteudo == null || conteudo.isEmpty) return null;

    final keyRegex = RegExp(r'\{key:\s*([A-G][b#]?)\}', caseSensitive: false);
    for (final linha in conteudo.split('\n').take(5)) {
      final match = keyRegex.firstMatch(linha);
      if (match != null) return _normalizarTom(match.group(1)!);
    }

    return null; // sem {key:}, não transpõe automaticamente
  }

  String _normalizarTom(String tom) {
    const enarmonicos = {
      'Db': 'C#',
      'Eb': 'D#',
      'Gb': 'F#',
      'Ab': 'G#',
      'Bb': 'A#',
    };
    return enarmonicos[tom] ?? tom;
  }

  void initYoutube() {
    if (!hasYoutube) return;
    final videoId = YoutubePlayer.convertUrlToId(musica.linkYoutube!);
    if (videoId == null) return;
    youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false, enableCaption: false),
    );
  }

  void initWebViewSeNecessario() {
    if (hasCifraWeb && !hasCifraNativa) initializeWebView();
  }

  void initializeWebView([BuildContext? context]) {
    if (webViewInitialized || !hasCifraWeb) return;

    isLoadingWebView = true;
    notifyListeners();

    try {
      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.grey[100]!)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            webViewController?.runJavaScript('''
              document.body.style.backgroundColor = '#f5f5f5';
              document.body.style.color = '#000000';
            ''');
            isLoadingWebView = false;
            notifyListeners();
          },
          onWebResourceError: (_) {
            isLoadingWebView = false;
            notifyListeners();
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ))
        ..loadRequest(Uri.parse(musica.linkCifra!));

      webViewInitialized = true;
      notifyListeners();
    } catch (_) {
      isLoadingWebView = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Tab
  // ─────────────────────────────────────────────────────────────────────

  void setTabIndex(int index) {
    tabIndex = index;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Transposição
  // ─────────────────────────────────────────────────────────────────────

  void transporTom(int delta) {
    semitonsDelta += delta;
    final tomOriginal = musica.tom;
    if (tomOriginal != null && _tons.contains(tomOriginal)) {
      final novoIndex = ((_tons.indexOf(tomOriginal) + semitonsDelta) % 12 + 12) % 12;
      tomAtualDisplay = _tons[novoIndex];
    }
    notifyListeners();
  }

  void resetarTom() {
    semitonsDelta = 0;
    tomAtualDisplay = musica.tom;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Modo cifra
  // ─────────────────────────────────────────────────────────────────────

  void setModoCifra(ModoCifra modo) {
    modoCifra = modo;
    if (modo == ModoCifra.web) initializeWebView();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Scroll config
  // ─────────────────────────────────────────────────────────────────────

  void aumentarFonte() {
    scrollConfig = scrollConfig.aumentarFonte();
    notifyListeners();
  }

  void diminuirFonte() {
    scrollConfig = scrollConfig.diminuirFonte();
    notifyListeners();
  }

  void setVelocidade(double v) {
    scrollConfig = scrollConfig.comVelocidade(v);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Auto-scroll
  // ─────────────────────────────────────────────────────────────────────

  void toggleAutoScroll() {
    autoScrollAtivo = !autoScrollAtivo;
    notifyListeners();
    if (autoScrollAtivo) _iniciarAutoScroll();
  }

  Future<void> _iniciarAutoScroll() async {
    while (autoScrollAtivo) {
      if (!usuarioInteragindo && scrollController.hasClients) {
        final max = scrollController.position.maxScrollExtent;
        final atual = scrollController.offset;
        if (atual >= max) {
          autoScrollAtivo = false;
          notifyListeners();
          break;
        }
        await scrollController.animateTo(
          atual + 1,
          duration: Duration(milliseconds: 1000 ~/ scrollConfig.velocidade * 10),
          curve: Curves.linear,
        );
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  void iniciarInteracao() {
    if (!autoScrollAtivo) return;
    _retomadaTimer?.cancel();
    usuarioInteragindo = true;
    notifyListeners();
  }

  void encerrarInteracao() {
    if (!autoScrollAtivo) return;
    _retomadaTimer = Timer(const Duration(seconds: 2), () {
      usuarioInteragindo = false;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Link externo
  // ─────────────────────────────────────────────────────────────────────

  Future<void> abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _retomadaTimer?.cancel();
    youtubeController?.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
