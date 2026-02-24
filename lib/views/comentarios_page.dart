// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/comentarios_controller.dart';
import 'package:sggm/models/comentario.dart';
import 'package:sggm/models/musicas.dart';

class ComentariosPage extends StatefulWidget {
  final int eventoId;
  final String eventoNome;
  final String eventoDataEvento; // ← NOVO: ISO 8601 ex: "2026-02-25T19:00:00"
  final Musica? musica;

  const ComentariosPage({
    super.key,
    required this.eventoId,
    required this.eventoNome,
    required this.eventoDataEvento, // ← NOVO
    this.musica,
  });

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final _textoController = TextEditingController();
  final _scrollController = ScrollController();
  bool _enviando = false;
  late ComentariosProvider _provider;

  // ── Verifica se o evento já aconteceu ──
  bool get _eventoJaAconteceu {
    try {
      final data = DateTime.parse(widget.eventoDataEvento);
      return data.isBefore(DateTime.now());
    } catch (_) {
      return false; // se não conseguir parsear, bloqueia por segurança
    }
  }

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<ComentariosProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final provider = Provider.of<ComentariosProvider>(context, listen: false);
    if (widget.musica != null) {
      await provider.listarPorMusica(widget.eventoId, widget.musica!.id!);
    } else {
      await provider.listarPorEvento(widget.eventoId);
    }
  }

  Future<void> _enviarComentario() async {
    if (!_eventoJaAconteceu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentários só são permitidos após o evento ser realizado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final texto = _textoController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    final provider = Provider.of<ComentariosProvider>(context, listen: false);

    final ok = await provider.criar(
      eventoId: widget.eventoId,
      musicaId: widget.musica?.id,
      texto: texto,
    );

    setState(() => _enviando = false);

    if (ok) {
      _textoController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      // ← usa a mensagem real do backend em vez de texto fixo
      final mensagem = _provider.erroUltimaAcao ?? 'Erro ao enviar comentário';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarOpcoes(ComentarioPerformance comentario) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.teal),
              title: const Text('Editar comentário'),
              onTap: () {
                Navigator.pop(context);
                _mostrarEdicao(comentario);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir comentário'),
              onTap: () {
                Navigator.pop(context);
                _confirmarExclusao(comentario);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarEdicao(ComentarioPerformance comentario) {
    final controller = TextEditingController(text: comentario.texto);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar comentário'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edite seu comentário...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoTexto = controller.text.trim();
              if (novoTexto.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await _provider.editar(comentario.id, novoTexto);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao editar comentário'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(ComentarioPerformance comentario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text('Tem certeza que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _provider.deletar(comentario.id);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir comentário'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatarTempo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final musicoId = auth.userData?['musico_id'];
    final bloqueado = !_eventoJaAconteceu;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.musica != null ? 'Comentários — ${widget.musica!.titulo}' : 'Comentários',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.eventoNome,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner de aviso quando evento ainda não aconteceu ──
          if (bloqueado)
            Container(
              width: double.infinity,
              color: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comentários disponíveis após a realização do evento.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ── Lista de comentários ──
          Expanded(
            child: Consumer<ComentariosProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.erro != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Erro ao carregar comentários',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.comentarios.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum comentário ainda.\nSeja o primeiro a comentar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: provider.comentarios.length,
                    itemBuilder: (context, index) {
                      final c = provider.comentarios[index];
                      final ehMeu = c.autor == musicoId;

                      return _ComentarioCard(
                        comentario: c,
                        ehMeu: ehMeu,
                        tempoFormatado: _formatarTempo(c.criadoEm),
                        onReagir: () => provider.reagir(c.id),
                        onOpcoes: c.podeEditar ? () => _mostrarOpcoes(c) : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // ── Campo de novo comentário ──
          const Divider(height: 1),
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            color: Theme.of(context).cardColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textoController,
                    enabled: !bloqueado, // ← desabilita campo se evento não aconteceu
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: bloqueado
                          ? 'Disponível após o evento'
                          : widget.musica != null
                              ? 'Comentar sobre ${widget.musica!.titulo}...'
                              : 'Comentar sobre o evento...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _enviando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded),
                        // ← cinza e desabilitado se evento não aconteceu
                        color: bloqueado ? Colors.grey : Colors.teal,
                        iconSize: 28,
                        onPressed: bloqueado ? null : _enviarComentario,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16)
        ],
      ),
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _provider.limpar();
    });
    _textoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Widget do card de comentário ──
class _ComentarioCard extends StatelessWidget {
  final ComentarioPerformance comentario;
  final bool ehMeu;
  final String tempoFormatado;
  final VoidCallback onReagir;
  final VoidCallback? onOpcoes;

  const _ComentarioCard({
    required this.comentario,
    required this.ehMeu,
    required this.tempoFormatado,
    required this.onReagir,
    this.onOpcoes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ehMeu ? Colors.teal : Colors.orangeAccent,
                  child: Text(
                    comentario.autorNome.isNotEmpty ? comentario.autorNome[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comentario.autorNome,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          if (ehMeu) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'você',
                                style: TextStyle(fontSize: 10, color: Colors.teal),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        tempoFormatado + (comentario.editadoEm != null ? ' · editado' : ''),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                if (onOpcoes != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    color: Colors.grey,
                    onPressed: onOpcoes,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            // ── Texto ──
            const SizedBox(height: 8),
            Text(
              comentario.texto,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            // ── Rodapé: curtida ──
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: onReagir,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          comentario.euCurto ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: comentario.euCurto ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comentario.totalReacoes}',
                          style: TextStyle(
                            fontSize: 13,
                            color: comentario.euCurto ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
