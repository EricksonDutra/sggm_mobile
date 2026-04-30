import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/escalas.dart';

class AdicionarEscalaDialog extends StatefulWidget {
  const AdicionarEscalaDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AdicionarEscalaDialog._(),
    );
  }

  @override
  State<AdicionarEscalaDialog> createState() => _AdicionarEscalaDialogState();
}

class _AdicionarEscalaDialogState extends State<AdicionarEscalaDialog> {
  final _obsController = TextEditingController();

  int? _musicoId;
  String? _musicoNome;
  int? _eventoId;
  String? _eventoNome;
  final List<int> _instrumentosIds = [];

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  DateTime? _parseData(String raw) {
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _eventoEhPassado(DateTime dt) {
    final temHorario = dt.hour != 0 || dt.minute != 0;
    final corte = temHorario ? dt.add(const Duration(hours: 3)) : DateTime(dt.year, dt.month, dt.day + 1, 3, 0);
    return DateTime.now().isAfter(corte);
  }

  void _onMusicoChanged(int? valor, MusicosProvider musicosProvider) {
    if (valor == null) return;
    final musico = musicosProvider.musicos.firstWhere((m) => m.id == valor);
    _musicoId = valor;
    _musicoNome = musico.nome;

    final instProvider = Provider.of<InstrumentosProvider>(context, listen: false);
    final principal = musico.instrumentoPrincipal?.toString();
    if (principal != null && principal.isNotEmpty) {
      final match = instProvider.instrumentos.where((i) => i.nome == principal).firstOrNull;
      if (match?.id != null && !_instrumentosIds.contains(match!.id)) {
        _instrumentosIds.add(match.id);
      }
    }
  }

  void _submeter() {
    if (_musicoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um músico!')),
      );
      return;
    }
    if (_eventoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um evento!')),
      );
      return;
    }
    if (_instrumentosIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um instrumento!')),
      );
      return;
    }

    final novaEscala = Escala(
      musicoId: _musicoId!,
      eventoId: _eventoId!,
      musicoNome: _musicoNome,
      eventoNome: _eventoNome,
      instrumentos: List<int>.from(_instrumentosIds),
      observacao: _obsController.text.trim().isNotEmpty ? _obsController.text.trim() : null,
    );

    Provider.of<EscalasProvider>(context, listen: false).adicionarRascunho(novaEscala);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✏️ Adicionado ao rascunho. Publique a escala para notificar.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova Escala (rascunho)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Músico
              Consumer<MusicosProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Músico *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    value: _musicoId,
                    items: provider.musicos
                        .map((m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.nome, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (valor) => setState(() => _onMusicoChanged(valor, provider)),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Evento
              Consumer<EventoProvider>(
                builder: (context, provider, _) {
                  final eventosFuturos = provider.eventos.where((e) {
                    final dt = _parseData(e.dataEvento);
                    return dt != null && !_eventoEhPassado(dt);
                  }).toList()
                    ..sort((a, b) {
                      final da = _parseData(a.dataEvento);
                      final db = _parseData(b.dataEvento);
                      if (da == null) return 1;
                      if (db == null) return -1;
                      return da.compareTo(db);
                    });

                  if (_eventoId == null && eventosFuturos.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _eventoId = eventosFuturos.first.id;
                        _eventoNome = eventosFuturos.first.nome;
                      });
                    });
                  }

                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Evento *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    value: _eventoId,
                    items: eventosFuturos
                        .map((e) => DropdownMenuItem<int>(
                              value: e.id,
                              child: Text(
                                '${e.nome} (${e.dataEvento.split('T')[0].split('-').reversed.join('/')})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (valor) => setState(() {
                      _eventoId = valor;
                      if (valor != null) {
                        _eventoNome = provider.eventos.firstWhere((e) => e.id == valor).nome;
                      }
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Instrumentos
              const Text('Instrumentos *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Consumer<InstrumentosProvider>(
                builder: (context, provider, _) {
                  if (provider.instrumentos.isEmpty) {
                    return const Text('Nenhum instrumento cadastrado', style: TextStyle(color: Colors.grey));
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: provider.instrumentos.map((inst) {
                      return FilterChip(
                        label: Text(inst.nome),
                        selected: _instrumentosIds.contains(inst.id),
                        onSelected: (v) => setState(() {
                          v ? _instrumentosIds.add(inst.id) : _instrumentosIds.remove(inst.id);
                        }),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Observação
              TextField(
                controller: _obsController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submeter,
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
