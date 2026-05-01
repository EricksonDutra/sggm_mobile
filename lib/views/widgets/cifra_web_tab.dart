import 'package:flutter/material.dart';
import 'package:sggm/controllers/musica_detalhes_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CifraWebTab extends StatelessWidget {
  final MusicaDetalhesController controller;

  const CifraWebTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.webViewController == null) {
      return const Center(
        child: Text('Não foi possível carregar a cifra', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        _buildBarra(context),
        Expanded(child: _buildWebView()),
      ],
    );
  }

  Widget _buildBarra(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tom: ${controller.musica.tom ?? "Não informado"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          if (controller.isLoadingWebView)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.black87),
            tooltip: 'Abrir no navegador',
            onPressed: () => controller.abrirLink(controller.musica.linkCifra!),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: controller.webViewController!),
        if (controller.isLoadingWebView) const LinearProgressIndicator(),
      ],
    );
  }
}
