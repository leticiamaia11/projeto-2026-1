import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_veiculo.dart';
import 'package:projeto_integrador/view/perfil_cliente.dart';

class ListaVeiculos extends StatefulWidget {
  const ListaVeiculos({super.key});

  @override
  State<ListaVeiculos> createState() => _ListaVeiculosState();
}

class _ListaVeiculosState extends State<ListaVeiculos> {
  // Exemplo de lista de veículos
    final List<Map<String, String>> veiculos = [
      {
        'modelo': 'Celta Life',
        'placa': 'ABC - 1234',
        'proprietario': 'Emily Sabrina',
      },
      {
        'modelo': 'Gol Trend',
        'placa': 'ABC - 1111',
        'proprietario': 'Thayná Lima',
      },
      {
        'modelo': 'Onix LTZ',
        'placa': 'ABC - 0000',
        'proprietario': 'Letícia Maia',
      },
      {
        'modelo': 'Pálio Attractive',
        'placa': 'ABC - 9999',
        'proprietario': 'Valentina Santos',
      },
    ];

    late List<Map<String, String>> veiculosFiltrados;

  @override
  void initState() {
    super.initState();
    veiculosFiltrados = veiculos; // Inicialmente mostra todos
  }

   void _filtrarVeiculos(String query) {
    setState(() {
      veiculosFiltrados = veiculos
          .where(
            (veiculo) =>
                veiculo['modelo']!.toLowerCase().contains(query.toLowerCase()) ||
                veiculo['placa']!.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
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
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => _filtrarVeiculos(value),
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
              itemCount: veiculosFiltrados.length,
              itemBuilder: (context, index) {
                final veiculo =
                    veiculosFiltrados[index]; // Pega o veículo atual pelo índice

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
                      // Ícone azul do carro (como no protótipo)
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
                              veiculo['modelo']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              veiculo['placa']!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              veiculo['proprietario']!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botão de editar (ícone do lápis azul)
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF2B5CB3),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerfilCliente(),
                            ),
                          );
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
