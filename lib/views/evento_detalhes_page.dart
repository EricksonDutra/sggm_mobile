import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';

class EventoDetalhesPage extends StatefulWidget {
  final Evento evento;

  const EventoDetalhesPage({super.key, required this.evento});

  @override
  State<EventoDetalhesPage> createState() => _EventoDetalhesPageState();
}

class _EventoDetalhesPageState extends State<EventoDetalhesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        Provider.of<EscalasProvider>(context, listen: false).listarEscalas(),
        Provider.of<MusicasProvider>(context, listen: false).listarMusicas(),
        Provider.of<MusicosProvider>(context, listen: false).listarMusicos(),
        Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos(),
        Provider.of<EventoProvider>(context, listen: false).listarEventos(),
      ]);
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
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

  // ✅ Função auxiliar para obter nome do instrumento
  String _obterNomeInstrumento(int? instrumentoId) {
    if (instrumentoId == null) return 'Não especificado';

    try {
      final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
      final instrumento = instProvider.instrumentos.firstWhere(
        (i) => i.id == instrumentoId,
        orElse: () => Instrumento(id: 0, nome: 'Desconhecido'),
      );
      return instrumento.nome;
    } catch (e) {
      return 'Desconhecido';
    }
  }

  // --- FUNÇÃO AUXILIAR: Monta o Texto da Escala ---
  String _gerarTextoEscala() {
    final eventoAtual = Provider.of<EventoProvider>(context, listen: false)
        .eventos
        .firstWhere((e) => e.id == widget.evento.id, orElse: () => widget.evento);

    final escalasDoEvento = Provider.of<EscalasProvider>(context, listen: false)
        .escalas
        .where((e) => e.eventoId == widget.evento.id)
        .toList();

    final musicas = eventoAtual.repertorio ?? [];

    StringBuffer sb = StringBuffer();
    sb.writeln('*${eventoAtual.nome}*'); // Negrito no WhatsApp
    String dataFormatada = eventoAtual.dataEvento.split('T')[0].split('-').reversed.join('/');
    sb.writeln('🗓 $dataFormatada');
    sb.writeln('📍 ${eventoAtual.local}');
    sb.writeln('');

    sb.writeln('*BANDA:*');
    if (escalasDoEvento.isEmpty) {
      sb.writeln('(Ninguém escalado)');
    } else {
      for (var escala in escalasDoEvento) {
        final instrumentoNome = _obterNomeInstrumento(escala.instrumentoNoEvento);
        sb.writeln('▪ ${escala.musicoNome ?? "Músico"} ($instrumentoNome)');
      }
    }
    sb.writeln('');

    sb.writeln('*REPERTÓRIO:*');
    if (musicas.isEmpty) {
      sb.writeln('(A definir)');
    } else {
      for (var i = 0; i < musicas.length; i++) {
        var m = musicas[i];
        sb.writeln('${i + 1}. ${m.titulo} - ${m.artista} [${m.tom ?? "?"}]');
      }
    }

    return sb.toString();
  }

  // --- AÇÃO 1: Enviar para o GRUPO (Geral) ---
  Future<void> _enviarParaGrupoWhatsApp() async {
    String texto = _gerarTextoEscala();
    final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(texto)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  // --- AÇÃO 2: Enviar para UM MÚSICO (Individual) ---
  Future<void> _notificarMusico(Escala escala) async {
    final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);

    try {
      final musico = musicosProvider.musicos.firstWhere(
        (m) => m.id == escala.musicoId,
      );

      String telefone = musico.telefone.replaceAll(RegExp(r'[^0-9]'), '');
      if (telefone.length <= 11) {
        telefone = "55$telefone";
      }

      final evento = widget.evento;
      String dataFormatada = evento.dataEvento.split('T')[0].split('-').reversed.join('/');

      final instrumentoNome = _obterNomeInstrumento(escala.instrumentoNoEvento);

      String mensagem = "Olá *${musico.nome}*! 👋\n"
          "Você foi escalado para o *${evento.nome}* dia $dataFormatada tocando *$instrumentoNome*.\n\n"
          "Confirme sua presença!";

      final Uri url = Uri.parse("https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}");

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao notificar músico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  // --- INTERFACE: Selecionar Músicas ---
  void _mostrarSelecaoMusicas(BuildContext context, Evento eventoAtual) {
    List<int> selecionadas = [];
    if (eventoAtual.repertorio != null) {
      selecionadas = eventoAtual.repertorio!.map((m) => m.id!).toList();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gerenciar Setlist'),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<MusicasProvider>(
                  builder: (context, provider, child) {
                    // ✅ CORREÇÃO: musicas em vez de musicos
                    if (provider.musicas.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma música cadastrada no repertório geral.'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.musicas.length, // ✅ CORREÇÃO
                      itemBuilder: (context, index) {
                        final musica = provider.musicas[index]; // ✅ CORREÇÃO
                        final estaSelecionado = selecionadas.contains(musica.id);

                        return CheckboxListTile(
                          title: Text(
                            musica.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${musica.artista} • Tom: ${musica.tom ?? "?"}'),
                          value: estaSelecionado,
                          activeColor: Colors.teal,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              if (value == true) {
                                if (musica.id != null) {
                                  selecionadas.add(musica.id!);
                                }
                              } else {
                                selecionadas.remove(musica.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<EventoProvider>(context, listen: false)
                        .atualizarRepertorio(widget.evento.id!, selecionadas)
                        .then((_) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Setlist salvo com sucesso!')),
                      );
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar: $e')),
                      );
                    });
                  },
                  child: const Text('Salvar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- LÓGICA DA ESCALA (Adicionar Músico) ---
  void _adicionarMusicoNaEscala(BuildContext context) {
    final outroInstrumentoController = TextEditingController();
    final obsController = TextEditingController();
    int? selectedMusicoId;
    int? selectedInstrumentoId; // ✅ Usar ID em vez de nome
    bool mostrarCampoOutro = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Escalar Músico'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown de Músicos
                    Consumer<MusicosProvider>(
                      builder: (context, provider, child) {
                        if (provider.musicos.isEmpty) {
                          return const Text('Nenhum músico cadastrado');
                        }

                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Músico',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: selectedMusicoId,
                          isExpanded: true,
                          items: provider.musicos.map((m) {
                            return DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.nome),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedMusicoId = v;

                              // Auto-selecionar instrumento principal
                              if (v != null) {
                                final musico = provider.musicos.firstWhere((m) => m.id == v);
                                if (musico.instrumentoPrincipal != null) {
                                  selectedInstrumentoId = musico.instrumentoPrincipal;
                                  mostrarCampoOutro = false;
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown de Instrumentos
                    Consumer<InstrumentosProvider>(
                      builder: (context, provider, child) {
                        if (provider.instrumentos.isEmpty) {
                          return const Text('Nenhum instrumento cadastrado');
                        }

                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Instrumento',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: selectedInstrumentoId,
                          isExpanded: true,
                          items: provider.instrumentos.map((inst) {
                            return DropdownMenuItem<int>(
                              value: inst.id,
                              child: Text(inst.nome),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedInstrumentoId = v;
                              // Se o nome for "Outro", mostrar campo
                              if (v != null) {
                                final inst = provider.instrumentos.firstWhere((i) => i.id == v);
                                mostrarCampoOutro = inst.nome.toLowerCase() == 'outro';
                              }
                            });
                          },
                        );
                      },
                    ),

                    if (mostrarCampoOutro)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: outroInstrumentoController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Instrumento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    TextField(
                      controller: obsController,
                      decoration: const InputDecoration(
                        labelText: 'Observação',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMusicoId == null || selectedInstrumentoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione músico e instrumento')),
                      );
                      return;
                    }

                    final nova = Escala(
                      musicoId: selectedMusicoId!,
                      eventoId: widget.evento.id!,
                      instrumentoNoEvento: selectedInstrumentoId, // ✅ ID do instrumento
                      observacao: obsController.text.isEmpty ? null : obsController.text,
                    );

                    Provider.of<EscalasProvider>(context, listen: false).adicionarEscala(nova).then((_) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Músico escalado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    });
                  },
                  child: const Text('Adicionar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.evento.nome, style: const TextStyle(fontSize: 18)),
            Text(
              widget.evento.dataEvento.split('T')[0].split('-').reversed.join('/'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Enviar Escala no Grupo',
            onPressed: _enviarParaGrupoWhatsApp,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'SETLIST', icon: Icon(Icons.queue_music)),
            Tab(text: 'ESCALA', icon: Icon(Icons.groups)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ABA SETLIST
          Consumer<EventoProvider>(
            builder: (context, provider, child) {
              final eventoAtual = provider.eventos.firstWhere(
                (e) => e.id == widget.evento.id,
                orElse: () => widget.evento,
              );
              final musicas = eventoAtual.repertorio ?? [];

              return Column(
                children: [
                  Expanded(
                    child: musicas.isEmpty
                        ? const Center(
                            child: Text('Nenhuma música selecionada'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: musicas.length,
                            itemBuilder: (context, index) {
                              final musica = musicas[index];
                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Text(
                                      musica.tom ?? '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    musica.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(musica.artista),
                                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('GERENCIAR MÚSICAS'),
                      onPressed: () => _mostrarSelecaoMusicas(context, eventoAtual),
                    ),
                  ),
                ],
              );
            },
          ),

          // ABA ESCALA
          Consumer<EscalasProvider>(
            builder: (context, provider, child) {
              final escalaDoCulto = provider.escalas.where((e) => e.eventoId == widget.evento.id).toList();

              return Stack(
                children: [
                  if (escalaDoCulto.isEmpty)
                    const Center(child: Text('Ninguém escalado ainda.'))
                  else
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 8, left: 8, right: 8),
                      itemCount: escalaDoCulto.length,
                      itemBuilder: (context, index) {
                        final item = escalaDoCulto[index];
                        final instrumentoNome = _obterNomeInstrumento(item.instrumentoNoEvento);

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              item.musicoNome ?? 'Músico',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Toca: $instrumentoNome'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.send_to_mobile, color: Colors.green),
                                  tooltip: 'Avisar no WhatsApp',
                                  onPressed: () => _notificarMusico(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    if (item.id != null) {
                                      provider.deletarEscala(item.id!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => _adicionarMusicoNaEscala(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Escalar'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
