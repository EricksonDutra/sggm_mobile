import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/services/biometric_service.dart';

class BiometricTestPage extends StatefulWidget {
  const BiometricTestPage({super.key});

  @override
  State<BiometricTestPage> createState() => _BiometricTestPageState();
}

class _BiometricTestPageState extends State<BiometricTestPage> {
  final _biometricService = BiometricService();

  bool? _canCheck;
  bool? _isSupported;
  List<String>? _biometrics;
  String? _description;
  bool? _isEnabled;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    final biometrics = await _biometricService.getAvailableBiometrics();
    final description = await auth.getBiometricDescription();
    final isEnabled = await auth.isBiometricEnabled();

    setState(() {
      _canCheck = canCheck;
      _isSupported = isSupported;
      _biometrics = biometrics.map((e) => e.toString()).toList();
      _description = description;
      _isEnabled = isEnabled;
    });
  }

  Future<void> _testAuthentication() async {
    final result = await _biometricService.authenticate(
      reason: 'Teste de autenticação biométrica',
    );

    setState(() {
      _testResult = result;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? '✅ Autenticação bem-sucedida!' : '❌ Autenticação falhou'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Biometria'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status do Dispositivo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Pode verificar biometria', _canCheck),
                  _buildInfoRow('Dispositivo suportado', _isSupported),
                  _buildInfoRow('Biometria habilitada no app', _isEnabled),
                  const SizedBox(height: 8),
                  Text('Descrição: $_description'),
                  const SizedBox(height: 8),
                  const Text('Biometrias disponíveis:'),
                  ...?_biometrics?.map((b) => Text('  • $b')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Resultado do Teste',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  if (_testResult != null)
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.cancel,
                      color: _testResult! ? Colors.green : Colors.red,
                      size: 64,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _testAuthentication,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Testar Autenticação'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, bool? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            value == true ? Icons.check_circle : Icons.cancel,
            color: value == true ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }
}
