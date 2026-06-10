import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/cliente_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart'; // Import necessário para o construtor
import 'package:projeto_integrador/models/cliente.dart';
import 'package:projeto_integrador/view/cadastro_cliente.dart';
import 'package:projeto_integrador/view/perfil_cliente.dart';

class ListaClientes extends StatefulWidget {
  const ListaClientes({super.key});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  // Instanciamos o seu Controller oficial. 
  // (Como ele pede um VeiculoController no construtor, passamos aqui)
  late final ClienteController _clienteController;
  
  List<Cliente> _clientesExibidos = [];
  bool _estaCarregando = true;

  @override
  void initState() {
    super.initState();
    _clienteController = ClienteController(veiculoController: VeiculoController());
    _inicializarLista();
  }

  /// Carrega os dados do Supabase e organiza em ordem alfabética usando seu método
  Future<void> _inicializarLista() async {
    setState(() => _estaCarregando = true);
    
    // Puxa os dados da nuvem para a memória local do controller
    await _clienteController.carregarClientesDoBanco();
    
    if (mounted) {
      setState(() {
        // REQUISITO ATENDIDO: Usa seu método 'obterClientesOrdenados()'
        _clientesExibidos = _clienteController.obterClientesOrdenados();
        _estaCarregando = false;
      });
    }
  }

  /// REQUISITO ATENDIDO: Usa seu método 'pesquisarCliente()' para filtrar a lista
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
          // Seu campo de busca original intacto
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filtrarClientes, // Conectado à sua lógica de pesquisa
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

          // Lista dinâmica tratando o loading do Supabase
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
                          
                          // Verifica se o cliente tem veículo para não quebrar a tela
                          String textoVeiculo = cliente.meusVeiculos.isNotEmpty
                              ? '${cliente.meusVeiculos.first.modelo} - ${cliente.meusVeiculos.first.placa}'
                              : 'Sem veículo vinculado';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
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
                                cliente.nomeCompleto, // Seu campo oficial
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              subtitle: Text(textoVeiculo),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // Passa o objeto cliente real completo para a tela de perfil
                                    builder: (_) => PerfilCliente(
                                      cliente: {
                                        'nome': cliente.nomeCompleto,
                                        'veiculo': textoVeiculo,
                                        'cpf': cliente.cpf,
                                        'telefone': cliente.telefone,
                                        'email': cliente.email,
                                      },
                                    ),
                                  ),
                                );
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
          // Passamos a instância do controller ativo nesta tela para a tela de cadastro
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaCadastroCliente(clienteController: _clienteController),
            ),
          );
          // Recarrega e força a atualização visual imediata ao voltar
          _inicializarLista();
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}