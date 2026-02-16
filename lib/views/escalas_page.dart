import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/instrumentos.dart';

class EscalasPage extends StatefulWidget {
  const EscalasPage({super.key});

  @override
  State<EscalasPage> createState() => _EscalasPageState();
}

class _EscalasPageState extends State<EscalasPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTudo();
    });
  }

  Future<void> _carregarTudo() async {
    setState(() => _isLoading = true);
    try {
      final escalasProvider = Provider.of<EscalasProvider>(context, listen: false);
      final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
      final eventosProvider = Provider.of<EventoProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      await Future.wait([
        escalasProvider.listarEscalas(),
        musicosProvider.listarMusicos(),
        eventosProvider.listarEventos(),
        instrumentosProvider.listarInstrumentos(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoAdicionar(BuildContext context) {
    final obsController = TextEditingController();
    final outroInstrumentoController = TextEditingController();

    int? selectedMusicoId;
    int? selectedEventoId;
    String? selectedInstrumento;
    bool mostrarCampoOutro = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nova Escala'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- MÚSICO ---
                    Consumer<MusicosProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Músico'),
                          initialValue: selectedMusicoId,
                          items: provider.musicos.map((musico) {
                            return DropdownMenuItem<int>(
                              value: musico.id,
                              child: Text(musico.nome, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedMusicoId = valor;

                              // LÓGICA DE AUTO-SELEÇÃO COM DADOS DO BANCO
                              if (valor != null) {
                                final musico = provider.musicos.firstWhere((m) => m.id == valor);
                                final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);

                                if (musico.instrumentoPrincipal != null &&
                                    musico.instrumentoPrincipal.toString().isNotEmpty) {
                                  // Verifica se o instrumento do músico existe na lista do banco
                                  bool existeNaLista = instProvider.instrumentos
                                      .any((i) => i.nome == musico.instrumentoPrincipal.toString());

                                  if (existeNaLista) {
                                    selectedInstrumento = musico.instrumentoPrincipal.toString();
                                    mostrarCampoOutro = false;
                                  } else {
                                    // Se não existe na lista, vai para "Outro"
                                    selectedInstrumento = 'Outro';
                                    mostrarCampoOutro = true;
                                    outroInstrumentoController.text = musico.instrumentoPrincipal.toString();
                                  }
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // --- EVENTO ---
                    Consumer<EventoProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Evento'),
                          initialValue: selectedEventoId,
                          items: provider.eventos.map((evento) {
                            return DropdownMenuItem<int>(
                              value: evento.id,
                              child: Text('${evento.nome} (${evento.dataEvento.split('T')[0]})'),
                            );
                          }).toList(),
                          onChanged: (valor) => setStateDialog(() => selectedEventoId = valor),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // --- INSTRUMENTOS (VINDOS DO BANCO) ---
                    Consumer<InstrumentosProvider>(
                      builder: (context, provider, child) {
                        // Cria a lista de opções adicionando "Outro" no final
                        var listaOpcoes = provider.instrumentos.map((i) => i.nome).toList();
                        listaOpcoes.add('Outro');

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Instrumento'),
                          initialValue: selectedInstrumento,
                          items: listaOpcoes.map((nome) {
                            return DropdownMenuItem<String>(
                              value: nome,
                              child: Text(nome),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            setStateDialog(() {
                              selectedInstrumento = valor;
                              mostrarCampoOutro = (valor == 'Outro');
                              if (!mostrarCampoOutro) outroInstrumentoController.clear();
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
                              labelText: 'Qual instrumento?', hintText: 'Digite o nome do instrumento'),
                        ),
                      ),

                    TextField(
                      controller: obsController,
                      decoration: const InputDecoration(labelText: 'Observação'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    // (Mesma lógica de salvamento anterior...)
                    if (selectedMusicoId == null || selectedEventoId == null || selectedInstrumento == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios!')));
                      return;
                    }

                    String instrumentoFinal = selectedInstrumento!;
                    int? instrumentoIdFinal;

                    if (selectedInstrumento == 'Outro') {
                      if (outroInstrumentoController.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Digite o instrumento!')));
                        return;
                      }
                      // Se for "Outro", talvez precise criar um novo instrumento ou lidar de outra forma.
                      instrumentoIdFinal = null; // ou lógica para criar/obter o id do novo instrumento
                    } else {
                      final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
                      final instrumento = instProvider.instrumentos.firstWhere(
                        (i) => i.nome == instrumentoFinal,
                        orElse: () => Instrumento(id: 0, nome: ''),
                      );
                      instrumentoIdFinal = instrumento.id;
                    }

                    final novaEscala = Escala(
                      musicoId: selectedMusicoId!,
                      eventoId: selectedEventoId!,
                      instrumentoNoEvento: instrumentoIdFinal,
                      observacao: obsController.text,
                    );

                    Provider.of<EscalasProvider>(context, listen: false)
                        .adicionarEscala(novaEscala)
                        .then((_) => Navigator.of(ctx).pop())
                        .catchError(
                            (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'))));
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build e resto da classe continuam iguais...
  @override
  Widget build(BuildContext context) {
    // ... (código do build igual ao anterior)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalas'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarTudo)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAdicionar(context),
        child: const Icon(Icons.add_link),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<EscalasProvider>(
              builder: (context, provider, child) {
                if (provider.escalas.isEmpty) {
                  return const Center(child: Text('Nenhuma escala registrada.'));
                }

                return RefreshIndicator(
                  onRefresh: _carregarTudo,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.escalas.length,
                    itemBuilder: (context, index) {
                      final escala = provider.escalas[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                          title: Text(
                            escala.musicoNome ?? 'Músico #${escala.musicoId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('em: ${escala.eventoNome ?? 'Evento #${escala.eventoId}'}'),
                              if (escala.instrumentoNoEvento.toString().isNotEmpty)
                                Text(
                                  'Tocando: ${escala.instrumentoNoEvento}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              if (escala.id != null) {
                                provider.deletarEscala(escala.id!);
                              }
                            },
                          ),
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
