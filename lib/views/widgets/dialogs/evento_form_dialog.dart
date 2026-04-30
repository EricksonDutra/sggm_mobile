// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/util/date_formatter.dart';

class EventoFormDialog {
  static Future<void> showAdicionar(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const _EventoFormDialogContent(evento: null),
    );
  }

  static Future<void> showEditar(BuildContext context, Evento evento) {
    return showDialog(
      context: context,
      builder: (_) => _EventoFormDialogContent(evento: evento),
    );
  }
}

class _EventoFormDialogContent extends StatefulWidget {
  const _EventoFormDialogContent({required this.evento});
  final Evento? evento;

  @override
  State<_EventoFormDialogContent> createState() => _EventoFormDialogContentState();
}

class _EventoFormDialogContentState extends State<_EventoFormDialogContent> {
  late final TextEditingController _nomeController;
  late final TextEditingController _localController;
  late DateTime _dataSelecionada;
  late TimeOfDay _horarioSelecionado;
  DateTime? _dataHoraEnsaio;

  bool get _modoEdicao => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final evento = widget.evento;
    final dataAtual = evento != null ? DateTime.parse(evento.dataEvento) : DateTime.now();

    _nomeController = TextEditingController(text: evento?.nome ?? 'Culto');
    _localController = TextEditingController(text: evento?.local ?? 'IPB Ponta Porã');
    _dataSelecionada = dataAtual;
    _horarioSelecionado = TimeOfDay(hour: dataAtual.hour, minute: dataAtual.minute);
    _dataHoraEnsaio = evento?.dataHoraEnsaio;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data do evento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _selecionarHorario() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) setState(() => _horarioSelecionado = picked);
  }

  Future<void> _selecionarEnsaio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraEnsaio ?? _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Data do ensaio',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (data == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _dataHoraEnsaio != null ? TimeOfDay.fromDateTime(_dataHoraEnsaio!) : TimeOfDay.now(),
    );
    if (hora == null) return;

    setState(() {
      _dataHoraEnsaio = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty || _localController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    final dataComHorario = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      _horarioSelecionado.hour,
      _horarioSelecionado.minute,
    );

    final provider = Provider.of<EventoProvider>(context, listen: false);

    if (_modoEdicao) {
      final eventoAtualizado = Evento(
        id: widget.evento!.id,
        nome: _nomeController.text,
        local: _localController.text,
        dataEvento: dataComHorario.toIso8601String(),
        descricao: widget.evento!.descricao,
        dataHoraEnsaio: _dataHoraEnsaio,
      );

      final sucesso = await provider.atualizarEvento(widget.evento!.id!, eventoAtualizado);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sucesso ? 'Evento atualizado com sucesso!' : provider.errorMessage ?? 'Erro ao atualizar'),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ));
    } else {
      final novoEvento = Evento(
        nome: _nomeController.text,
        local: _localController.text,
        dataEvento: dataComHorario.toIso8601String(),
        descricao: 'Criado via App',
        dataHoraEnsaio: _dataHoraEnsaio,
      );

      final sucesso = await provider.adicionarEvento(novoEvento);
      if (!context.mounted) return;
      if (sucesso) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao criar evento'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_modoEdicao ? 'Editar Evento' : 'Novo Evento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _localController,
              decoration: const InputDecoration(labelText: 'Local', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Data do evento
            InkWell(
              onTap: _selecionarData,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data do Evento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormatter.data(_dataSelecionada), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),

            // Horário
            InkWell(
              onTap: _selecionarHorario,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Horário',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:'
                  '${_horarioSelecionado.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ensaio
            InkWell(
              onTap: _selecionarEnsaio,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data e hora do ensaio (opcional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.event_available),
                  suffix: _dataHoraEnsaio != null
                      ? GestureDetector(
                          onTap: () => setState(() => _dataHoraEnsaio = null),
                          child: const Icon(Icons.close, size: 18),
                        )
                      : null,
                ),
                child: Text(
                  _dataHoraEnsaio != null
                      ? DateFormatter.dataHora(_dataHoraEnsaio!)
                      : 'Toque para selecionar (opcional)',
                  style: TextStyle(
                    color: _dataHoraEnsaio != null ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
