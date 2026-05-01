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
        const SnackBar(content: Text('ID do músico não encontrado'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Erro ao carregar perfil'), backgroundColor: Colors.red),
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
          builder: (context) => PerfilEditPage(musico: musico, isOwnProfile: true),
        ),
      );
      if (resultado == true) await musicosProvider.listarMusicos();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Músico não encontrado'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static const _menuItems = [
    _MenuItem(title: 'EVENTOS', icon: Icons.calendar_today_outlined),
    _MenuItem(title: 'MÚSICOS', icon: Icons.people_outline),
    _MenuItem(title: 'ESCALAS', icon: Icons.assignment_outlined),
    _MenuItem(title: 'REPERTÓRIO', icon: Icons.queue_music),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Layout responsivo:
    // < 600  → mobile  (2 colunas, cards compactos)
    // 600-1024 → tablet (3 colunas)
    // > 1024 → desktop (4 colunas, conteúdo centralizado com max-width)
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final contentMaxWidth = isDesktop ? 900.0 : double.infinity;
    final cardAspect = isDesktop ? 1.3 : (isTablet ? 1.2 : 1.1);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SGGM',
          style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MudarSenhaPage()));
              } else if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'perfil',
                child: Row(children: [
                  Icon(Icons.account_circle, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('Meu Perfil', style: TextStyle(color: Colors.white)),
                ]),
              ),
              const PopupMenuItem(
                value: 'senha',
                child: Row(children: [
                  Icon(Icons.lock_reset, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('Mudar Senha', style: TextStyle(color: Colors.white)),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Sair', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fundo com wave
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/wave.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40.0 : 20.0,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header com saudação
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final nome = auth.userData?['nome'] ?? 'Usuário';
                          final tipoUsuario = auth.userData?['tipo_usuario'] ?? '';
                          final badge = tipoUsuario == 'ADMIN'
                              ? 'Admin'
                              : tipoUsuario == 'LIDER'
                                  ? 'Líder'
                                  : '';

                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá, $nome',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 32 : 28,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                ),
                              ),
                              if (badge.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Grid responsivo
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: isDesktop ? 20 : 15,
                            mainAxisSpacing: isDesktop ? 20 : 15,
                            childAspectRatio: cardAspect,
                          ),
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            final page = _pageForIndex(index);
                            return _DarkCard(
                              title: item.title,
                              icon: item.icon,
                              page: page,
                              isDesktop: isDesktop,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return const EventosPage();
      case 1:
        return const MusicosPage();
      case 2:
        return const EscalasPage();
      case 3:
        return const MusicasPage();
      default:
        return const EventosPage();
    }
  }
}

// ─── Modelo auxiliar ─────────────────────────────────────────────────────────

class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem({required this.title, required this.icon});
}

// ─── Card escuro ─────────────────────────────────────────────────────────────

class _DarkCard extends StatefulWidget {
  const _DarkCard({
    required this.title,
    required this.icon,
    required this.page,
    required this.isDesktop,
  });

  final String title;
  final IconData icon;
  final Widget page;
  final bool isDesktop;

  @override
  State<_DarkCard> createState() => _DarkCardState();
}

class _DarkCardState extends State<_DarkCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? Colors.white38 : Colors.white24,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.3),
              blurRadius: _hovered ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.page),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    size: widget.isDesktop ? 48 : 40,
                    color: _hovered ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _hovered ? Colors.white : Colors.white70,
                    fontSize: widget.isDesktop ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
