import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/musicos.dart';
import 'package:intl/intl.dart';

class PerfilEditPage extends StatefulWidget {
  final Musico musico;
  final bool isOwnProfile; // ✅ Se está editando próprio perfil

  const PerfilEditPage({
    super.key,
    required this.musico,
    required this.isOwnProfile,
  });

  @override
  State<PerfilEditPage> createState() => _PerfilEditPageState();
}

class _PerfilEditPageState extends State<PerfilEditPage> {
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _enderecoController;

  // ✅ Campos de afastamento
  late TextEditingController _motivoController;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  int? _instrumentoSelecionado;
  String? _statusSelecionado;
  bool _isLoading = false;
  bool _isLider = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores
    _nomeController = TextEditingController(text: widget.musico.nome);
    _telefoneController = TextEditingController(text: widget.musico.telefone);
    _enderecoController = TextEditingController(text: widget.musico.endereco ?? '');
    _motivoController = TextEditingController(text: widget.musico.motivoInatividade ?? '');

    _instrumentoSelecionado = widget.musico.instrumentoPrincipal;
    _statusSelecionado = widget.musico.status;
    _dataInicio = widget.musico.dataInicioInatividade;
    _dataFim = widget.musico.dataFimInatividade;

    // Verificar se é líder
    final auth = context.read<AuthProvider>();
    _isLider = auth.isLider;

