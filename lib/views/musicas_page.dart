import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/models/musicas.dart';
import 'package:sggm/views/musica_detalhes_page.dart';
import 'package:sggm/views/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:sggm/views/widgets/dialogs/musica_form_dialog.dart';
import 'package:sggm/views/widgets/loading/shimmer_list_tile.dart';
import 'package:sggm/views/widgets/musicas/musica_list_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicasPage extends StatefulWidget {
  const MusicasPage({super.key});

  @override
  State<MusicasPage> createState() => _MusicasPageState();
}

class _MusicasPageState extends State<MusicasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarMusicas());
  }

  Future<void> _carregarMusicas() async {
    try {
      await Provider.of<MusicasProvider>(context, listen: false).listarMusicas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar músicas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _abrirCifra(String? link) async {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum link de cifra cadastrado')),
      );
      return;
    }
    try {
      final uri = Uri.parse(link);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link inválido')),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(Musica musica) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      entityName: musica.titulo,
      message: 'Deseja realmente excluir "${musica.titulo}" de ${musica.artistaNome}?\n'
          'Esta ação não pode ser desfeita.',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await Provider.of<MusicasProvider>(context, listen: false).deletarMusica(musica.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música excluída com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir música'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLider = Provider.of<AuthProvider>(context, listen: false).userData?['is_lider'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertório'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMusicas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      floatingActionButton: isLider
          ? FloatingActionButton(
              onPressed: () => MusicaFormDialog.show(context),
              tooltip: 'Adicionar Música',
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<MusicasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 5,
              itemBuilder: (_, __) => const ShimmerListTile(showAvatar: true, showTrailing: true),
            );
          }

          if (provider.musicas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Nenhuma música cadastrada', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    isLider ? 'Toque no + para adicionar' : 'Aguarde o líder adicionar músicas',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _carregarMusicas,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.musicas.length,
              itemBuilder: (context, index) {
                final musica = provider.musicas[index];
                return MusicaListTile(
                  musica: musica,
                  isLider: isLider,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MusicaDetalhesPage(musica: musica)),
                  ),
                  onEditar: () => MusicaFormDialog.show(context, musicaInicial: musica),
                  onExcluir: () => _confirmarExclusao(musica),
                  onAbrirCifra: () => _abrirCifra(musica.linkCifra),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
