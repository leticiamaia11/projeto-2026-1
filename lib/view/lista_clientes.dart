import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/cliente_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart'; 
import 'package:projeto_integrador/models/cliente.dart';
import 'package:projeto_integrador/view/cadastro_cliente.dart';
import 'package:projeto_integrador/view/perfil_cliente.dart';

class ListaClientes extends StatefulWidget {
  const ListaClientes({super.key});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  late final ClienteController _clienteController;
  late final VeiculoController _veiculoController; // Guardamos a referência do mesmo controller de veículos
  
  List<Cliente> _clientesExibidos = [];
  bool _estaCarregando = true;

  @override
  void initState() {
    super.initState();
    // 🟢 Inicializa ambos compartilhando o mesmo ecossistema de memória
    _veiculoController = VeiculoController();
    _clienteController = ClienteController(veiculoController: _veiculoController);
    _inicializarLista();
  }

  Future<void> _inicializarLista() async {
    setState(() => _estaCarregando = true);
    
    try {
      // 🟢 CORREÇÃO: Busca os veículos primeiro para que fiquem disponíveis na memória
      await _veiculoController.carregarVeiculosDoBanco();
      // Puxa os clientes do Supabase
      await _clienteController.carregarClientesDoBanco();
    } catch (e) {
      debugPrint("Erro ao carregar dados unificados: $e");
    }
    
    if (mounted) {
      setState(() {
        _clientesExibidos = _clienteController.obterClientesOrdenados();
        _estaCarregando = false;
      });
    }
  }

  void _filtrarClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _clientesExibidos = _clienteController.obterClientesOrdenados();
      } else {
        _clientesExibidos = _clienteController.pesquisarCliente(query);
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
          'Clientes',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filtrarClientes,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
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
          Expanded(
            child: _estaCarregando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
                : _clientesExibidos.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum cliente cadastrado.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _clientesExibidos.length,
                        itemBuilder: (context, index) {
                          final cliente = _clientesExibidos[index];
                          
                          // 🟢 CORREÇÃO: Varre os veículos do controlador associados a este cliente
                          final carrosDoDono = _veiculoController.obterVeiculosOrdenados().where(
                            (v) => v.proprietario.toLowerCase() == cliente.nomeCompleto.toLowerCase()
                          ).toList();

                          String textoVeiculo = carrosDoDono.isNotEmpty
                              ? '${carrosDoDono.first.modelo} - ${carrosDoDono.first.placa}'
                              : 'Sem veículo vinculado';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF91B9D1),
                                child: Text(
                                  cliente.nomeCompleto.isNotEmpty ? cliente.nomeCompleto[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                cliente.nomeCompleto,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                              subtitle: Text(textoVeiculo),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () async {
                                // 🟢 CORREÇÃO: Passa o objeto real adaptado para o Perfil não perder as referências
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PerfilCliente(
                                      cliente: {
                                        'nome': cliente.nomeCompleto,
                                        'proprietario': cliente.nomeCompleto,
                                        'veiculo': textoVeiculo,
                                        'cpf': cliente.cpf,
                                        'telefone': cliente.telefone,
                                        'email': cliente.email,
                                      },
                                      clienteController: _clienteController, // Passa o controle adiante
                                    ),
                                  ),
                                );
                                _inicializarLista(); // Atualiza ao retornar
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaCadastroCliente(clienteController: _clienteController),
            ),
          );
          _inicializarLista();
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}