    // Carregar instrumentos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos();
    });
  }

  // ✅ NOVO: Diálogo para cadastrar novo instrumento
  Future<dynamic> _mostrarDialogoCadastrarInstrumento() async {
    final nomeInstrumentoController = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.music_note, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Novo Instrumento'),
          ],
        ),
        content: TextField(
          controller: nomeInstrumentoController,
          decoration: const InputDecoration(
            labelText: 'Nome do Instrumento *',
            hintText: 'Ex: Guitarra, Bateria, Teclado...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeInstrumentoController.text.trim();

              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite o nome do instrumento'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Cadastrar instrumento
              final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

              try {
                final novoInstrumento = await instrumentosProvider.adicionarInstrumento({'nome': nome});

                if (novoInstrumento != null) {
                  if (ctx.mounted) Navigator.of(ctx).pop(novoInstrumento);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Instrumento "$nome" cadastrado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao cadastrar instrumento'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  /// ✅ Verificar se campo pode ser editado
  bool _podeEditarCampo(String campo) {
    // Líder pode editar tudo
    if (_isLider) return true;

    // Músico comum pode editar apenas campos permitidos
    const camposPermitidos = [
      'telefone',
      'endereco',
      'status', // Pode mudar apenas para AFASTADO
    ];

    return camposPermitidos.contains(campo);
  }

  /// Salvar alterações
  Future<void> _salvarAlteracoes() async {
    setState(() => _isLoading = true);

    try {
      // ✅ Montar dados conforme permissão
      final Map<String, dynamic> dadosAtualizados = {};

      // Campos que todos podem editar
      if (_podeEditarCampo('telefone')) {
        dadosAtualizados['telefone'] = _telefoneController.text;
      }
      if (_podeEditarCampo('endereco')) {
        dadosAtualizados['endereco'] = _enderecoController.text;
      }

      // ✅ Status e campos de afastamento
      if (_podeEditarCampo('status')) {
        dadosAtualizados['status'] = _statusSelecionado;

        if (_statusSelecionado == 'AFASTADO') {
          dadosAtualizados['data_inicio_inatividade'] = _dataInicio?.toIso8601String().split('T')[0];
          dadosAtualizados['data_fim_inatividade'] = _dataFim?.toIso8601String().split('T')[0];
          dadosAtualizados['motivo_inatividade'] = _motivoController.text;
        }
      }

      // ✅ Campos que apenas líder pode editar
      if (_isLider) {
        dadosAtualizados['nome'] = _nomeController.text;
        dadosAtualizados['instrumento_principal'] = _instrumentoSelecionado;
      }

      print('📤 Enviando dados: $dadosAtualizados');

      // Atualizar no backend
      final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
      final sucesso = await musicosProvider.atualizarMusico(
        widget.musico.id!,
        dadosAtualizados,
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true indicando sucesso
      } else {
        final erro = musicosProvider.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro ?? 'Erro ao atualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Selecionar data
  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isInicio ? (_dataInicio ?? DateTime.now()) : (_dataFim ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOwnProfile ? 'Meu Perfil' : 'Editar Músico'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _salvarAlteracoes,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== NOME ==========
                  TextField(
                    controller: _nomeController,
                    enabled: _podeEditarCampo('nome'),
                    decoration: InputDecoration(
                      labelText: 'Nome *',
                      border: const OutlineInputBorder(),
                      suffixIcon: !_podeEditarCampo('nome') ? const Icon(Icons.lock, size: 20) : null,
                    ),
                  ),
                  if (!_podeEditarCampo('nome'))
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        'Apenas líderes podem editar o nome',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ========== TELEFONE ==========
                  TextField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone *',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ========== ENDEREÇO ==========
                  TextField(
                    controller: _enderecoController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ========== INSTRUMENTO (só líder) ==========
                  Consumer<InstrumentosProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _instrumentoSelecionado, // ✅ CORRIGIDO: usar value ao invés de initialValue
                            decoration: InputDecoration(
                              labelText: 'Instrumento Principal',
                              border: const OutlineInputBorder(),
                              suffixIcon: !_podeEditarCampo('instrumento') ? const Icon(Icons.lock, size: 20) : null,
                            ),
                            items: [
                              ...provider.instrumentos.map((inst) {
                                return DropdownMenuItem<int>(
                                  value: inst.id,
                                  child: Text(inst.nome),
                                );
                              }),
                              // ✅ Opção para cadastrar novo instrumento (apenas se for líder)
                              if (_isLider)
                                const DropdownMenuItem<int>(
                                  value: -1,
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('➕ Cadastrar Novo Instrumento'),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: _podeEditarCampo('instrumento')
                                ? (value) async {
                                    if (value == -1) {
                                      // Mostrar diálogo para cadastrar novo instrumento
                                      final novoInstrumento = await _mostrarDialogoCadastrarInstrumento();

                                      if (novoInstrumento != null) {
                                        // Recarregar lista de instrumentos
                                        await provider.listarInstrumentos();

                                        // Selecionar o novo instrumento
                                        setState(() {
                                          _instrumentoSelecionado = novoInstrumento.id;
                                        });
                                      }
                                    } else {
                                      setState(() => _instrumentoSelecionado = value);
                                    }
                                  }
                                : null,
                          ),
                          // ✅ CORRIGIDO: Remover texto duplicado
                          if (!_podeEditarCampo('instrumento'))
                            const Padding(
                              padding: EdgeInsets.only(top: 4, left: 12),
                              child: Text(
                                'Apenas líderes podem alterar o instrumento',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ========== STATUS ==========
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: _statusSelecionado, // ✅ CORRIGIDO: usar value ao invés de initialValue
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'ATIVO', child: Text('Ativo')),
                      const DropdownMenuItem(value: 'AFASTADO', child: Text('Afastado Temporariamente')),
                      if (_isLider) // Apenas líder pode inativar definitivamente
                        const DropdownMenuItem(value: 'INATIVO', child: Text('Inativo')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusSelecionado = value;
                        // Limpar datas se não for afastado
                        if (value != 'AFASTADO') {
                          _dataInicio = null;
                          _dataFim = null;
                          _motivoController.clear();
                        }
                      });
                    },
                  ),

                  // ========== CAMPOS DE AFASTAMENTO ==========
                  if (_statusSelecionado == 'AFASTADO') ...[
                    const SizedBox(height: 16),

                    // Data início
                    ListTile(
                      title: const Text('Data Início'),
                      subtitle: Text(
                        _dataInicio != null ? DateFormat('dd/MM/yyyy').format(_dataInicio!) : 'Selecione uma data',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selecionarData(context, true),
                    ),

                    // Data fim
                    ListTile(
                      title: const Text('Data Fim'),
                      subtitle: Text(
                        _dataFim != null ? DateFormat('dd/MM/yyyy').format(_dataFim!) : 'Selecione uma data',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selecionarData(context, false),
                    ),

                    const SizedBox(height: 16),

                    // Motivo
                    TextField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo do Afastamento',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Viagem, problemas de saúde...',
                      ),
                      maxLines: 3,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ========== BOTÃO SALVAR ==========
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _salvarAlteracoes,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Alterações'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
