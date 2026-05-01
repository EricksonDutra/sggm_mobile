import 'package:flutter/material.dart';
import 'package:sggm/controllers/musica_detalhes_controller.dart';
import 'package:sggm/util/cifra_parser.dart';
import 'package:sggm/views/widgets/cifra_floating_controls.dart';
import 'package:sggm/views/widgets/cifra_secao_widget.dart';

class CifraNativaTab extends StatelessWidget {
  final MusicaDetalhesController controller;

  const CifraNativaTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final conteudo = CifraParser.transporCifra(
      controller.musica.conteudoCifra!,
      controller.semitonsDelta,
    );
    final secoes = CifraParser.parsearSecoes(conteudo);
    final usarDuasColunas = MediaQuery.of(context).size.width > 800;

    return Stack(
      children: [
        Listener(
          onPointerDown: (_) => controller.iniciarInteracao(),
          onPointerUp: (_) => controller.encerrarInteracao(),
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, usarDuasColunas ? 16 : 72, 80),
                  child: usarDuasColunas
                      ? _buildDuasColunas(secoes, controller.scrollConfig.fontSize)
                      : _buildUmaColuna(secoes, controller.scrollConfig.fontSize),
                ),
              ),
            ],
          ),
        ),
        _buildControles(context),
      ],
    );
  }

  Widget _buildUmaColuna(List<SecaoCifra> secoes, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...secoes.map((s) => CifraSecaoWidget(secao: s, fontSize: fontSize)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDuasColunas(List<SecaoCifra> secoes, double fontSize) {
    final metade = (secoes.length / 2).ceil();
    final esquerda = secoes.sublist(0, metade);
    final direita = secoes.sublist(metade);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: esquerda.map((s) => CifraSecaoWidget(secao: s, fontSize: fontSize)).toList(),
          ),
        ),
        // Sem divisória — espaço entre colunas resolve visualmente
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: direita.map((s) => CifraSecaoWidget(secao: s, fontSize: fontSize)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControles(BuildContext context) {
    final c = controller;
    return CifraFloatingControls(
      config: c.scrollConfig,
      autoScrollAtivo: c.autoScrollAtivo,
      onToggleScroll: c.toggleAutoScroll,
      onFonteMais: c.aumentarFonte,
      onFonteMenos: c.diminuirFonte,
      onVelocidadeChanged: c.setVelocidade,
      tomAtual: c.tomAtualDisplay ?? c.musica.tom,
      semitonsDelta: c.semitonsDelta,
      onTomMenos: () => c.transporTom(-1),
      onTomMais: () => c.transporTom(1),
      onTomReset: c.resetarTom,
      modoCifra: (c.hasCifraNativa && c.hasCifraWeb) ? c.modoCifra : null,
      onModoChanged: (c.hasCifraNativa && c.hasCifraWeb) ? c.setModoCifra : null,
    );
  }
}
