import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
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

  void _mostrarDialogoAdicionar(BuildContext context) async {
    // ✅ Carrega instrumentos ANTES de mostrar o diálogo
    final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

    if (instrumentosProvider.instrumentos.isEmpty) {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await instrumentosProvider.listarInstrumentos();

      if (context.mounted) {
        Navigator.pop(context); // Fecha loading
      }
    }

    // Agora mostra o diálogo com os dados já carregados
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController();
    final enderecoController = TextEditingController();

    int? instrumentoSelecionadoId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Novo Músico'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                  ),
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
                  const SizedBox(height: 16),

                  // ✅ Agora os dados já estão carregados, sem FutureBuilder
                  Consumer<InstrumentosProvider>(
                    builder: (context, provider, child) {
                      if (provider.instrumentos.isEmpty) {
                        return const Text(
                          'Nenhum instrumento disponível.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Instrumento Principal',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        isExpanded: true,
                        initialValue: instrumentoSelecionadoId,
                        items: provider.instrumentos.map((instrumento) {
                          return DropdownMenuItem<int>(
                            value: instrumento.id,
                            child: Text(instrumento.nome),
                          );
                        }).toList(),
                        onChanged: (novoValor) {
                          setStateDialog(() {
                            instrumentoSelecionadoId = novoValor;
                          });
                        },
                      );
                    },
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
                  // Validação simples
                  if (nomeController.text.isEmpty || emailController.text.isEmpty || telefoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Preencha nome, telefone e email!')));
                    return;
                  }

                  // Cria o objeto Musico
                  final novoMusico = Musico(
                    nome: nomeController.text,
                    telefone: telefoneController.text,
                    email: emailController.text,
                    instrumentoPrincipal: instrumentoSelecionadoId,
                    endereco: enderecoController.text.isNotEmpty ? enderecoController.text : null,
                    status: 'ATIVO',
                  );

                  // ✅ Converte para Map e envia
                  Provider.of<MusicosProvider>(context, listen: false)
                      .adicionarMusico(novoMusico.toJson()) // ✅ Usando toJson()
                      .then((sucesso) {
                    if (sucesso) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Músico cadastrado com sucesso!'),
                        backgroundColor: Colors.green,
                      ));
                    } else {
                      final erro = Provider.of<MusicosProvider>(context, listen: false).errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(erro ?? 'Erro ao cadastrar músico'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ));
                  });
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
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
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: musico.status == 'ATIVO'
                                    ? Colors.deepPurple
                                    : musico.status == 'AFASTADO'
                                        ? Colors.orange
                                        : Colors.grey,
                                child: Text(
                                  musico.nome.isNotEmpty ? musico.nome[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              if (musico.status != 'ATIVO')
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: musico.status == 'INATIVO' ? Colors.red : Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            musico.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (musico.instrumentoPrincipalNome != null &&
                                  musico.instrumentoPrincipalNome!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.music_note, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        musico.instrumentoPrincipalNome!,
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
