import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/view/saida_financeira.dart';
import 'package:projeto_integrador/view/servicos.dart'; 
import 'package:projeto_integrador/controllers/veículo_controller.dart'; 

class TelaRelatorio extends StatefulWidget {
  final ServicoController servicoController;
  final VeiculoController veiculoController; // Passado para abrir a tela de serviços por aqui

  const TelaRelatorio({
    super.key,
    required this.servicoController,
    required this.veiculoController,
  });

  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  String _abaAtual = 'Gastos'; // Controla a aba selecionada ('Gastos' ou 'Ganhos')
  String _periodoSelecionado = 'Mensal'; // Filtro padrão: 'Diário', 'Quinzenal', 'Mensal'

  // Estrutura futura para integração com Banco de Dados
  bool _carregandoDoBanco = false;

  @override
  void initState() {
    super.initState();
    _buscarDadosDoBanco();
  }

  // Método preparado para carregar dados de forma assíncrona do banco no futuro
  Future<void> _buscarDadosDoBanco() async {
    setState(() {
      _carregandoDoBanco = true;
    });

    // TODO: No futuro, chamar os métodos de fetch do banco de dados aqui:
    // await widget.servicoController.buscarServicosEFechamentoDoBanco();

    setState(() {
      _carregandoDoBanco = false;
    });
  }

  // Filtra as listas locais baseando-se no período selecionado
  List<dynamic> _filtrarPorPeriodo(List<dynamic> lista) {
    final agora = DateTime.now();
    return lista.where((item) {
      final DateTime dataItem = item.data; // Certifique-se de que seus modelos possuem a propriedade 'data'
      final diferencaDias = agora.difference(dataItem).inDays;

      if (_periodoSelecionado == 'Diário') {
        return diferencaDias == 0 && dataItem.day == agora.day;
      } else if (_periodoSelecionado == 'Quinzenal') {
        return diferencaDias <= 15;
      } else {
        // Mensal
        return diferencaDias <= 30;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Pegando as listas brutas do seu controller
    final listaServicosRaw = widget.servicoController.historicoGlobal; // Ganhos
    final listaGastosRaw = widget.servicoController.listaDeGastos; // Gastos (método/lista interna que armazena os gastos)

    // Aplicando filtros de Período
    final listaGastosFiltrados = _filtrarPorPeriodo(listaGastosRaw);
    final listaServicosFiltrados = _filtrarPorPeriodo(listaServicosRaw);

    // Calculando totais com base nos dados filtrados da tela
    double totalFaturado = listaServicosFiltrados.fold(0, (soma, item) => soma + item.valor);
    double totalGastos = listaGastosFiltrados.fold(0, (soma, item) => soma + item.valor);
    double balancoTotal = totalFaturado - totalGastos;

    // Define qual lista exibir de acordo com a aba clicada
    final listaExibida = _abaAtual == 'Gastos' ? listaGastosFiltrados : listaServicosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: _carregandoDoBanco
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Cabeçalho Azul com Balanço e Botões Rápidos
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E40AF), // Azul escuro conforme o mockup
                  ),
                  padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Relatório',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: () {
                              // Exportar relatório (Futuro)
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Balanço Total Atual',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${balancoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botão Adicionar Saída
                          _buildBotaoAtalho(
                            label: 'Adicionar Saída',
                            icon: Icons.add,
                            onTap: () => _abrirTelaSaida(),
                          ),
                          // Botão Adicionar Entrada
                          _buildBotaoAtalho(
                            label: 'Adicionar Entrada',
                            icon: Icons.add,
                            onTap: () => _abrirTelaEntrada(),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // 2. Barra de Seleção de Abas (Gastos / Ganhos) e Filtro de Período
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildTabSelector('Gastos'),
                          const SizedBox(width: 16),
                          _buildTabSelector('Ganhos'),
                        ],
                      ),
                      // Filtro de Período Dropdown
                      DropdownButton<String>(
                        value: _periodoSelecionado,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'Diário', child: Text('Diário ')),
                          DropdownMenuItem(value: 'Quinzenal', child: Text('Quinzenal ')),
                          DropdownMenuItem(value: 'Mensal', child: Text('Mensal ')),
                        ],
                        onChanged: (novoValor) {
                          if (novoValor != null) {
                            setState(() {
                              _periodoSelecionado = novoValor;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Lista Dinâmica de Itens (Cards brancos do design)
                Expanded(
                  child: listaExibida.isEmpty
                      ? Center(child: Text('Nenhum registro encontrado para este período.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: listaExibida.length,
                          itemBuilder: (context, index) {
                            final item = listaExibida[index];

                            // Identifica se é gasto ou serviço para formatar o design
                            final isGasto = _abaAtual == 'Gastos';
                            final String titulo = isGasto ? (item.descricao.split(' - ').first) : 'Serviço';
                            final String subTitulo = isGasto ? (item.descricao.contains(' - ') ? item.descricao.split(' - ').last : '') : item.descricao;
                            final String dataFormatada = "${item.data.day.toString().padLeft(2, '0')} ${_obterNomeMes(item.data.month)}. ${item.data.year}";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Ícone quadrado cinza/azul claro
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.credit_card, color: Color(0xFF1E40AF)),
                                  ),
                                  const SizedBox(width: 16),
                                  // Textos (Título e Descrição)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titulo,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subTitulo,
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Valores e Datas
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${isGasto ? '- ' : '+ '}R\$ ${item.valor.toStringAsFixed(2).replaceAll('.', ',')}",
                                        style: TextStyle(
                                          color: isGasto ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dataFormatada,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Widget auxiliar para as Abas Alternáveis
  Widget _buildTabSelector(String nomeAbas) {
    final selecionado = _abaAtual == nomeAbas;
    return GestureDetector(
      onTap: () {
        setState(() {
          _abaAtual = nomeAbas;
        });
      },
      child: Text(
        nomeAbas,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: selecionado ? const Color(0xFF1E40AF) : Colors.grey,
        ),
      ),
    );
  }

  // Widget auxiliar para os botões do topo (Adicionar Entrada / Saída)
  Widget _buildBotaoAtalho({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _abrirTelaSaida() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaSaidaFinanceira(servicoController: widget.servicoController),
      ),
    ).then((_) => setState(() {}));
  }

  void _abrirTelaEntrada() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaServicos(),
      ),
    ).then((_) => setState(() {}));
  }

  String _obterNomeMes(int mes) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return meses[mes - 1];
  }
}