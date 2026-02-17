import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';

class BiometricSetupDialog extends StatelessWidget {
  final String biometricType;

  const BiometricSetupDialog({
    super.key,
    required this.biometricType,
  });

  static Future<bool?> show(BuildContext context, String biometricType) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BiometricSetupDialog(biometricType: biometricType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.fingerprint,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Login Rápido',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deseja usar $biometricType para fazer login mais rápido?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Suas credenciais continuam seguras e criptografadas',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Agora Não'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final auth = Provider.of<AuthProvider>(context, listen: false);

            try {
              await auth.enableBiometricLogin();
              if (context.mounted) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text('$biometricType habilitado com sucesso!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao habilitar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.fingerprint),
          label: const Text('Habilitar'),
        ),
      ],
    );
  }
}
