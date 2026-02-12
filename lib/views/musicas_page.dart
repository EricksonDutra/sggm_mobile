import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/musicas.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                decoration: const InputDecoration(labelText: 'Título *'),
              ),
              TextField(
                controller: artistaController,
                decoration: const InputDecoration(labelText: 'Artista/Banda *'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tomController,
                      decoration: const InputDecoration(labelText: 'Tom (Ex: G, Cm)'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: linkCifraController,
                decoration: const InputDecoration(labelText: 'Link Cifra (Opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (tituloController.text.isEmpty || artistaController.text.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Título e Artista são obrigatórios!')));
                return;
              }

              final novaMusica = Musica(
                titulo: tituloController.text,
                artista: artistaController.text,
                tom: tomController.text,
                linkCifra: linkCifraController.text,
              );

              Provider.of<MusicasProvider>(context, listen: false).adicionarMusica(novaMusica).then((_) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Música adicionada!')));
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertório'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarMusicas)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAdicionar(context),
        child: const Icon(Icons.queue_music),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MusicasProvider>(
              builder: (context, provider, child) {
                if (provider.musicos.isEmpty) {
                  // Nota: O getter no controller chama 'musicos' (lista)
                  return const Center(child: Text('Nenhuma música cadastrada.'));
                }

                return RefreshIndicator(
                  onRefresh: _carregarMusicas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.musicos.length,
                    itemBuilder: (context, index) {
                      final musica = provider.musicos[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(
                              musica.tom?.isNotEmpty == true ? musica.tom! : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          title: Text(
                            musica.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(musica.artista),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () {
                              if (musica.id != null) {
                                provider.deletarMusica(musica.id!);
                              }
                            },
                          ),
                          onTap: () {
                            // Futuro: Abrir link da cifra
                          },
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
