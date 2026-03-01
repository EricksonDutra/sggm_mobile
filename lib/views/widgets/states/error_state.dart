import 'package:flutter/material.dart';
import '../buttons/app_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Tentar Novamente',
                icon: Icons.refresh,
                onPressed: onRetry,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
