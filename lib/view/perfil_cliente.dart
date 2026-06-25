import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/servicos.dart';
import 'package:projeto_integrador/controllers/perfil_cliente_controller.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/controllers/cliente_controller.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../view/cadastro_cliente.dart';

class PerfilCliente extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final ClienteController clienteController;

  const PerfilCliente({
    super.key,
    required this.cliente,
    required this.clienteController,
  });

  @override
  State<PerfilCliente> createState() => _PerfilClienteState();
}

class _PerfilClienteState extends State<PerfilCliente> {
  late PerfilClienteController _controller;
  late ServicoController _servicoCtrl;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _controller = PerfilClienteController(cliente: widget.cliente);

    // Reaproveita a infraestrutura do controller existente para evitar duplicação de dados
    final veiculoCtrl = widget.clienteController.veiculoController;
    _servicoCtrl = ServicoController(veiculoController: veiculoCtrl);

    _carregarInformacoes();
  }

  Future<void> _carregarInformacoes() async {
    setState(() => _carregando = true);
    try {
      // Carrega os dados mapeados no PerfilClienteController (Supabase)
      await _controller.buscarDadosRelacionados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Erro ao carregar dados do banco: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _confirmarExclusaoVeiculo(Map<String, dynamic> veiculo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Excluir Veículo"),
          content: Text(
            "Deseja realmente remover o veículo ${veiculo['modelo'] ?? ''} (${veiculo['placa'] ?? ''})?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _carregando = true);

                bool sucesso = await _controller.deletarVeiculoDoBanco(veiculo);

                if (mounted) {
                  setState(() => _carregando = false);
                  if (sucesso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text("Veículo deletado com sucesso!"),
                      ),
                    );
                    _carregarInformacoes();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text("Falha ao deletar o veículo."),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Excluir",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatarData(dynamic dataRaw) {
    if (dataRaw == null) return '';
    try {
      DateTime dataParsed = dataRaw is DateTime
          ? dataRaw
          : DateTime.parse(dataRaw.toString());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF1E40AF)),
            onPressed: () async {
              final clienteObj = Cliente.fromMap(widget.cliente);

              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaCadastroCliente(
                    clienteController: widget.clienteController,
                    clienteParaEditar: clienteObj,
                  ),
                ),
              );
              if (resultado == true) {
                _carregarInformacoes();
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: () async {
              // 1. Confirmação
              bool? confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Excluir Cliente"),
                  content: const Text(
                    "Isso removerá permanentemente o cliente e todos os veículos vinculados a ele. Tem certeza?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Excluir Tudo",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              // 2. Ação de Exclusão
              if (confirmar == true) {
                setState(() => _carregando = true);

                // Usa o ID do cliente que está dentro do Map widget.cliente
                String idCliente = widget.cliente['id'].toString();

                bool sucesso = await widget.clienteController
                    .deletarClienteComVeiculos(idCliente);

                if (mounted) {
                  if (sucesso) {
                    Navigator.pop(
                      context,
                    ); // Fecha o perfil e volta para a lista
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cliente removido com sucesso!"),
                      ),
                    );
                  } else {
                    setState(() => _carregando = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erro ao remover cliente.")),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
            )
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
                        child: Icon(
                          Icons.person,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          cliente['proprietario'] ??
                              cliente['nome'] ??
                              'Nome do Cliente',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    'Informações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B5CB3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Telefone: ${cliente['telefone'] ?? 'Não informado'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'E-mail: ${cliente['email'] ?? 'Não informado'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CPF: ${cliente['cpf'] ?? 'Não informado'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Seção de Veículos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Veículos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B5CB3),
                        ),
                      ),
                      if (_controller.veiculosDoCliente.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmarExclusaoVeiculo(
                            _controller.veiculosDoCliente[0],
                          ),
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
                          child: const Icon(
                            Icons.directions_car_filled_outlined,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modelo do veículo: ${_controller.veiculosDoCliente[0]['modelo'] ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Placa: ${_controller.veiculosDoCliente[0]['placa'] ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Nenhum veículo cadastrado para este cliente.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        // 🟢 CORREÇÃO: Repassa o controlador herdado válido para que o dropdown funcione
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaCadastroVeiculo(
                              clienteController: widget.clienteController,
                            ),
                          ),
                        );
                        _carregarInformacoes();
                      },
                      icon: const Text(
                        'Adicionar veículo',
                        style: TextStyle(color: Colors.grey),
                      ),
                      label: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF2B5CB3),
                      ),
                    ),
                  ),
                  const Divider(),

                  // Histórico de serviços
                  const Text(
                    'Histórico de Serviços',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B5CB3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_controller.veiculosDoCliente.isNotEmpty)
                    Text(
                      'Veículo\n${_controller.veiculosDoCliente[0]['modelo'] ?? ''} - ${_controller.veiculosDoCliente[0]['placa'] ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  const SizedBox(height: 12),

                  // Substitua o seu ListView.builder de veículos por isto:
                  const Text(
                    'Veículos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B5CB3),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final atualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TelaServicos(servicoController: _servicoCtrl),
                          ),
                        );
                        if (atualizado == true) {
                          _carregarInformacoes();
                        }
                      },
                      icon: const Text(
                        'Adicionar serviço',
                        style: TextStyle(color: Colors.grey),
                      ),
                      label: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF2B5CB3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
