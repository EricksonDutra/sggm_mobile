import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EscalasProvider>(context, listen: false).listarEscalas();
      Provider.of<MusicasProvider>(context, listen: false).listarMusicas();
      Provider.of<MusicosProvider>(context, listen: false).listarMusicos();
      Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos();
      Provider.of<EventoProvider>(context, listen: false).listarEventos();
    });
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
        sb.writeln('▪ ${escala.musicoNome ?? "Músico"} (${escala.instrumentoNoEvento})');
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp')));
      }
    }
  }

  // --- AÇÃO 2: Enviar para UM MÚSICO (Individual) ---
  Future<void> _notificarMusico(Escala escala) async {
    final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
    final musico =
        musicosProvider.musicos.firstWhere((m) => m.id == escala.musicoId, orElse: () => throw "Músico não achado");

    String telefone = musico.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (telefone.length <= 11) {
      telefone = "55$telefone";
    }

    final evento = widget.evento;
    String dataFormatada = evento.dataEvento.split('T')[0].split('-').reversed.join('/');

    String mensagem = "Olá *${musico.nome}*! 👋\n"
        "Você foi escalado para o *${evento.nome}* dia $dataFormatada tocando *${escala.instrumentoNoEvento}*.\n\n"
        "Confirme sua presença!";

    final Uri url = Uri.parse("https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Erro silencioso ou SnackBar
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
                    if (provider.musicos.isEmpty) {
                      return const Text('Nenhuma música cadastrada no repertório geral.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.musicos.length,
                      itemBuilder: (context, index) {
                        final musica = provider.musicos[index];
                        final estaSelecionado = selecionadas.contains(musica.id);
                        return CheckboxListTile(
                          title: Text(musica.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${musica.artista} • Tom: ${musica.tom ?? "?"}'),
                          value: estaSelecionado,
                          activeColor: Colors.teal,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              if (value == true) {
                                selecionadas.add(musica.id!);
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<EventoProvider>(context, listen: false)
                        .atualizarRepertorio(widget.evento.id!, selecionadas)
                        .then((_) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Setlist salvo com sucesso!')));
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
    String? selectedInstrumento;
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
                    Consumer<MusicosProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Músico', border: OutlineInputBorder()),
                          value: selectedMusicoId,
                          isExpanded: true,
                          items: provider.musicos
                              .map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome)))
                              .toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedMusicoId = v;
                              if (v != null) {
                                final musico = provider.musicos.firstWhere((m) => m.id == v);
                                final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
                                if (musico.instrumentoPrincipal != null) {
                                  bool existe =
                                      instProvider.instrumentos.any((i) => i.nome == musico.instrumentoPrincipal);
                                  if (existe) {
                                    selectedInstrumento = musico.instrumentoPrincipal;
                                    mostrarCampoOutro = false;
                                  } else {
                                    selectedInstrumento = 'Outro';
                                    mostrarCampoOutro = true;
                                    outroInstrumentoController.text = musico.instrumentoPrincipal!;
                                  }
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<InstrumentosProvider>(
                      builder: (context, provider, child) {
                        var lista = provider.instrumentos.map((i) => i.nome).toList();
                        if (!lista.contains('Outro')) lista.add('Outro');
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Instrumento', border: OutlineInputBorder()),
                          value: selectedInstrumento,
                          items: lista.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedInstrumento = v;
                              mostrarCampoOutro = (v == 'Outro');
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
                          decoration: const InputDecoration(labelText: 'Nome do Instrumento'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: obsController,
                      decoration: const InputDecoration(labelText: 'Observação'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMusicoId == null || selectedInstrumento == null) return;
                    final instFinal =
                        (selectedInstrumento == 'Outro') ? outroInstrumentoController.text : selectedInstrumento!;
                    final nova = Escala(
                      musicoId: selectedMusicoId!,
                      eventoId: widget.evento.id!,
                      instrumentoNoEvento: instFinal,
                      observacao: obsController.text,
                    );
                    Provider.of<EscalasProvider>(context, listen: false)
                        .adicionarEscala(nova)
                        .then((_) => Navigator.pop(ctx));
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.evento.nome, style: const TextStyle(fontSize: 18)),
            Text(widget.evento.dataEvento.split('T')[0].split('-').reversed.join('/'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Enviar Escala no Grupo',
              onPressed: _enviarParaGrupoWhatsApp,
            ),
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
              final eventoAtual =
                  provider.eventos.firstWhere((e) => e.id == widget.evento.id, orElse: () => widget.evento);
              final musicas = eventoAtual.repertorio ?? [];
              return Column(
                children: [
                  Expanded(
                    child: musicas.isEmpty
                        ? const Center(child: Text('Nenhuma música selecionada'))
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
                                    child: Text(musica.tom ?? '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(musica.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  if (escalaDoCulto.isEmpty) const Center(child: Text('Ninguém escalado ainda.')),
                  ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 8, left: 8, right: 8),
                    itemCount: escalaDoCulto.length,
                    itemBuilder: (context, index) {
                      final item = escalaDoCulto[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(item.musicoNome ?? 'Músico', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Toca: ${item.instrumentoNoEvento}'),
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
                                onPressed: () => provider.deletarEscala(item.id!),
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
}