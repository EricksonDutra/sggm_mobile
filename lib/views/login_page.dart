import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false; // ✅ Adicione
  bool _biometricEnabled = false; // ✅ Adicione
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _checkBiometric(); // ✅ Adicione
  }

  Future<void> _checkBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final available = await auth.canUseBiometric();
    final enabled = await auth.isBiometricEnabled();
    final type = await auth.getBiometricDescription();

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _biometricType = type;
    });

    print('🔐 Biometria disponível: $available');
    print('🔐 Biometria habilitada: $enabled');
    print('🔐 Tipo: $type');

    // ✅ Auto-login com biometria se habilitado
    if (available && enabled) {
      await _loginWithBiometric();
    }
  }

  // ✅ ADICIONE ESTE MÉTODO
  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.loginWithBiometric();

      if (mounted && success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticação biométrica cancelada'),
            backgroundColor: Colors.orange,
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

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha usuário e senha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final loginSuccess = await auth.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted && loginSuccess) {
        // ✅ Verificar se deve oferecer biometria
        final biometricAvailable = await auth.canUseBiometric();
        final biometricEnabled = await auth.isBiometricEnabled();

        print('🔐 Biometria disponível: $biometricAvailable');
        print('🔐 Biometria habilitada: $biometricEnabled');

        // Se biometria disponível e ainda não está habilitada
        if (biometricAvailable && !biometricEnabled) {
          final biometricType = await auth.getBiometricDescription();

          print('🔐 Mostrando dialog para habilitar $_biometricType');

          // Mostrar dialog após pequeno delay para melhor UX
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            final shouldEnable = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
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
                      try {
                        await auth.enableBiometricLogin();
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
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
              ),
            );

            if (shouldEnable == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
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
          }
        }

        // Navegar para home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário ou senha incorretos'),
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

  // ✅ Imagem melhorada com ajustes visuais
  Widget _buildWaveImage() {
    return Container(
      width: double.infinity,
      height: 140, // ✅ Altura aumentada
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // ✅ Mais arredondado
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3), // ✅ Sombra verde
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          // ✅ Borda verde sutil
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black87, // ✅ Fundo escuro para contraste
            child: Image.asset(
              'assets/wave.jpg',
              fit: BoxFit.contain, // ✅ Mantém proporção sem cortar
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black45,
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      size: 60,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF1E1E1E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // ✅ Padding ajustado
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20), // ✅ Espaço inicial

                  // Logo/Título
                  const Text(
                    'SGGM',
                    style: TextStyle(
                      fontFamily: 'Inknut_Antiqua',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Linha verde
                  Container(
                    width: 100,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo
                  const Text(
                    'IPB Ponta Porã',
                    style: TextStyle(
                      fontFamily: 'Inknut_Antiqua',
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32), // ✅ Espaço reduzido

                  // ✅ Imagem melhorada
                  _buildWaveImage(),
                  const SizedBox(height: 32), // ✅ Espaço reduzido

                  // Campo Usuário
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(
                      fontFamily: 'Inknut_Antiqua',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Usuário',
                      labelStyle: const TextStyle(
                        fontFamily: 'Inknut_Antiqua',
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontFamily: 'Inknut_Antiqua',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      labelStyle: const TextStyle(
                        fontFamily: 'Inknut_Antiqua',
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24), // ✅ Espaço reduzido

                  // ✅ Botão Entrar (corrigido)
                  SizedBox(
                    width: double.infinity,
                    height: 52, // ✅ Altura fixa adequada
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // ✅ Mais arredondado
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontFamily: 'Inknut_Antiqua',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),

                  // ✅ ADICIONE ESTE BOTÃO DE BIOMETRIA
                  if (_biometricAvailable && _biometricEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'ou',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithBiometric,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.fingerprint,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                        label: Text(
                          'USAR ${_biometricType.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'Inknut_Antiqua',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16), // ✅ Espaço reduzido

                  // Texto informativo
                  Text(
                    'Use suas credenciais da IPB Ponta Porã',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inknut_Antiqua',
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
