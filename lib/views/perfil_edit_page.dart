// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/musicos.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:sggm/services/biometric_service.dart';
import 'package:sggm/views/widgets/loading/loading_overlay.dart';

class PerfilEditPage extends StatefulWidget {
  final Musico musico;
  final bool isOwnProfile;

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
    _nomeController = TextEditingController(text: widget.musico.nome);
    _telefoneController = TextEditingController(text: widget.musico.telefone);
    _enderecoController = TextEditingController(text: widget.musico.endereco ?? '');
    _motivoController = TextEditingController(text: widget.musico.motivoInatividade ?? '');

    _instrumentoSelecionado = widget.musico.instrumentoPrincipal;
    _statusSelecionado = widget.musico.status;
    _dataInicio = widget.musico.dataInicioInatividade;
    _dataFim = widget.musico.dataFimInatividade;

    _isLider = context.read<AuthProvider>().isLider;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InstrumentosProvider>(context, listen: false).listarInstrumentos();
    });
  }

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

              final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

              try {
                final novoInstrumento = await instrumentosProvider.adicionarInstrumento({'nome': nome});

                if (ctx.mounted) Navigator.of(ctx).pop(novoInstrumento);

                if (context.mounted && novoInstrumento != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Instrumento "$nome" cadastrado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao cadastrar instrumento'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao cadastrar instrumento'),
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

  bool _podeEditarCampo(String campo) {
    if (_isLider) return true;
    const camposPermitidos = ['telefone', 'endereco', 'status'];
    return camposPermitidos.contains(campo);
  }

  Future<void> _salvarAlteracoes() async {
    setState(() => _isLoading = true);
    LoadingOverlay.show(context, message: 'Salvando...');

    try {
      final Map<String, dynamic> dadosAtualizados = {};

      if (_podeEditarCampo('telefone')) {
        dadosAtualizados['telefone'] = _telefoneController.text;
      }
      if (_podeEditarCampo('endereco')) {
        dadosAtualizados['endereco'] = _enderecoController.text;
      }
      if (_podeEditarCampo('status')) {
        dadosAtualizados['status'] = _statusSelecionado;
        if (_statusSelecionado == 'AFASTADO') {
          dadosAtualizados['data_inicio_inatividade'] = _dataInicio?.toIso8601String().split('T')[0];
          dadosAtualizados['data_fim_inatividade'] = _dataFim?.toIso8601String().split('T')[0];
          dadosAtualizados['motivo_inatividade'] = _motivoController.text;
        }
      }
      if (_isLider) {
        dadosAtualizados['nome'] = _nomeController.text;
        dadosAtualizados['instrumento_principal'] = _instrumentoSelecionado;
      }

      final musicosProvider = Provider.of<MusicosProvider>(context, listen: false);
      final sucesso = await musicosProvider.atualizarMusico(
        widget.musico.id!,
        dadosAtualizados,
      );

      if (!mounted) return;
      LoadingOverlay.hide(context);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      LoadingOverlay.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar alterações'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<InstrumentosProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _instrumentoSelecionado,
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
                        if (_isLider)
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Cadastrar Novo Instrumento'),
                              ],
                            ),
                          ),
                      ],
                      onChanged: _podeEditarCampo('instrumento')
                          ? (value) async {
                              if (value == -1) {
                                final novoInstrumento = await _mostrarDialogoCadastrarInstrumento();
                                if (novoInstrumento != null) {
                                  await provider.listarInstrumentos();
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
            const Text(
              'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _statusSelecionado,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: 'ATIVO', child: Text('Ativo')),
                const DropdownMenuItem(value: 'AFASTADO', child: Text('Afastado Temporariamente')),
                if (_isLider) const DropdownMenuItem(value: 'INATIVO', child: Text('Inativo')),
              ],
              onChanged: (value) {
                setState(() {
                  _statusSelecionado = value;
                  if (value != 'AFASTADO') {
                    _dataInicio = null;
                    _dataFim = null;
                    _motivoController.clear();
                  }
                });
              },
            ),
            if (_statusSelecionado == 'AFASTADO') ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data Início'),
                subtitle: Text(
                  _dataInicio != null ? DateFormat('dd/MM/yyyy').format(_dataInicio!) : 'Selecione uma data',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(context, true),
              ),
              ListTile(
                title: const Text('Data Fim'),
                subtitle: Text(
                  _dataFim != null ? DateFormat('dd/MM/yyyy').format(_dataFim!) : 'Selecione uma data',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(context, false),
              ),
              const SizedBox(height: 16),
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

class BiometricSettingTile extends StatefulWidget {
  const BiometricSettingTile({super.key});

  @override
  State<BiometricSettingTile> createState() => _BiometricSettingTileState();
}

class _BiometricSettingTileState extends State<BiometricSettingTile> {
  bool _enabled = false;
  bool _available = false;
  String _type = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final available = await auth.canUseBiometric();
    final enabled = await auth.isBiometricEnabled();
    final type = await auth.getBiometricDescription();

    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _type = type;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (value) {
      final authenticated = await BiometricService().authenticate(
        reason: 'Confirme para habilitar login biométrico',
      );

      if (authenticated) {
        await auth.enableBiometricLogin();
        if (mounted) {
          setState(() => _enabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login biométrico habilitado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      await auth.disableBiometricLogin();
      if (mounted) {
        setState(() => _enabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login biométrico desabilitado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) {
      return const ListTile(
        leading: Icon(Icons.fingerprint, color: Colors.grey),
        title: Text('Login Biométrico'),
        subtitle: Text('Não disponível neste dispositivo'),
        enabled: false,
      );
    }

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Login Biométrico'),
      subtitle: Text(_type),
      value: _enabled,
      onChanged: _toggleBiometric,
    );
  }
}
