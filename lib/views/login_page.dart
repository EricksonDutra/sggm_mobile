import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/home_page.dart';
import 'package:sggm/views/widgets/input_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _userController;
  late TextEditingController _passController;
  late FocusNode _userFocus;
  late FocusNode _passFocus;

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passController = TextEditingController();
    _userFocus = FocusNode();
    _passFocus = FocusNode();

    // 🎯 Auto-focus no campo de usuário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  /// Fazer login com validação
  Future<void> _fazerLogin() async {
    // ✅ Validar campos vazios
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _mostrarErro('Por favor, preencha todos os campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();

      // 🔐 Tentar login
      final sucesso = await auth.login(
        _userController.text.trim(),
        _passController.text,
      );

      if (!mounted) return;

      if (sucesso) {
        // ✅ Login bem-sucedido
        print('✅ Login realizado com sucesso!');
        print('👤 Usuário: ${auth.userData?['nome']}');
        print('👑 É líder: ${auth.isLider}');

        // 🏠 Navegar para home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // ❌ Login falhou
        _mostrarErro('Usuário ou senha inválidos');
        _passController.clear();
        _userFocus.requestFocus();
      }
    } catch (e) {
      print('❌ Erro ao fazer login: $e');
      _mostrarErro('Erro ao conectar ao servidor');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Exibir mensagem de erro
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        // ❌ Prevenir voltar durante login
        return !_isLoading;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // ========== HEADER ==========
                  _buildHeader(),

                  // ========== IMAGE ==========
                  _buildWaveImage(),

                  // ========== FORM ==========
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header com logo e título
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'SGGM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontFamily: 'Inknut_Antiqua',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'IPB Ponta Porã',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontFamily: 'Inknut_Antiqua',
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  /// Build wave image
  Widget _buildWaveImage() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/wave.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.deepPurple.shade900,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey.shade600,
                  size: 48,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build login form
  Widget _buildLoginForm() {
    return Column(
      children: [
        // ========== CAMPO DE USUÁRIO ==========
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: buildTextField(
            controller: _userController,
            labelText: 'Usuário',
            focusNode: _userFocus,
            onSubmitted: (_) => _passFocus.requestFocus(),
          ),
        ),

        // ========== CAMPO DE SENHA ==========
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: TextField(
            controller: _passController,
            focusNode: _passFocus,
            obscureText: !_showPassword,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _isLoading ? null : _fazerLogin(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              labelText: 'Senha',
              filled: true,
              fillColor: const Color(0xFF414141),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inknut_Antiqua',
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(
                  color: Colors.grey,
                ),
              ),
              // ✅ Botão para mostrar/esconder senha
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inknut_Antiqua',
            ),
            cursorColor: const Color.fromARGB(255, 6, 124, 41),
          ),
        ),

        const SizedBox(height: 20),

        // ========== BOTÃO DE LOGIN ==========
        _buildLoginButton(),

        const SizedBox(height: 16),

        // ========== INFORMAÇÕES ADICIONAIS ==========
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Use suas credenciais da IPB Ponta Porã',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Build login button
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _fazerLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade700,
        disabledBackgroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: _isLoading ? 0 : 4,
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            )
          : const Text(
              'ENTRAR',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inknut_Antiqua',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
