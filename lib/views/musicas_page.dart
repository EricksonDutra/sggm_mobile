import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart'; // ✅ ADICIONAR
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/musicas.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicasPage extends StatefulWidget {
  const MusicasPage({super.key});

  @override
  State<MusicasPage> createState() => _MusicasPageState();
}

class _MusicasPageState extends State<MusicasPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarMusicas();
    });
  }

  Future<void> _carregarMusicas() async {
    setState(() => _isLoading = true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final tituloController = TextEditingController();
    final artistaController = TextEditingController();
    final tomController = TextEditingController();
    final linkCifraController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Música'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistaController,
                decoration: const InputDecoration(
                  labelText: 'Artista/Banda *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tomController,
                decoration: const InputDecoration(
                  labelText: 'Tom (Ex: G, Cm)',
                  border: OutlineInputBorder(),
                  hintText: 'C, D, Em, F#m...',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCifraController,
                decoration: const InputDecoration(
                  labelText: 'Link Cifra (Opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tituloController.text.trim().isEmpty || artistaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Título e Artista são obrigatórios!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final novaMusica = Musica(
                titulo: tituloController.text.trim(),
                artista: artistaController.text.trim(),
                tom: tomController.text.trim().isEmpty ? null : tomController.text.trim(),
                linkCifra: linkCifraController.text.trim().isEmpty ? null : linkCifraController.text.trim(),
              );

              Provider.of<MusicasProvider>(context, listen: false).adicionarMusica(novaMusica).then((_) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Música adicionada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao adicionar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Salvar'),
          ),
        ],
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
          SnackBar(content: Text('Link inválido: $e')),
        );
      }
    }
  }

  void _confirmarExclusao(Musica musica) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir "${musica.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (musica.id != null) {
                Provider.of<MusicasProvider>(context, listen: false).deletarMusica(musica.id!).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Música excluída com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NOVO: Obter permissão do usuário
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
          )
        ],
      ),

      // ✅ Botão "+" - Só para líder/admin
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoAdicionar(context),
              tooltip: 'Adicionar Música',
              child: const Icon(Icons.add),
            )
          : null, // ✅ Músico comum não vê o botão

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MusicasProvider>(
              builder: (context, provider, child) {
                if (provider.musicas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma música cadastrada',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ✅ Mensagem diferente por permissão
                        Text(
                          isLider ? 'Toque no + para adicionar' : 'Aguarde o líder adicionar músicas',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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
                              Text(musica.artista),
                              if (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                                const Row(
                                  children: [
                                    Icon(Icons.link, size: 12, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      'Cifra disponível',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // ✅ Menu de 3 pontos - Condicional
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
                                          Text(
                                            'Excluir',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
                                  : null, // ✅ Sem cifra = sem botão

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
