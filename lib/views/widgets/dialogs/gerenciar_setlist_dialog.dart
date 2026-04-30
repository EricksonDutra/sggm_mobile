import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/eventos.dart';

class GerenciarSetlistDialog {
  static Future<void> show(BuildContext context, Evento evento) {
    return showDialog(
      context: context,
      builder: (_) => _GerenciarSetlistDialogContent(evento: evento),
    );
  }
}

class _GerenciarSetlistDialogContent extends StatefulWidget {
  const _GerenciarSetlistDialogContent({required this.evento});
  final Evento evento;

  @override
  State<_GerenciarSetlistDialogContent> createState() => _GerenciarSetlistDialogContentState();
}

class _GerenciarSetlistDialogContentState extends State<_GerenciarSetlistDialogContent> {
  late Set<int> _selecionadas;
  final _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _selecionadas = {
      ...?widget.evento.repertorio?.where((m) => m.id != null).map((m) => m.id!),
    };
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    try {
      await Provider.of<EventoProvider>(context, listen: false)
          .atualizarRepertorio(widget.evento.id!, _selecionadas.toList());
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setlist salvo com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerenciar Setlist'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<MusicasProvider>(
          builder: (context, provider, _) {
            if (provider.musicas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma música cadastrada no repertório geral.'),
              );
            }

            final musicasFiltradas = _termoBusca.isEmpty
                ? provider.musicas
                : provider.musicas
                    .where((m) =>
                        m.titulo.toLowerCase().contains(_termoBusca.toLowerCase()) ||
                        m.artistaNome.toLowerCase().contains(_termoBusca.toLowerCase()))
                    .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Busca
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _buscaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar música ou artista...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _buscaController.clear();
                                setState(() => _termoBusca = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _termoBusca = v),
                  ),
                ),

                // Contador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${_selecionadas.length} selecionada${_selecionadas.length != 1 ? "s" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      if (_termoBusca.isNotEmpty) ...[
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

                // Lista
                Flexible(
                  child: musicasFiltradas.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma música encontrada para "$_termoBusca"',
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
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              value: id != null && _selecionadas.contains(id),
                              activeColor: Colors.teal,
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
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              onChanged: (value) {
                                if (id == null) return;
                                setState(() => value == true ? _selecionadas.add(id) : _selecionadas.remove(id));
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
