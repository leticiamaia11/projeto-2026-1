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
  
  List<Map<String, dynamic>> _todosOsServicos = []; // Cache com tudo vindo do banco
  List<Map<String, dynamic>> _servicosFiltrados = []; // O que de fato aparece na lista
  List<Veiculo> _veiculosParaFiltro = []; // Lista de carros pro Dropdown
  
  String _filtroSelecionado = "TODOS"; // Controla o estado do filtro (TODOS ou a Placa)
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  // Carrega em paralelo os veículos e todos os serviços cadastrados
  Future<void> _inicializarDados() async {
    setState(() => _carregando = true);
    try {
      // 1. Carrega os veículos usando o seu VeiculoController
      await widget.veiculoController.carregarVeiculosDoBanco();
      
      // 2. Busca TODOS os serviços cadastrados no sistema (sem filtro de placa inicial)
      final dadosServicos = await _supabase
          .from('registro_servicos')
          .select()
          .order('data', ascending: false);

      setState(() {
        _veiculosParaFiltro = widget.veiculoController.obterVeiculosOrdenados();
        _todosOsServicos = List<Map<String, dynamic>>.from(dadosServicos);
        _aplicarFiltroLocal(); // Aplica a filtragem na memória
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Erro ao carregar dados: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Executa o filtro de forma ultra rápida diretamente na memória do celular
  void _aplicarFiltroLocal() {
    if (_filtroSelecionado == "TODOS") {
      _servicosFiltrados = List.from(_todosOsServicos);
    } else {
      _servicosFiltrados = _todosOsServicos
          .where((servico) => servico['placa_veiculo'] == _filtroSelecionado)
          .toList();
    }
  }

  // Caixas de diálogo de detalhes, observações e exclusão mantidas conforme o seu padrão
  void _mostrarDetalhesServico(Map<String, dynamic> servico) {
    showDialog(
      context: context,
      builder: (context) {
        final dataStr = servico['data'] ?? servico['data'];
        final dataFormatada = dataStr != null 
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dataStr.toString()))
            : 'Sem data';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(servico['descricao'] ?? 'Detalhes do Serviço', style: const TextStyle(color: Color(0xFF1E40AF))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${servico['placa_veiculo'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${(servico['valor'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Duração: ${servico['duracao_horas'] ?? 0} hora(s)', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Realizado em: $dataFormatada', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Observações regulares:\n${servico['observacoes'] ?? 'Nenhuma observação anotada.'}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Color(0xFF1E40AF))),
            )
          ],
        );
      },
    );
  }

  void _abrirModalObservacao(Map<String, dynamic> servico) {
    final txtCtrl = TextEditingController(text: servico['observacoes'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Observação Regular'),
          content: TextField(
            controller: txtCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex: Problema regular devido ao desgaste...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _carregando = true);
                try {
                  await _supabase
                      .from('registro_servicos')
                      .update({'observacoes': txtCtrl.text.trim()})
                      .eq('id', servico['id']);

                  _inicializarDados(); 
                } catch (e) {
                  debugPrint("Erro ao salvar observação: $e");
                }
              },
              child: const Text('Salvar Alteração', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _deletarServico(dynamic idServico) async {
    setState(() => _carregando = true);
    try {
      await _supabase.from('registro_servicos').delete().eq('id', idServico);
      _inicializarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Serviço removido com sucesso!")),
        );
      }
    } catch (e) {
      setState(() => _carregando = false);
      debugPrint("Erro ao deletar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Histórico de Serviços',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : Column(
              children: [
                // 🟢 COMPONENTE FILTRO DE VEÍCULOS NO TOPO DA TELA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 12),
                      const Text(
                        'Filtrar Carro:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtroSelecionado,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              const DropdownMenuItem(
                                value: "TODOS",
                                child: Text("Todos os Veículos", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                              ),
                              ..._veiculosParaFiltro.map((v) {
                                return DropdownMenuItem(
                                  value: v.placa,
                                  child: Text('${v.modelo} (${v.placa})'),
                                );
                              }),
                            ],
                            onChanged: (novoValor) {
                              if (novoValor != null) {
                                setState(() {
                                  _filtroSelecionado = novoValor;
                                  _aplicarFiltroLocal();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // LISTAGEM DOS SERVIÇOS REALIZADOS
                Expanded(
                  child: _servicosFiltrados.isEmpty
                      ? _buildStateVazio()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _servicosFiltrados.length,
                          itemBuilder: (context, index) {
                            final servico = _servicosFiltrados[index];
                            final dataStr = servico['data_servico'] ?? servico['data'];
                            final dataFormatada = dataStr != null 
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dataStr.toString()))
                                : '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                onTap: () => _mostrarDetalhesServico(servico),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        servico['descricao'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Tag discreta exibindo a placa do carro no card
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        servico['placa_veiculo'] ?? '',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                      ),
                                    )
                                  ],
                                ),
                                subtitle: Text('$dataFormatada • R\$ ${(servico['valor'] ?? 0.0).toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.note_add_outlined, color: Color(0xFF1E40AF)),
                                      onPressed: () => _abrirModalObservacao(servico),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deletarServico(servico['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E40AF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Serviço', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaServicos(
                servicoController: widget.servicoController,
              ),
            ),
          );
          if (resultado == true) {
            _inicializarDados(); // Recarrega se inseriu um novo serviço
          }
        },
      ),
    );
  }

  Widget _buildStateVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _filtroSelecionado == "TODOS" 
                  ? 'Nenhum serviço registrado no sistema.'
                  : 'Nenhum serviço registrado para o carro $_filtroSelecionado.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}