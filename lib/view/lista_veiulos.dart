import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/perfil_cliente.dart';

class ListaVeiculos extends StatelessWidget {
  const ListaVeiculos({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de lista de usuários (isso pode ficar aqui dentro sem problemas por enquanto)
    final List<Map<String, String>> clientes = [
      {'modelo': 'Celta Life', 'placa': 'ABC1234', 'proprietario' : 'Emily Sabrina'},
      {'nome': 'Emily Sabrina', 'veiculo': 'Fiat Argo - DEF5678'},
    ];

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
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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

          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF91B9D1),
                      child: Text(
                        cliente['nome']![0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      cliente['nome']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    subtitle: Text(cliente['veiculo']!),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PerfilCliente(),
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
      // O botão flutuante deve ficar DENTRO do Scaffold, mas FORA do body
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaCadastroVeiculo()),
          );
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
