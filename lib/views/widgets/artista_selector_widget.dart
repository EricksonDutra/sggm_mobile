import 'package:flutter/material.dart';
import 'package:sggm/models/artista.dart';
import 'package:sggm/services/artista_service.dart';

class ArtistaSelectorWidget extends StatefulWidget {
  final Function(Artista) onArtistaSelected;
  final Artista? artistaInicial;

  const ArtistaSelectorWidget({
    super.key,
    required this.onArtistaSelected,
    this.artistaInicial,
  });

  @override
  _ArtistaSelectorWidgetState createState() => _ArtistaSelectorWidgetState();
}

class _ArtistaSelectorWidgetState extends State<ArtistaSelectorWidget> {
  final ArtistaService _artistaService = ArtistaService(); // ✅ CORRIGIDO: Sem parâmetros
  List<Artista> _artistas = [];
  Artista? _artistaSelecionado;
  bool _carregando = false;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _artistaSelecionado = widget.artistaInicial;
    _carregarArtistas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarArtistas({String? busca}) async {
    if (!mounted) return;

    setState(() => _carregando = true);
    try {
      final artistas = await _artistaService.listarArtistas(busca: busca);
      if (mounted) {
        setState(() => _artistas = artistas);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar artistas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _adicionarNovoArtista() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => _DialogNovoArtista(),
    );

    if (nome != null && nome.isNotEmpty) {
      try {
        final novoArtista = await _artistaService.criarArtista(nome);
        if (mounted) {
          setState(() {
            _artistas.insert(0, novoArtista);
            _artistaSelecionado = novoArtista;
          });
          widget.onArtistaSelected(novoArtista);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artista "${novoArtista.nome}" adicionado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao adicionar artista: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _buscaController,
          decoration: InputDecoration(
            labelText: 'Buscar Artista/Banda',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _adicionarNovoArtista,
              tooltip: 'Adicionar novo artista',
              color: Theme.of(context).primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _carregarArtistas(busca: value);
          },
        ),
        const SizedBox(height: 16),
        if (_carregando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_artistas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.music_note_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nenhum artista encontrado',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _adicionarNovoArtista,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar novo artista'),
                  ),
                ],
              ),
            ),
          )
        else
          DropdownButtonFormField<Artista>(
            initialValue: _artistaSelecionado,
            decoration: InputDecoration(
              labelText: 'Selecione o Artista',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            items: _artistas.map((artista) {
              return DropdownMenuItem(
                value: artista,
                child: Text(artista.nome),
              );
            }).toList(),
            onChanged: (artista) {
              setState(() => _artistaSelecionado = artista);
              if (artista != null) {
                widget.onArtistaSelected(artista);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Selecione um artista';
              }
              return null;
            },
          ),
      ],
    );
  }
}

class _DialogNovoArtista extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  _DialogNovoArtista();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.library_music, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Novo Artista/Banda'),
        ],
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Nome do Artista/Banda',
          hintText: 'Ex: Isaías Saad',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.person_add),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.pop(context, value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context, text);
            }
          },
          icon: const Icon(Icons.check),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }
}
