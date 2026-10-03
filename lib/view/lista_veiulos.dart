import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/controllers/cliente_controller.dart'; // IMPORTADO: Necessário para instanciar o controller
import 'package:projeto_integrador/models/veiculo.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/perfil_cliente.dart';

class ListaVeiculos extends StatefulWidget {
  const ListaVeiculos({super.key});

  @override
  State<ListaVeiculos> createState() => _ListaVeiculosState();
}

class _ListaVeiculosState extends State<ListaVeiculos> {
  // Substituído a lista estática pelo seu Controller Oficial
  final VeiculoController _veiculoCtrl = VeiculoController();

  // CORREÇÃO: Criada a instância do ClienteController necessária para abastecer a tela de cadastro
  final ClienteController _clienteCtrl = ClienteController(
    veiculoController: VeiculoController(),
  );

  List<Veiculo> _veiculosExibidos = [];
  bool _estaCarregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosDoBanco();
  }

  /// Puxa em tempo real os veículos salvos no Supabase
  Future<void> _carregarDadosDoBanco() async {
    setState(() => _estaCarregando = true);

    try {
      // Carrega os dados para a listaDeVeiculos interna do seu controller
      await _veiculoCtrl.carregarVeiculosDoBanco();
    } catch (e) {
      print(
        "Nota: Certifique-se de ter o método de carga implementado no controller: $e",
      );
    }

    if (mounted) {
      setState(() {
        _veiculosExibidos = _veiculoCtrl.listaDeVeiculos;
        _estaCarregando = false;
      });
    }
  }

  /// Filtra a lista local usando as propriedades do objeto Veiculo real
  void _filtrarVeiculos(String query) {
    setState(() {
      if (query.isEmpty) {
        _veiculosExibidos = _veiculoCtrl.listaDeVeiculos;
      } else {
        _veiculosExibidos = _veiculoCtrl.listaDeVeiculos
            .where(
              (veiculo) =>
                  veiculo.modelo.toLowerCase().contains(query.toLowerCase()) ||
                  veiculo.placa.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Veículos',
          style: TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Campo de busca intacto ligado ao filtro dinâmico
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filtrarVeiculos,
              decoration: InputDecoration(
                hintText: 'Buscar veículo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tratamento dinâmico da árvore de componentes (Loading ou Lista Remota)
          Expanded(
            child: _estaCarregando
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                  )
                : _veiculosExibidos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum veículo encontrado.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _veiculosExibidos.length,
                    itemBuilder: (context, index) {
                      final veiculo =
                          _veiculosExibidos[index]; // Mapeado para o Model real

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ícone azul do carro do protótipo
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8BB7D6).withAlpha(150),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_outlined,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    veiculo.modelo, // Campo real do model
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    veiculo.placa, // Campo real do model
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    veiculo.proprietario ??
                                        'Sem proprietário', // Tratando nulos com segurança
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botão de excluir (ícone do lápis azul)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline, // Ícone de lixeira
                                color: Colors
                                    .redAccent, // Cor vermelha para indicar ação destrutiva
                                size: 22,
                              ),
                              onPressed: () async {
                                // 1. Confirmação antes de excluir
                                bool? confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Excluir Veículo"),
                                    content: Text(
                                      "Tem certeza que deseja remover ${veiculo.modelo}?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "Excluir",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                // 2. Execução da exclusão no banco e na tela
                                if (confirmar == true) {
                                  setState(() => _estaCarregando = true);

                                  bool sucesso = await _veiculoCtrl
                                      .removerVeiculo(veiculo.placa);
                                  {
                                    if (sucesso) {
                                      if (!mounted) return;
                                      _carregarDadosDoBanco(); // Recarrega a lista do banco
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Veículo removido com sucesso!",
                                          ),
                                        ),
                                      );
                                    } else {
                                      setState(() => _estaCarregando = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Erro ao remover veículo.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // CORREÇÃO: Nome do parâmetro corrigido e passando a instância correta gerenciada pela tela
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TelaCadastroVeiculo(clienteController: _clienteCtrl),
            ),
          );

          // Quando o usuário volta do cadastro, recarrega a lista do banco de dados na tela
          _carregarDadosDoBanco();
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}