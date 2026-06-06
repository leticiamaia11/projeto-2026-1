import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:projeto_integrador/view/servicos.dart'; 
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';

class TelaHistorico extends StatefulWidget {
  final Map<String, dynamic> veiculo; // Recebe o veículo selecionado

  const TelaHistorico({super.key, required this.veiculo});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _servicos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarHistoricoDoSupabase();
  }

  // Busca em tempo real os serviços atrelados à placa ou ID deste veículo
  Future<void> _buscarHistoricoDoSupabase() async {
    setState(() => _carregando = true);
    try {
      final placa = widget.veiculo['placa'];
      
      final dados = await _supabase
          .from('servicos')
          .select()
          .eq('placa_veiculo', placa)
          .order('data_servico', ascending: false);

      setState(() {
        _servicos = List<Map<String, dynamic>>.from(dados);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Erro ao carregar histórico: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // CRITÉRIO DE ACEITE: Mostra todas as informações detalhadas em um Modal
  void _mostrarDetalhesServico(Map<String, dynamic> servico) {
    showDialog(
      context: context,
      builder: (context) {
        final dataStr = servico['data_servico'] ?? servico['data'];
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
              Text('Placa: ${servico['placa_veiculo'] ?? ''}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${(servico['valor'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // FLUXO ALTERNATIVO: Permite adicionar ou editar uma Observação (Salva no Supabase)
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
              hintText: 'Ex: Este problema ocorre regularmente devido ao desgaste da peça X...',
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
                  // Atualiza a coluna de observação diretamente no Supabase
                  await _supabase
                      .from('servicos')
                      .update({'observacoes': txtCtrl.text.trim()})
                      .eq('id', servico['id']);

                  _buscarHistoricoDoSupabase(); // Recarrega os dados do banco
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

  // FLUXO ALTERNATIVO: Excluir Serviços do banco de dados
  void _deletarServico(dynamic idServico) async {
    setState(() => _carregando = true);
    try {
      await _supabase.from('servicos').delete().eq('id', idServico);
      _buscarHistoricoDoSupabase();
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
        title: Text(
          'Histórico: ${widget.veiculo['modelo'] ?? 'Veículo'}',
          style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
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
          : _servicos.isEmpty
              ? _buildStateVazio() // FLUXO ALTERNATIVO se não houver dados
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _servicos.length,
                  itemBuilder: (context, index) {
                    final servico = _servicos[index];
                    final dataStr = servico['data_servico'] ?? servico['data'];
                    final dataFormatada = dataStr != null 
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dataStr.toString()))
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _mostrarDetalhesServico(servico), // CRITÉRIO DE ACEITE
                        title: Text(
                          servico['descricao'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E40AF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Serviço', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          // CRITÉRIO DE ACEITE: Redireciona para a tela de registro injetando a dependência exigida
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaServicos(
                servicoController: ServicoController(veiculoController: VeiculoController()),
              ),
            ),
          );
          if (resultado == true) {
            _buscarHistoricoDoSupabase(); // Recarrega se inseriu um novo serviço
          }
        },
      ),
    );
  }

  // Widget visual para tratar o fluxo alternativo quando a lista está zerada
  Widget _buildStateVazio() {
    return Center(
      child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_circle_outlined, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum serviço registrado para este veículo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaServicos(
                    servicoController: ServicoController(veiculoController: VeiculoController()),
                  ),
                ),
              );
              if (resultado == true) _buscarHistoricoDoSupabase();
            },
            child: const Text(
              'Gostaria de adicionar novos serviços?',
              style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 15),
            ),
          )
        ],
      ),
      ),
    );
  }
}