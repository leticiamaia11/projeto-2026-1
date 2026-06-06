import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/servicos.dart';
import 'package:projeto_integrador/controllers/perfil_cliente_controller.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart'; // Importado
import 'package:projeto_integrador/controllers/veículo_controller.dart'; // Importado se necessário para inicializar
import 'package:intl/intl.dart'; // Importado para formatar a data na listagem

class PerfilCliente extends StatefulWidget {
  final Map<String, dynamic> cliente;
  const PerfilCliente({super.key, required this.cliente});

  @override
  State<PerfilCliente> createState() => _PerfilClienteState();
}

class _PerfilClienteState extends State<PerfilCliente> {
  late PerfilClienteController _controller;
  late ServicoController _servicoCtrl; // Declarado para resolver o erro de escopo
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _controller = PerfilClienteController(cliente: widget.cliente);
    
    // Inicializa os controllers necessários para cumprir o requisito do construtor da TelaServicos
    final veiculoCtrlGenerico = VeiculoController(); 
    _servicoCtrl = ServicoController(veiculoController: veiculoCtrlGenerico);
    
    _carregarInformacoes();
  }

  // Faz a chamada assíncrona ao banco e atualiza o estado da tela
  Future<void> _carregarInformacoes() async {
    setState(() => _carregando = true);
    try {
      await _controller.buscarDadosRelacionados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Erro ao carregar dados do banco: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Modal de confirmação que dispara a ação do Supabase
  void _confirmarExclusaoVeiculo(Map<String, dynamic> veiculo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Excluir Veículo"),
          content: Text("Deseja realmente remover o veículo ${veiculo['modelo'] ?? ''} (${veiculo['placa'] ?? ''}) do Supabase?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Fecha o modal
                setState(() => _carregando = true); // Ativa o indicador de progresso

                bool sucesso = await _controller.deletarVeiculoDoBanco(veiculo);

                if (mounted) {
                  setState(() => _carregando = false);
                  
                  if (sucesso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.green, content: Text("Veículo deletedo com sucesso do banco!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text("Falha ao deletar o veículo.")),
                    );
                  }
                }
              },
              child: const Text("Excluir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Função auxiliar para formatar datas vindas do banco (String ou DateTime)
  String _formatarData(dynamic dataRaw) {
    if (dataRaw == null) return '';
    try {
      DateTime dataParsed = dataRaw is DateTime ? dataRaw : DateTime.parse(dataRaw.toString());
      return DateFormat('dd/MM/yyyy').format(dataParsed);
    } catch (e) {
      return dataRaw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = _controller.cliente;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFCCCCCC),
                        child: Icon(Icons.person, size: 45, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          cliente['proprietario'] ?? cliente['nome'] ?? 'Nome do Cliente',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF2B5CB3)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text('Informações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF2B5CB3))),
                  const SizedBox(height: 8),
                  Text('Telefone: ${cliente['telefone'] ?? '(41) 99999-9999'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('E-mail: ${cliente['email'] ?? 'cliente@gmail.com'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('CPF: ${cliente['cpf'] ?? '000.000.000-00'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Seção de Veículos conectada ao banco
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Veículos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF2B5CB3))),
                      if (_controller.veiculosDoCliente.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmarExclusaoVeiculo(_controller.veiculosDoCliente[0]),
                        ),
                    ],
                  ),
                  
                  if (_controller.veiculosDoCliente.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BB7D6).withAlpha(178),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 45),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modelo do veículo: ${_controller.veiculosDoCliente[0]['modelo'] ?? ''}', style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Placa: ${_controller.veiculosDoCliente[0]['placa'] ?? ''}', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Nenhum veículo cadastrado para este cliente.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCadastroVeiculo()));
                        _carregarInformacoes(); // Recarrega os dados reais após cadastrar
                      },
                      icon: const Text('Adicionar veículo', style: TextStyle(color: Colors.grey)),
                      label: const Icon(Icons.add_circle, color: Color(0xFF2B5CB3)),
                    ),
                  ),
                  const Divider(),

                  // Histórico de serviços vindo do banco
                  const Text('Histórico de Serviços', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF2B5CB3))),
                  const SizedBox(height: 4),
                  if (_controller.veiculosDoCliente.isNotEmpty)
                    Text(
                      'Veículo\n${_controller.veiculosDoCliente[0]['modelo'] ?? ''} - ${_controller.veiculosDoCliente[0]['placa'] ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.servicosDoVeiculo.length,
                    itemBuilder: (context, index) {
                      final servico = _controller.servicosDoVeiculo[index];
                      final valor = servico['valor'] ?? 0.0;
                      final dataFormatada = _formatarData(servico['data_servico'] ?? servico['data']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${servico['descricao'] ?? ''} - $dataFormatada', 
                                style: const TextStyle(fontSize: 15)
                              )
                            ),
                            Text(
                              'R\$ ${double.parse(valor.toString()).toStringAsFixed(2)}', 
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, color: Color(0xFF2B5CB3), size: 18),
                            const SizedBox(width: 8),
                            const Icon(Icons.delete_outline, color: Color(0xFF2B5CB3), size: 18),
                          ],
                        ),
                      );
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        // Navega e aguarda o pop retornar um resultado (se sucesso == true)
                        final atualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaServicos(servicoController: _servicoCtrl),
                          ),
                        );
                        
                        if (atualizado == true) {
                          _carregarInformacoes(); // Recarrega os dados do Supabase imediatamente
                        }
                      },
                      icon: const Text('Adicionar serviço', style: TextStyle(color: Colors.grey)),
                      label: const Icon(Icons.add_circle, color: Color(0xFF2B5CB3)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}