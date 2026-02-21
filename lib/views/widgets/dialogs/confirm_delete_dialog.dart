import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String entityName;
  final String? message;

  const ConfirmDeleteDialog({
    super.key,
    required this.entityName,
    this.message,
  });

  static Future<bool> show(
    BuildContext context, {
    required String entityName,
    String? message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        entityName: entityName,
        message: message,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Confirmar exclusão'),
        ],
      ),
      content: Text(
        message ?? 'Tem certeza que deseja excluir "$entityName"?\nEsta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
