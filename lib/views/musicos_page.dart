import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/musicos.dart';

class MusicosPage extends StatefulWidget {
  const MusicosPage({super.key});

  @override
  State<MusicosPage> createState() => _MusicosPageState();
}

class _MusicosPageState extends State<MusicosPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarMusicos();
    });
  }

  Future<void> _carregarMusicos() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<MusicosProvider>(context, listen: false).listarMusicos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar músicos: $e'),
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

  // Diálogo para cadastro rápido
  void _mostrarDialogoAdicionar(BuildContext context) {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();
    final instrumentoController = TextEditingController();
    final enderecoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Músico'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome *')),
              TextField(
                  controller: instrumentoController,
                  decoration: const InputDecoration(labelText: 'Instrumento Principal (Ex: Baixo)')),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone *'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              // Validação básica
              if (nomeController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e email!')));
                return;
              }

              final novoMusico = Musico(
                nome: nomeController.text,
                telefone: telefoneController.text,
                email: emailController.text,
                instrumentoPrincipal: instrumentoController.text,
                endereco: enderecoController.text,
              );

              // Chama o provider para salvar no Django
              Provider.of<MusicosProvider>(context, listen: false).adicionarMusico(novoMusico).then((_) {
                Navigator.of(ctx).pop(); // Fecha o diálogo
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Músico cadastrado com sucesso!')));
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
        title: const Text('Músicos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMusicos,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAdicionar(context),
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MusicosProvider>(
              builder: (context, provider, child) {
                if (provider.musicos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum músico encontrado.\nCadastre o primeiro!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _carregarMusicos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: provider.musicos.length,
                    itemBuilder: (context, index) {
                      final musico = provider.musicos[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              musico.nome.isNotEmpty ? musico.nome[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            musico.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (musico.instrumentoPrincipal != null && musico.instrumentoPrincipal!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.music_note, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        musico.instrumentoPrincipal!,
                                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.email, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(musico.email, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(musico.telefone),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              // Exemplo simples de exclusão
                              // Idealmente mostraria um diálogo de confirmação antes
                              if (musico.id != null) {
                                Provider.of<MusicosProvider>(context, listen: false).deletarMusico(musico.id!);
                              }
                            },
                          ),
                          onTap: () {
                            // Futuro: Editar músico
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
