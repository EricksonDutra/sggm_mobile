import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/views/eventos_page.dart';
import 'package:sggm/views/musicos_page.dart';
import 'package:sggm/views/escalas_page.dart';
import 'package:sggm/views/musicas_page.dart';
import 'package:sggm/views/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Tenta pegar o nome do usuário do token ou usa um padrão
    // (Dependendo de como você decodifica o token, aqui é um exemplo simples)
    const nomeUsuario = "Líder";

    return Scaffold(
      // Fundo preto sólido para combinar com o tema dark
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            const Text('SGGM', style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/wave.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. CONTEÚDO PRINCIPAL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Cabeçalho de Boas Vindas
                  const Text(
                    'Olá, $nomeUsuario',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'IPB Ponta Porã',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Grid de Menu
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1, // Ajusta a altura dos cartões
                      children: [
                        _buildDarkCard(
                          context,
                          title: 'EVENTOS',
                          icon: Icons.calendar_today_outlined,
                          page: const EventosPage(),
                        ),
                        _buildDarkCard(
                          context,
                          title: 'MÚSICOS',
                          icon: Icons.people_outline,
                          page: const MusicosPage(),
                        ),
                        _buildDarkCard(
                          context,
                          title: 'ESCALAS',
                          icon: Icons.assignment_outlined,
                          page: const EscalasPage(),
                        ),
                        _buildDarkCard(
                          context,
                          title: 'REPERTÓRIO',
                          icon: Icons.queue_music,
                          page: const MusicasPage(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget customizado para os Cartões Dark
  Widget _buildDarkCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Cinza bem escuro (Surface color)
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white24, // Borda fina e discreta igual ao login
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white), // Ícone branco
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
