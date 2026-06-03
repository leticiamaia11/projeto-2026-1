import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/servicos.dart';

class PerfilCliente extends StatefulWidget {
  // Recebe os dados do cliente que foi clicado na lista anterior
  final Map<String, dynamic> cliente;

  const PerfilCliente({super.key, required this.cliente});

  @override
  State<PerfilCliente> createState() => _PerfilClienteState();
}

class _PerfilClienteState extends State<PerfilCliente> {
  // Simulando dados que virão das tabelas relacionadas do Supabase
  List<Map<String, dynamic>> veiculosDoCliente = [];
  List<Map<String, dynamic>> servicosDoVeiculo = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDadosRelacionados();
  }

  // Futuramente, esta função fará o SELECT filtrando pelas chaves estrangeiras no Supabase
  void _buscarDadosRelacionados() {
    // Exemplo de filtragem: futuramente seria .from('veiculos').select().eq('cliente_id', widget.cliente['id'])
    setState(() {
      veiculosDoCliente = [
        {'id': 1, 'modelo': 'Celta', 'placa': 'ABC-1234'}
      ];

      // Futuramente: .from('servicos').select().eq('veiculo_id', veiculosDoCliente[0]['id'])
      servicosDoVeiculo = [
        {'descricao': 'Troca de óleo', 'data': 'xx/xx/xxxx', 'valor': 350.00},
        {'descricao': 'Alinhamento', 'data': 'xx/xx/xxxx', 'valor': 120.00},
      ];
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.cliente;

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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho: Foto, Nome e Ícone de Editar
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color( 0xFFCCCCCC),
                        child: Icon(Icons.person, size: 45, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          cliente['proprietario'] ?? cliente['nome'] ?? 'Nome do Cliente',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF2B5CB3)),
                        onPressed: () {
                          // Ação para editar perfil do cliente
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Seção: Informações Pessoais
                  const Text(
                    'Informações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B5CB3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Telefone: ${cliente['telefone'] ?? '(41) 99999-9999'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('E-mail: ${cliente['email'] ?? 'cliente@gmail.com'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('CPF: ${cliente['cpf'] ?? '000.000.000-00'}', style: const TextStyle(fontSize: 15)),
                  
                  const SizedBox(height: 20),
                  const Divider(),

                  // Seção: Veículos
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFF1E40AF)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  
                  // Card do Veículo baseado no layout
                  if (veiculosDoCliente.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BB7D6).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 45),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modelo do veículo: ${veiculosDoCliente[0]['modelo']}', style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Placa: ${veiculosDoCliente[0]['placa']}', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Botão Adicionar Veículo
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaCadastroVeiculo(), // Tela para cadastrar um novo veículo
                          ),
                        );
                      },
                      icon: const Text('Adicionar veículo', style: TextStyle(color: Colors.grey)),
                      label: const Icon(Icons.add_circle, color: Color(0xFF2B5CB3)),
                    ),
                  ),
                  const Divider(),

                  // Seção: Histórico de Serviços
                  const Text(
                    'Histórico de Serviços',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B5CB3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (veiculosDoCliente.isNotEmpty)
                    Text(
                      'Veículo\n${veiculosDoCliente[0]['modelo']} - ${veiculosDoCliente[0]['placa']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  const SizedBox(height: 12),

                  // Lista de serviços do histórico
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicosDoVeiculo.length,
                    itemBuilder: (context, index) {
                      final servico = servicosDoVeiculo[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${servico['descricao']} - ${servico['data']}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            Text(
                              'R\$ ${servico['valor'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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

                  // Botão Adicionar Serviço
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaServicos(), 
                          ),
                        );
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