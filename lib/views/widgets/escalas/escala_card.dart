// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/models/escalas.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';

class EscalaCard extends StatelessWidget {
  const EscalaCard({
    super.key,
    required this.escala,
    required this.isLider,
    required this.currentUserId,
  });

  final Escala escala;
  final bool isLider;
  final int? currentUserId;

  bool get _isMinhaEscala => currentUserId != null && escala.musicoId == currentUserId;
  bool get _isRascunho => (escala.id ?? 0) < 0;

  IconData get _statusIcon => _isRascunho
      ? Icons.edit_note
      : escala.confirmado
          ? Icons.check_circle
          : Icons.pending;

  Color get _statusColor => _isRascunho
      ? Colors.blue
      : escala.confirmado
          ? Colors.green
          : Colors.orange;

  Future<void> _confirmarPresenca(BuildContext context, bool confirmado) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await context.read<EscalasProvider>().confirmarPresenca(escala.id!, confirmado);
      if (ok) {
        messenger.showSnackBar(SnackBar(
          content: Text(confirmado ? 'Presença confirmada!' : 'Presença desmarcada'),
          backgroundColor: confirmado ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ));
      } else {
        final erro = context.read<EscalasProvider>().errorMessage ?? 'Erro ao confirmar presença';
        messenger.showSnackBar(SnackBar(content: Text(erro), backgroundColor: Colors.red));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Erro ao confirmar presença'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _confirmarDelecao(BuildContext context) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      entityName: escala.musicoNome ?? 'este músico',
      message: 'Deseja remover ${escala.musicoNome ?? "este músico"} da escala?\nEsta ação não pode ser desfeita.',
    );
    if (confirmed && context.mounted && escala.id != null) {
      try {
        await context.read<EscalasProvider>().deletarEscala(escala.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Escala removida com sucesso'), backgroundColor: Colors.green),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao remover escala'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(_statusIcon, color: _statusColor, size: 30),
            title: Text(escala.musicoNome ?? 'Músico #${escala.musicoId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (escala.instrumentoNome != null && escala.instrumentoNome!.isNotEmpty)
                  Text('🎵 ${escala.instrumentoNome}')
                else if (escala.instrumentos != null && escala.instrumentos!.isNotEmpty)
                  Text('🎵 ${escala.instrumentos!.length} instrumento(s) selecionado(s)'),
                if (escala.observacao != null && escala.observacao!.isNotEmpty) Text('📝 ${escala.observacao}'),
                Text(
                  _isRascunho ? 'Rascunho (não publicado)' : (escala.confirmado ? 'Confirmado' : 'Pendente'),
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: isLider
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: _isRascunho ? 'Remover do rascunho' : 'Remover escala',
                    onPressed: () {
                      if (_isRascunho) {
                        context.read<EscalasProvider>().removerRascunho(escala.eventoId, escala.id!);
                      } else {
                        _confirmarDelecao(context);
                      }
                    },
                  )
                : null,
          ),
          if (!_isRascunho && (_isMinhaEscala || isLider))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarPresenca(context, !escala.confirmado),
                  icon: Icon(escala.confirmado ? Icons.cancel : Icons.check),
                  label: Text(escala.confirmado ? 'Desmarcar Presença' : 'Confirmar Presença'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: escala.confirmado ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
