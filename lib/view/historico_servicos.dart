import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:projeto_integrador/view/servicos.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/models/veiculo.dart';

class TelaHistorico extends StatefulWidget {
  final ServicoController servicoController;
  final VeiculoController veiculoController;

  const TelaHistorico({
    super.key,
    required this.servicoController,
    required this.veiculoController,
  });

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _todosOsServicos = [];
  List<Map<String, dynamic>> _servicosFiltrados = [];
  List<Veiculo> _veiculosParaFiltro = [];

  String _filtroSelecionado = "TODOS";
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    setState(() => _carregando = true);
    try {
      await widget.veiculoController.carregarVeiculosDoBanco();
      final dadosServicos = await _supabase
          .from('registro_servicos')
          .select()
          .order('data', ascending: false);

      if (mounted) {
        setState(() {
          _veiculosParaFiltro = widget.veiculoController.obterVeiculosOrdenados();
          _todosOsServicos = List<Map<String, dynamic>>.from(dadosServicos);
          _aplicarFiltroLocal();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Erro ao carregar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aplicarFiltroLocal() {
    if (_filtroSelecionado == "TODOS") {
      _servicosFiltrados = List.from(_todosOsServicos);
    } else {
      _servicosFiltrados = _todosOsServicos
          .where((servico) => servico['placaveiculo'] == _filtroSelecionado)
          .toList();
    }
  }

  void _mostrarDetalhesServico(Map<String, dynamic> servico) {
    showDialog(
      context: context,
      builder: (context) {
        final dataStr = servico['data'];
        final dataFormatada = dataStr != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dataStr.toString()))
            : 'Sem data';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(servico['descricao'] ?? 'Detalhes', style: const TextStyle(color: Color(0xFF1E40AF))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${servico['placaveiculo'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${(servico['valor'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Duração: ${servico['duracaoemhoras'] ?? 0} hora(s)', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Realizado em: $dataFormatada', style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar', style: TextStyle(color: Color(0xFF1E40AF)))),
          ],
        );
      },
    );
  }

  void _deletarServico(dynamic idServico) async {
    setState(() => _carregando = true);
    try {
      await _supabase.from('registro_servicos').delete().eq('id', idServico);
      await _inicializarDados();
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Histórico de Serviços', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)), onPressed: () => Navigator.pop(context)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _filtroSelecionado,
                  decoration: const InputDecoration(labelText: "Filtrar por placa", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: "TODOS", child: Text("Todos os veículos")),
                    ..._veiculosParaFiltro.map((v) => DropdownMenuItem(value: v.placa, child: Text(v.placa))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filtroSelecionado = val!;
                      _aplicarFiltroLocal();
                    });
                  },
                ),
              ),
              Expanded(
                child: _servicosFiltrados.isEmpty
                    ? _buildStateVazio()
                    : ListView.builder(
                        itemCount: _servicosFiltrados.length,
                        itemBuilder: (context, i) {
                          final s = _servicosFiltrados[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(s['descricao'] ?? 'Serviço', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Placa: ${s['placaveiculo'] ?? ''}"),
                              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletarServico(s['id'])),
                              onTap: () => _mostrarDetalhesServico(s),
                            ),
                          );
                        },
                      ),
              ),
            ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E40AF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Serviço', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => TelaServicos(servicoController: widget.servicoController)));
          if (resultado == true) _inicializarDados();
        },
      ),
    );
  }

  Widget _buildStateVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_circle_outlined, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_filtroSelecionado == "TODOS" ? 'Nenhum serviço registrado.' : 'Nenhum serviço para $_filtroSelecionado.',
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}