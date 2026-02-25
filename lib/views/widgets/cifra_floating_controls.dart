import 'package:flutter/material.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/util/cifra_scroll_controller.dart';

class CifraFloatingControls extends StatefulWidget {
  final CifraScrollConfig config;
  final bool autoScrollAtivo;
  final VoidCallback onToggleScroll;
  final VoidCallback onFonteMais;
  final VoidCallback onFonteMenos;
  final VoidCallback onVelocidadeMais;
  final VoidCallback onVelocidadeMenos;

  const CifraFloatingControls({
    super.key,
    required this.config,
    required this.autoScrollAtivo,
    required this.onToggleScroll,
    required this.onFonteMais,
    required this.onFonteMenos,
    required this.onVelocidadeMais,
    required this.onVelocidadeMenos,
  });

  @override
  State<CifraFloatingControls> createState() => _CifraFloatingControlsState();
}

class _CifraFloatingControlsState extends State<CifraFloatingControls> with SingleTickerProviderStateMixin {
  // ── Estado ──────────────────────────────────────────────────────────────────
  bool _expandido = false;
  Offset _posicao = const Offset(160, 10);

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  // ── Constantes ───────────────────────────────────────────────────────────────
  static const double _botaoSize = 44.0;
  static const double _painelLargura = 200.0;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Lógica de posicionamento ─────────────────────────────────────────────────

  bool get _abreParaCima {
    final size = MediaQuery.of(context).size;
    return _posicao.dy > size.height / 2;
  }

  bool get _abreParaEsquerda {
    final size = MediaQuery.of(context).size;
    return _posicao.dx > size.width - _painelLargura - 20;
  }

  /// Coordenada bottom do botão em relação à tela (para ancorar Positioned)
  double get _bottomDoBotao {
    final size = MediaQuery.of(context).size;
    return size.height - _posicao.dy - _botaoSize;
  }

  void _mover(Offset delta) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _posicao = Offset(
        (_posicao.dx + delta.dx).clamp(0, size.width - _botaoSize),
        (_posicao.dy + delta.dy).clamp(0, size.height - _botaoSize),
      );
    });
  }

  void _toggle() {
    setState(() => _expandido = !_expandido);
    _expandido ? _animController.forward() : _animController.reverse();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Quando abre para cima: ancora pelo bottom para o painel crescer
    // para cima sem sair da tela nem perder o hit-test
    if (_abreParaCima) {
      return Positioned(
        left: _posicao.dx,
        bottom: _bottomDoBotao,
        child: _buildEmpilhadoCima(),
      );
    }

    return Positioned(
      left: _posicao.dx,
      top: _posicao.dy,
      child: _buildEmpilhadoBaixo(),
    );
  }

  Widget _buildEmpilhadoCima() {
    return Column(
      crossAxisAlignment: _abreParaEsquerda ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_expandido) ...[
          _buildPainel(),
          const SizedBox(height: 8),
        ],
        _buildBotaoPrincipal(),
      ],
    );
  }

  Widget _buildEmpilhadoBaixo() {
    return Column(
      crossAxisAlignment: _abreParaEsquerda ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBotaoPrincipal(),
        if (_expandido) ...[
          const SizedBox(height: 8),
          _buildPainel(),
        ],
      ],
    );
  }

  // ── Botão principal ──────────────────────────────────────────────────────────

  Widget _buildBotaoPrincipal() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      onPanUpdate: (d) => _mover(d.delta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _botaoSize,
        height: _botaoSize,
        decoration: BoxDecoration(
          color: _expandido ? AppTheme.presbyterianoVerde : AppTheme.backgroundTerciario,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.presbyterianoVerde, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _expandido ? Icons.close : Icons.tune,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  // ── Painel expandido ─────────────────────────────────────────────────────────

  Widget _buildPainel() {
    return ScaleTransition(
      scale: _scaleAnim,
      alignment: _abreParaCima
          ? (_abreParaEsquerda ? Alignment.bottomRight : Alignment.bottomLeft)
          : (_abreParaEsquerda ? Alignment.topRight : Alignment.topLeft),
      child: Container(
        width: _painelLargura,
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecundario,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.presbyterianoVerde.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecalho(),
            _buildCorpo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // captura área vazia entre widgets
      onPanUpdate: (d) => _mover(d.delta),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.presbyterianoVerde.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: const Row(
          children: [
            Text(
              'CONTROLES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.presbyterianoVerdeClaro,
                letterSpacing: 1.4,
              ),
            ),
            Spacer(),
            Icon(Icons.drag_indicator, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildCorpo() {
    final scrollAtivo = widget.autoScrollAtivo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(Icons.text_fields, 'Fonte'),
          _buildControlRow(
            valor: '${widget.config.fontSize.toInt()}px',
            onMenos: widget.onFonteMenos,
            onMais: widget.onFonteMais,
            iconMenos: Icons.text_decrease,
            iconMais: Icons.text_increase,
          ),
          const _Divisor(),
          _buildLabel(Icons.auto_mode, 'Auto-scroll'),
          const SizedBox(height: 6),
          _buildBotaoScroll(scrollAtivo),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: scrollAtivo ? _buildControleVelocidade() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoScroll(bool scrollAtivo) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: widget.onToggleScroll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: scrollAtivo ? AppTheme.presbyterianoVerde : AppTheme.presbyterianoVerde.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.presbyterianoVerde),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                scrollAtivo ? Icons.pause : Icons.play_arrow,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                scrollAtivo ? 'Pausar' : 'Iniciar',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControleVelocidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildLabel(Icons.speed, 'Velocidade'),
        _buildControlRow(
          valor: '${widget.config.velocidade.toInt()}',
          onMenos: widget.onVelocidadeMenos,
          onMais: widget.onVelocidadeMais,
          iconMenos: Icons.remove,
          iconMais: Icons.add,
        ),
      ],
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────────────────────────

  Widget _buildLabel(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildControlRow({
    required String valor,
    required VoidCallback onMenos,
    required VoidCallback onMais,
    required IconData iconMenos,
    required IconData iconMais,
  }) {
    return Row(
      children: [
        _buildIconBtn(iconMenos, onMenos),
        Expanded(
          child: Center(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _buildIconBtn(iconMais, onMais),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.backgroundTerciario,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Colors.white12, height: 1),
    );
  }
}
