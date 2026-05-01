import 'package:flutter/material.dart';
import 'package:sggm/controllers/musica_detalhes_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeTab extends StatelessWidget {
  final MusicaDetalhesController controller;

  const YoutubeTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.youtubeController == null) {
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

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller.youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
      builder: (context, player) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            player,
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(Icons.music_note, 'Tom', controller.musica.tom ?? 'Não informado'),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.person, 'Artista', controller.musica.artistaNome),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir no YouTube'),
                      onPressed: () => controller.abrirLink(controller.musica.linkYoutube!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
