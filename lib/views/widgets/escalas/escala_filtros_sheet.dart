import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/models/eventos.dart';

const _kMesesAbrev = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

class EscalaFiltro {
  int? ano;
  int? mes;
  String? musicoNome;
  String? instrumentoNome;

  bool get ativo => ano != null || mes != null || musicoNome != null || instrumentoNome != null;

  void limpar() {
    ano = null;
    mes = null;
    musicoNome = null;
    instrumentoNome = null;
  }

  String get descricao {
    final partes = <String>[];
    if (ano != null) partes.add('$ano');
    if (mes != null) partes.add(_kMesesAbrev[mes! - 1]);
    if (musicoNome != null) partes.add(musicoNome!);
    if (instrumentoNome != null) partes.add(instrumentoNome!);
    return 'Filtro: ${partes.join(' • ')}';
  }
}

class EscalaFiltrosSheet extends StatelessWidget {
  const EscalaFiltrosSheet({
    super.key,
    required this.filtro,
    required this.eventosMap,
    required this.onAplicar,
  });

  final EscalaFiltro filtro;
  final Map<int, Evento> eventosMap;
  final VoidCallback onAplicar;

  static Future<void> show({
    required BuildContext context,
    required EscalaFiltro filtro,
    required Map<int, Evento> eventosMap,
    required VoidCallback onAplicar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EscalaFiltrosSheet(
        filtro: filtro,
        eventosMap: eventosMap,
        onAplicar: onAplicar,
      ),
    );
  }

  List<int> _anosDisponiveis(Map<int, Evento> eventosMap) {
    return eventosMap.values.map((e) => DateTime.tryParse(e.dataEvento)?.year).whereType<int>().toSet().toList()
      ..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    final anos = _anosDisponiveis(eventosMap);

    return StatefulBuilder(
      builder: (ctx, setSheet) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ListView(
              controller: scrollController,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // cabeçalho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        setSheet(() => filtro.limpar());
                        onAplicar();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Limpar tudo'),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Ano
                const Text('Ano', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                anos.isEmpty
                    ? const Text('Nenhum ano disponível', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: anos
                            .map((ano) => ChoiceChip(
                                  label: Text('$ano'),
                                  selected: filtro.ano == ano,
                                  onSelected: (v) => setSheet(() => filtro.ano = v ? ano : null),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 20),

                // Mês
                const Text('Mês', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(12, (i) {
                    final mes = i + 1;
                    return ChoiceChip(
                      label: Text(_kMesesAbrev[i]),
                      selected: filtro.mes == mes,
                      onSelected: (v) => setSheet(() => filtro.mes = v ? mes : null),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Músico
                const Text('Músico', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Consumer<MusicosProvider>(
                  builder: (context, provider, _) {
                    final nomes = provider.musicos.map((m) => m.nome).toList();
                    return Autocomplete<String>(
                      initialValue: TextEditingValue(text: filtro.musicoNome ?? ''),
                      optionsBuilder: (v) =>
                          v.text.isEmpty ? nomes : nomes.where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
                      onSelected: (valor) => setSheet(() => filtro.musicoNome = valor),
                      fieldViewBuilder: (context, controller, focusNode, _) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Digite o nome do músico',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: filtro.musicoNome != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      controller.clear();
                                      setSheet(() => filtro.musicoNome = null);
                                    },
                                  )
                                : const Icon(Icons.search, size: 18),
                          ),
                          onChanged: (v) {
                            if (v.isEmpty) setSheet(() => filtro.musicoNome = null);
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final nome = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.person_outline, size: 20),
                                    title: Text(nome),
                                    onTap: () => onSelected(nome),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Instrumento
                const Text('Instrumento', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Selecione para filtrar escalas que contenham este instrumento',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 10),
                Consumer<InstrumentosProvider>(
                  builder: (context, provider, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: filtro.instrumentoNome == null,
                          onSelected: (_) => setSheet(() => filtro.instrumentoNome = null),
                        ),
                        ...provider.instrumentos.map(
                          (inst) => ChoiceChip(
                            label: Text(inst.nome),
                            selected: filtro.instrumentoNome == inst.nome,
                            onSelected: (v) => setSheet(() => filtro.instrumentoNome = v ? inst.nome : null),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Botão aplicar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar filtros'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      onAplicar();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
