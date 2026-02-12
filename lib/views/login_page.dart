import 'package:flutter/material.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/views/initial_page.dart';
import 'package:sggm/views/widgets/input_widget.dart';
import 'package:provider/provider.dart';
import 'package:sggm/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _fazerLogin() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    bool sucesso = await auth.login(_userController.text, _passController.text);

    setState(() => _isLoading = false);

    if (sucesso) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login ou senha inválidos'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Column(children: [
              Text('SGGM', style: TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'Inknut_Antiqua')),
              SizedBox(height: 10),
              Text('IPB Ponta Porã',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14, fontFamily: 'Inknut_Antiqua', fontWeight: FontWeight.normal)),
            ]),
            Image.asset('assets/wave.jpg'),
            Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                child: buildTextField(controller: _userController, labelText: 'Usuário'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                child: buildTextField(
                  controller: _passController,
                  labelText: 'Senha',
                  obscureText: true,
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _fazerLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENTRAR',
                        style: TextStyle(color: Colors.white, fontFamily: 'Inknut_Antiqua'),
                      ),
              )
            ]),
          ],
        ),
      ),
    );
  }
}
