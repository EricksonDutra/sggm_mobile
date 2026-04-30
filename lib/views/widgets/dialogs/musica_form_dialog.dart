import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/artista.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/views/widgets/artista_selector_widget.dart';

class MusicaFormDialog extends StatefulWidget {
  const MusicaFormDialog({super.key, this.musicaInicial});

  final Musica? musicaInicial;

  static Future<void> show(BuildContext context, {Musica? musicaInicial}) {
    return showDialog(
      context: context,
      builder: (_) => MusicaFormDialog(musicaInicial: musicaInicial),
    );
  }

  @override
  State<MusicaFormDialog> createState() => _MusicaFormDialogState();
}

class _MusicaFormDialogState extends State<MusicaFormDialog> {
  late final TextEditingController _tituloController;
  late final TextEditingController _tomController;
  late final TextEditingController _linkCifraController;
  late final TextEditingController _linkYoutubeController;
  Artista? _artistaSelecionado;

  bool get _isEdicao => widget.musicaInicial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.musicaInicial;
    _tituloController = TextEditingController(text: m?.titulo ?? '');
    _tomController = TextEditingController(text: m?.tom ?? '');
    _linkCifraController = TextEditingController(text: m?.linkCifra ?? '');
    _linkYoutubeController = TextEditingController(text: m?.linkYoutube ?? '');
    if (m != null) {
      _artistaSelecionado = Artista(id: m.artistaId, nome: m.artistaNome);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _tomController.dispose();
    _linkCifraController.dispose();
    _linkYoutubeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título é obrigatório!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_artistaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um artista!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final musica = Musica(
      id: widget.musicaInicial?.id ?? 0,
      titulo: _tituloController.text.trim(),
      artistaId: _artistaSelecionado!.id,
      artistaNome: _artistaSelecionado!.nome,
      tom: _tomController.text.trim().isEmpty ? null : _tomController.text.trim(),
      linkCifra: _linkCifraController.text.trim().isEmpty ? null : _linkCifraController.text.trim(),
      linkYoutube: _linkYoutubeController.text.trim().isEmpty ? null : _linkYoutubeController.text.trim(),
    );

    try {
      final provider = Provider.of<MusicasProvider>(context, listen: false);
      if (_isEdicao) {
        await provider.atualizarMusica(musica.id!, musica);
      } else {
        await provider.adicionarMusica(musica);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdicao ? '"${musica.titulo}" atualizada!' : 'Música "${musica.titulo}" adicionada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdicao ? 'Erro ao editar música' : 'Erro ao adicionar música'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEdicao ? Icons.edit_outlined : Icons.music_note),
          const SizedBox(width: 8),
          Text(_isEdicao ? 'Editar Música' : 'Nova Música'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              ArtistaSelectorWidget(
                artistaInicial: _artistaSelecionado,
                onArtistaSelected: (a) => setState(() => _artistaSelecionado = a),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tomController,
                decoration: const InputDecoration(
                  labelText: 'Tom (Ex: G, Cm)',
                  border: OutlineInputBorder(),
                  hintText: 'C, D, Em, F#m...',
                  prefixIcon: Icon(Icons.music_video),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkCifraController,
                decoration: const InputDecoration(
                  labelText: 'Link Cifra (Opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkYoutubeController,
                decoration: const InputDecoration(
                  labelText: 'Link YouTube (Opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://youtube.com/...',
                  prefixIcon: Icon(Icons.video_library),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Salvar'),
          onPressed: _salvar,
        ),
      ],
    );
  }
}
