import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/artista.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/views/widgets/artista_selector_widget.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:sggm/views/widgets/loading/shimmer_list_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicasPage extends StatefulWidget {
  const MusicasPage({super.key});

  @override
  State<MusicasPage> createState() => _MusicasPageState();
}

class _MusicasPageState extends State<MusicasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarMusicas();
    });
  }

  Future<void> _carregarMusicas() async {
    try {
      await Provider.of<MusicasProvider>(context, listen: false).listarMusicas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar músicas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final tituloController = TextEditingController();
    final tomController = TextEditingController();
    final linkCifraController = TextEditingController();
    final linkYoutubeController = TextEditingController();
    Artista? artistaSelecionado;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.music_note),
              SizedBox(width: 8),
              Text('Nova Música'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  ArtistaSelectorWidget(
                    onArtistaSelected: (artista) {
                      setDialogState(() => artistaSelecionado = artista);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tomController,
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
                    controller: linkCifraController,
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
                    controller: linkYoutubeController,
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
              onPressed: () async {
                if (tituloController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Título é obrigatório!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (artistaSelecionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione um artista!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final novaMusica = Musica(
                  id: 0,
                  titulo: tituloController.text.trim(),
                  artistaId: artistaSelecionado!.id,
                  artistaNome: artistaSelecionado!.nome,
                  tom: tomController.text.trim().isEmpty ? null : tomController.text.trim(),
                  linkCifra: linkCifraController.text.trim().isEmpty ? null : linkCifraController.text.trim(),
                  linkYoutube: linkYoutubeController.text.trim().isEmpty ? null : linkYoutubeController.text.trim(),
                );

                try {
                  await Provider.of<MusicasProvider>(context, listen: false).adicionarMusica(novaMusica);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Música "${novaMusica.titulo}" adicionada!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao adicionar música'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirCifra(String? link) async {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum link de cifra cadastrado')),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(link);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link inválido')),
        );
      }
    }
  }

  void _confirmarExclusao(Musica musica) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      entityName: musica.titulo,
      message:
          'Deseja realmente excluir "${musica.titulo}" de ${musica.artistaNome}?\nEsta ação não pode ser desfeita.',
    );

    if (confirmed && context.mounted) {
      try {
        await Provider.of<MusicasProvider>(context, listen: false).deletarMusica(musica.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Música excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir música'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLider = auth.userData?['is_lider'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertório'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMusicas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoAdicionar(context),
              tooltip: 'Adicionar Música',
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<MusicasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 5,
              itemBuilder: (_, __) => const ShimmerListTile(showAvatar: true, showTrailing: true),
            );
          }

          if (provider.musicas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma música cadastrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLider ? 'Toque no + para adicionar' : 'Aguarde o líder adicionar músicas',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _carregarMusicas,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.musicas.length,
              itemBuilder: (context, index) {
                final musica = provider.musicas[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        musica.tom?.isNotEmpty == true ? musica.tom! : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      musica.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(musica.artistaNome),
                        if (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                          const Row(
                            children: [
                              Icon(Icons.link, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Cifra disponível',
                                style: TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: isLider
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'cifra') {
                                _abrirCifra(musica.linkCifra);
                              } else if (value == 'excluir') {
                                _confirmarExclusao(musica);
                              }
                            },
                            itemBuilder: (context) => [
                              if (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                                const PopupMenuItem(
                                  value: 'cifra',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_browser, size: 18),
                                      SizedBox(width: 8),
                                      Text('Abrir Cifra'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                            ? IconButton(
                                icon: const Icon(Icons.open_in_browser, color: Colors.blue),
                                tooltip: 'Abrir Cifra',
                                onPressed: () => _abrirCifra(musica.linkCifra),
                              )
                            : null,
                    onTap: () => _abrirCifra(musica.linkCifra),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
