import 'package:flutter/material.dart';
import 'package:sggm/services/api_service.dart';

class MudarSenhaPage extends StatefulWidget {
  const MudarSenhaPage({super.key});

  @override
  State<MudarSenhaPage> createState() => _MudarSenhaPageState();
}

class _MudarSenhaPageState extends State<MudarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _senhaNova1Controller = TextEditingController();
  final _senhaNova2Controller = TextEditingController();

  bool _isLoading = false;
  bool _mostrarSenhaAtual = false;
  bool _mostrarSenhaNova1 = false;
  bool _mostrarSenhaNova2 = false;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _senhaNova1Controller.dispose();
    _senhaNova2Controller.dispose();
    super.dispose();
  }

  /// Validar e mudar senha
  Future<void> _mudarSenha() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        '/api/musicos/mudar_senha/',
        body: {
          'senha_atual': _senhaAtualController.text,
          'senha_nova': _senhaNova1Controller.text,
          'confirmar_senha': _senhaNova2Controller.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Sucesso!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Aguardar um pouco e voltar
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Erro do servidor
        final erro = response.data['error'] ?? 'Erro ao alterar senha';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mudar Senha'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== ÍCONE E DESCRIÇÃO ==========
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Alterar Senha',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Digite sua senha atual e escolha uma nova senha segura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ========== SENHA ATUAL ==========
              TextFormField(
                controller: _senhaAtualController,
                obscureText: !_mostrarSenhaAtual,
                decoration: InputDecoration(
                  labelText: 'Senha Atual *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarSenhaAtual ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _mostrarSenhaAtual = !_mostrarSenhaAtual);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite sua senha atual';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // ========== NOVA SENHA ==========
              TextFormField(
                controller: _senhaNova1Controller,
                obscureText: !_mostrarSenhaNova1,
                decoration: InputDecoration(
                  labelText: 'Nova Senha *',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarSenhaNova1 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _mostrarSenhaNova1 = !_mostrarSenhaNova1);
                    },
                  ),
                  border: const OutlineInputBorder(),
                  helperText: 'Mínimo de 8 caracteres',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a nova senha';
                  }
                  if (value.length < 8) {
                    return 'A senha deve ter no mínimo 8 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ========== CONFIRMAR NOVA SENHA ==========
              TextFormField(
                controller: _senhaNova2Controller,
                obscureText: !_mostrarSenhaNova2,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nova Senha *',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarSenhaNova2 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _mostrarSenhaNova2 = !_mostrarSenhaNova2);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a nova senha';
                  }
                  if (value != _senhaNova1Controller.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ========== DICAS DE SEGURANÇA ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dicas para uma senha segura',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDica('Use pelo menos 8 caracteres'),
                    _buildDica('Combine letras, números e símbolos'),
                    _buildDica('Evite senhas óbvias ou sequenciais'),
                    _buildDica('Não use informações pessoais'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ========== BOTÃO SALVAR ==========
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _mudarSenha,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Salvando...' : 'Alterar Senha',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDica(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
