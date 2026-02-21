import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/views/eventos_page.dart';
import 'package:sggm/views/musicos_page.dart';
import 'package:sggm/views/escalas_page.dart';
import 'package:sggm/views/musicas_page.dart';
import 'package:sggm/views/login_page.dart';
import 'package:sggm/views/perfil_edit_page.dart';
import 'package:sggm/views/mudar_senha_page.dart';
import 'package:sggm/views/widgets/loading/loading_overlay.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _abrirMeuPerfil(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
    final musicoId = auth.userData?['musico_id'];

    if (musicoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID do músico não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    LoadingOverlay.show(context, message: 'Carregando perfil...');

    try {
      await musicosProvider.listarMusicos();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    LoadingOverlay.hide(context);

    try {
      final musico = musicosProvider.musicos.firstWhere((m) => m.id == musicoId);

      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilEditPage(
            musico: musico,
            isOwnProfile: true,
          ),
        ),
      );

      if (resultado == true) {
        await musicosProvider.listarMusicos();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Músico não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SGGM',
          style: TextStyle(
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            tooltip: 'Opções',
            offset: const Offset(0, 50),
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white24),
            ),
            onSelected: (value) {
              if (value == 'perfil') {
                _abrirMeuPerfil(context);
              } else if (value == 'senha') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MudarSenhaPage()),
                );
              } else if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('Meu Perfil', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'senha',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('Mudar Senha', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/wave.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      final nome = auth.userData?['nome'] ?? 'Usuário';
                      final tipoUsuario = auth.userData?['tipo_usuario'] ?? '';

                      String badge = '';
                      if (tipoUsuario == 'ADMIN') {
                        badge = 'Admin';
                      } else if (tipoUsuario == 'LIDER') {
                        badge = 'Líder';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Olá, $nome',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (badge.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tipoUsuario == 'ADMIN' ? Colors.amber.shade900 : Colors.deepPurple.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Text(
                            'IPB Ponta Porã',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
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
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
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
              Icon(icon, size: 40, color: Colors.white),
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
