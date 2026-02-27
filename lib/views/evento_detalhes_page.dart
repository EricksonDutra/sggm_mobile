// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/views/escalas_page.dart';
import 'package:sggm/views/musica_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';

import 'package:sggm/views/comentarios_page.dart';

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
      AppLogger.error('❌ Erro ao carregar dados: $e');
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

  bool get _eventoJaAconteceu {
    try {
      final data = DateTime.parse(widget.evento.dataEvento);
      return data.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

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

    // ── CABEÇALHO ──────────────────────────────────────────
    sb.writeln('*${eventoAtual.nome.toUpperCase()}*');

    // Tipo do evento (CULTO, CASAMENTO, etc.)
    if (eventoAtual.tipo.isNotEmpty) {
      sb.writeln('🎵 Tipo: ${eventoAtual.tipo}');
    }

    // Data do evento
    String dataFormatada = eventoAtual.dataEvento.split('T')[0].split('-').reversed.join('/');
    sb.writeln('🗓 Data: $dataFormatada');

    // Horário do evento (se disponível na string ISO)
    final temHorario = eventoAtual.dataEvento.contains('T');
    if (temHorario) {
      final horario = eventoAtual.dataEvento.split('T')[1].substring(0, 5);
      sb.writeln('🕐 Horário: $horario');
    }

    sb.writeln('📍 Local: ${eventoAtual.local}');

    // Descrição/observação do evento
    if (eventoAtual.descricao != null && eventoAtual.descricao!.trim().isNotEmpty) {
      sb.writeln('📝 ${eventoAtual.descricao}');
    }

    sb.writeln('');

    // ── ENSAIO ─────────────────────────────────────────────
    if (eventoAtual.dataHoraEnsaio != null) {
      sb.writeln('*ENSAIO:*');
      final ensaio = eventoAtual.dataHoraEnsaio!;
      final diaEnsaio =
          '${ensaio.day.toString().padLeft(2, '0')}/${ensaio.month.toString().padLeft(2, '0')}/${ensaio.year}';
      final horaEnsaio = '${ensaio.hour.toString().padLeft(2, '0')}:${ensaio.minute.toString().padLeft(2, '0')}';
      sb.writeln('📅 $diaEnsaio às $horaEnsaio');
      sb.writeln('');
    }

    // ── BANDA ──────────────────────────────────────────────
    sb.writeln('*BANDA:*');
    if (escalasDoEvento.isEmpty) {
      sb.writeln('(Ninguém escalado)');
    } else {
      final confirmados = escalasDoEvento.where((e) => e.confirmado).toList();
      final pendentes = escalasDoEvento.where((e) => !e.confirmado).toList();

      for (var escala in confirmados) {
        final instrumentoNome = _obterNomeInstrumento(escala.instrumentoNoEvento);
        sb.writeln('✅ ${escala.musicoNome ?? "Músico"} ($instrumentoNome)');
      }
      for (var escala in pendentes) {
        final instrumentoNome = _obterNomeInstrumento(escala.instrumentoNoEvento);
        sb.writeln('⏳ ${escala.musicoNome ?? "Músico"} ($instrumentoNome)');
      }

      // Observações individuais
      final comObservacao = escalasDoEvento.where((e) => e.observacao != null && e.observacao!.trim().isNotEmpty);
      if (comObservacao.isNotEmpty) {
        sb.writeln('');
        sb.writeln('_Obs:_');
        for (var escala in comObservacao) {
          sb.writeln('• ${escala.musicoNome ?? "Músico"}: ${escala.observacao}');
        }
      }
    }
    sb.writeln('');

    // ── REPERTÓRIO ─────────────────────────────────────────
    sb.writeln('*REPERTÓRIO:*');
    if (musicas.isEmpty) {
      sb.writeln('(A definir)');
    } else {
      for (var i = 0; i < musicas.length; i++) {
        final m = musicas[i];
        final tom = m.tom ?? '?';
        sb.writeln('${i + 1}. *${m.titulo}* - ${m.artistaNome} [Tom: $tom]');

        if (m.linkYoutube != null && m.linkYoutube!.isNotEmpty) {
          sb.writeln('   🎬 ${m.linkYoutube}');
        }
      }
    }
    sb.writeln('');

    // ── RODAPÉ ─────────────────────────────────────────────
    sb.writeln('_Enviado pelo app SGGM_ 🎶');

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
      AppLogger.error('❌ Erro ao notificar músico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _mostrarSelecaoMusicas(BuildContext context, Evento eventoAtual) {
    final Set<int> selecionadas = {
      ...?eventoAtual.repertorio?.where((m) => m.id != null).map((m) => m.id!),
    };
    final TextEditingController buscaController = TextEditingController();
    String termoBusca = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gerenciar Setlist'),
              contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<MusicasProvider>(
                  builder: (context, provider, child) {
                    if (provider.musicas.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nenhuma música cadastrada no repertório geral.'),
                      );
                    }

                    final musicasFiltradas = termoBusca.isEmpty
                        ? provider.musicas
                        : provider.musicas
                            .where(
                              (m) =>
                                  m.titulo.toLowerCase().contains(termoBusca.toLowerCase()) ||
                                  m.artistaNome.toLowerCase().contains(termoBusca.toLowerCase()),
                            )
                            .toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Campo de busca ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: buscaController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Buscar música ou artista...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: termoBusca.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        buscaController.clear();
                                        setStateDialog(() => termoBusca = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (v) => setStateDialog(() => termoBusca = v),
                          ),
                        ),

                        // ── Contador ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                '${selecionadas.length} selecionada${selecionadas.length != 1 ? "s" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (termoBusca.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• ${musicasFiltradas.length} resultado${musicasFiltradas.length != 1 ? "s" : ""}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // ── Lista ───────────────────────────────────────
                        Flexible(
                          child: musicasFiltradas.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Nenhuma música encontrada para "$termoBusca"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: musicasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final musica = musicasFiltradas[index];
                                    final id = musica.id;
                                    final selecionado = id != null && selecionadas.contains(id);

                                    return CheckboxListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                      value: selecionado,
                                      activeColor: Colors.teal,
                                      // Nome + artista na mesma linha
                                      title: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: DefaultTextStyle.of(context).style,
                                          children: [
                                            TextSpan(
                                              text: musica.titulo,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: '  •  ${musica.artistaNome}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (bool? value) {
                                        if (id == null) return;
                                        setStateDialog(() {
                                          if (value == true) {
                                            selecionadas.add(id);
                                          } else {
                                            selecionadas.remove(id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
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
                  onPressed: () async {
                    try {
                      await Provider.of<EventoProvider>(context, listen: false)
                          .atualizarRepertorio(widget.evento.id!, selecionadas.toList());
                      if (context.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Setlist salvo com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar: $e')),
                        );
                      }
                    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ NOVO: Obter permissão do usuário
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLider = auth.userData?['is_lider'] ?? false;

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
          // ✅ Só líder/admin pode enviar para grupo
          if (isLider)
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
          // ========== ABA SETLIST ==========
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
                                  subtitle: Text(musica.artistaNome),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (musica.linkYoutube != null && musica.linkYoutube!.isNotEmpty)
                                        const Icon(Icons.play_circle, color: Colors.red, size: 20),
                                      const SizedBox(width: 4),
                                      if (musica.linkCifra != null && musica.linkCifra!.isNotEmpty)
                                        const Icon(Icons.music_note, color: Colors.blue, size: 20),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          Icons.chat_bubble_outline,
                                          size: 20,
                                          color: _eventoJaAconteceu ? Colors.teal : Colors.grey[600],
                                        ),
                                        tooltip: _eventoJaAconteceu ? 'Comentários' : 'Disponível após o evento',
                                        onPressed: _eventoJaAconteceu
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ComentariosPage(
                                                      eventoId: eventoAtual.id!,
                                                      eventoNome: eventoAtual.nome,
                                                      eventoDataEvento: eventoAtual.dataEvento,
                                                      musica: musica,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null, // ← null desabilita o botão automaticamente no Flutter
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MusicaDetalhesPage(musica: musica),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),

                  // ✅ BOTÃO "GERENCIAR MÚSICAS" - Só para líder/admin
                  if (isLider)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('GERENCIAR MÚSICAS'),
                        onPressed: () => _mostrarSelecaoMusicas(context, eventoAtual),
                      ),
                    ),
                  const Padding(padding: EdgeInsets.only(bottom: 16))
                ],
              );
            },
          ),

          // ========== ABA ESCALA ==========
          Consumer<EscalasProvider>(
            builder: (context, provider, child) {
              final escalaDoCulto = provider.escalas.where((e) => e.eventoId == widget.evento.id).toList();

              return Stack(
                children: [
                  if (escalaDoCulto.isEmpty)
                    const Center(child: Text('Ninguém escalado ainda.'))
                  else
                    ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: isLider ? 80 : 8, // ✅ Espaço menor se não houver botão
                        top: 8,
                        left: 8,
                        right: 8,
                      ),
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

                            // ✅ Ações visíveis SÓ para líder/admin
                            trailing: isLider
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.send_to_mobile, color: Colors.green),
                                        tooltip: 'Avisar no WhatsApp',
                                        onPressed: () => _notificarMusico(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () async {
                                          final confirmed = await ConfirmDeleteDialog.show(
                                            context,
                                            entityName: item.musicoNome ?? 'Músico',
                                            message:
                                                'Deseja remover ${item.musicoNome ?? "este músico"} da escala?\nEsta ação não pode ser desfeita.',
                                          );
                                          if (confirmed && context.mounted && item.id != null) {
                                            provider.deletarEscala(item.id!);
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : null, // ✅ Músico comum não vê botões
                          ),
                        );
                      },
                    ),

                  // ✅ BOTÃO "ESCALAR" - Só para líder/admin
                  if (isLider)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.extended(
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EscalasPage())),
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
