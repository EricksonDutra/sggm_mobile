import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/musicos.dart';
import 'package:sggm/views/perfil_edit_page.dart';

class MusicosPage extends StatefulWidget {
  const MusicosPage({super.key});

  @override
  State<MusicosPage> createState() => _MusicosPageState();
}

class _MusicosPageState extends State<MusicosPage> {
  bool _isLoading = true;
  int? _musicoLogadoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Carregar ID do músico logado
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _musicoLogadoId = auth.userData?['musico_id'];

      await _carregarMusicos();
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

                  // ✅ Dropdown de instrumentos com opção "Outro"
                  Consumer<InstrumentosProvider>(
                    builder: (context, provider, child) {
                      if (provider.instrumentos.isEmpty) {
                        return const Text(
                          'Nenhum instrumento disponível.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Instrumento Principal',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            ),
                            isExpanded: true,
                            initialValue: instrumentoSelecionadoId,
                            items: [
                              ...provider.instrumentos.map((instrumento) {
                                return DropdownMenuItem<int>(
                                  value: instrumento.id,
                                  child: Text(instrumento.nome),
                                );
                              }),
                              // ✅ NOVO: Opção "Outro"
                              const DropdownMenuItem<int>(
                                value: -1, // Valor especial para indicar "outro"
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('➕ Cadastrar Novo Instrumento'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (novoValor) async {
                              if (novoValor == -1) {
                                // ✅ Mostrar diálogo para cadastrar novo instrumento
                                final novoInstrumento = await _mostrarDialogoCadastrarInstrumento(context);

                                if (novoInstrumento != null) {
                                  // Recarregar lista de instrumentos
                                  await provider.listarInstrumentos();

                                  // Selecionar o novo instrumento
                                  setStateDialog(() {
                                    instrumentoSelecionadoId = novoInstrumento.id;
                                  });
                                }
                              } else {
                                setStateDialog(() {
                                  instrumentoSelecionadoId = novoValor;
                                });
                              }
                            },
                          ),
                        ],
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
                    instrumentoPrincipal: instrumentoSelecionadoId == -1 ? null : instrumentoSelecionadoId,
                    endereco: enderecoController.text.isNotEmpty ? enderecoController.text : null,
                    status: 'ATIVO',
                  );

                  // ✅ Converte para Map e envia
                  Provider.of<MusicosProvider>(context, listen: false)
                      .adicionarMusico(novoMusico.toJson())
                      .then((sucesso) {
                    if (sucesso) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Músico cadastrado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      final erro = Provider.of<MusicosProvider>(context, listen: false).errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(erro ?? 'Erro ao cadastrar músico'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

// ✅ NOVO: Diálogo para cadastrar novo instrumento
  Future<dynamic> _mostrarDialogoCadastrarInstrumento(BuildContext context) async {
    final nomeInstrumentoController = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.music_note, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Novo Instrumento'),
          ],
        ),
        content: TextField(
          controller: nomeInstrumentoController,
          decoration: const InputDecoration(
            labelText: 'Nome do Instrumento *',
            hintText: 'Ex: Guitarra, Bateria, Teclado...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeInstrumentoController.text.trim();

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite o nome do instrumento'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Cadastrar instrumento
              final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

              try {
                final novoInstrumento = await instrumentosProvider.adicionarInstrumento({'nome': nome});

                if (novoInstrumento != null) {
                  if (ctx.mounted) Navigator.of(ctx).pop(novoInstrumento);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Instrumento "$nome" cadastrado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao cadastrar instrumento'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  void _editarMusico(Musico musico) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isOwnProfile = musico.id == _musicoLogadoId;
    final isLider = auth.isLider;

    // Verificar permissão: pode editar se for próprio perfil OU se for líder
    if (!isOwnProfile && !isLider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para editar este perfil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegar para tela de edição
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilEditPage(
          musico: musico,
          isOwnProfile: isOwnProfile,
        ),
      ),
    );

    // Se retornou true, recarregar lista
    if (resultado == true) {
      _carregarMusicos();
    }
  }

  // ✅ NOVO: Confirmar exclusão
  void _confirmarExclusao(Musico musico) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir ${musico.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<MusicosProvider>(context, listen: false).deletarMusico(musico.id!).then((sucesso) {
                if (sucesso) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Músico excluído com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao excluir músico'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
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
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // ✅ Apenas líderes podem adicionar músicos
          if (!auth.isLider) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () => _mostrarDialogoAdicionar(context),
            child: const Icon(Icons.person_add),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MusicosProvider>(
              builder: (context, provider, child) {
                if (provider.musicos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum músico encontrado.\\nCadastre o primeiro!',
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
                      final isOwnProfile = musico.id == _musicoLogadoId;

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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  musico.nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // ✅ Badge "Você" se for o próprio perfil
                              if (isOwnProfile)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Você',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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
                          trailing: Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              final isLider = auth.isLider;

                              // ✅ Apenas líder pode excluir
                              if (!isLider) return const SizedBox.shrink();

                              return IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _confirmarExclusao(musico),
                              );
                            },
                          ),
                          onTap: () => _editarMusico(musico), // ✅ NOVO: Editar ao tocar
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
