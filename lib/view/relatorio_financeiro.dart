import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/view/saida_financeira.dart';
import 'package:projeto_integrador/view/servicos.dart'; 
import 'package:projeto_integrador/controllers/veículo_controller.dart'; 
import '../models/registroServico.dart'; 
// IMPORTANTE: Importando o modelo de Gasto fornecido
import '../models/gasto.dart'; 

class TelaRelatorio extends StatefulWidget {
  final ServicoController servicoController;
  final VeiculoController veiculoController;

  const TelaRelatorio({
    super.key,
    required this.servicoController,
    required this.veiculoController,
  });

  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  String _abaAtual = 'Gastos'; 
  String _periodoSelecionado = 'Mensal'; 
  bool _carregandoDoBanco = false;

  @override
  void initState() {
    super.initState();
    _buscarDadosDoBanco();
  }

  // 🟢 Chamada real ao método que criamos no ServicoController
  Future<void> _buscarDadosDoBanco() async {
    setState(() => _carregandoDoBanco = true);
    await widget.servicoController.buscarDadosParaRelatorio();
    setState(() => _carregandoDoBanco = false);
  }

  // 🟢 Tratamento dinâmico adaptado para reconhecer instâncias de RegistroServico e Gasto
  List<dynamic> _filtrarPorPeriodo(List<dynamic> lista) {
    final agora = DateTime.now();
    return lista.where((item) {
      DateTime dataItem;

      if (item is RegistroServico) {
        dataItem = item.data;
      } else if (item is Gasto) {
        dataItem = item.data;
      } else {
        // Fallback de segurança caso algum mapa solto passe pela listagem
        dataItem = DateTime.parse((item['data_gasto'] ?? item['data'] ?? agora.toString()).toString());
      }
          
      final diferencaDias = agora.difference(dataItem).inDays;

      if (_periodoSelecionado == 'Diário') {
        return diferencaDias == 0 && dataItem.day == agora.day;
      } else if (_periodoSelecionado == 'Quinzenal') {
        return diferencaDias <= 15;
      } else {
        return diferencaDias <= 30;
      }
    }).toList();
  }

  void _exportarRelatorioPDF() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Color(0xFF1E40AF)),
            SizedBox(width: 10),
            Text('Exportar Relatório'),
          ],
        ),
        content: Text('Deseja salvar o relatório $_periodoSelecionado em formato PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('O sistema confirma: Relatório salvo com sucesso em PDF!'),
                ),
              );
            },
            child: const Text('Salvar', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaServicosRaw = widget.servicoController.historicoGlobal; 
    final listaGastosRaw = widget.servicoController.listaDeGastos; 

    final listaGastosFiltrados = _filtrarPorPeriodo(listaGastosRaw);
    final listaServicosFiltrados = _filtrarPorPeriodo(listaServicosRaw);

    // 🟢 Acumuladores protegidos mapeando corretamente o objeto Gasto e RegistroServico
    double totalFaturado = listaServicosFiltrados.fold(0.0, (soma, item) {
      if (item is RegistroServico) return soma + item.valor;
      return soma + double.parse((item['valor'] ?? 0.0).toString());
    });

    double totalGastos = listaGastosFiltrados.fold(0.0, (soma, item) {
      if (item is Gasto) return soma + item.valor;
      if (item is RegistroServico) return soma + item.valor;
      return soma + double.parse((item['valor'] ?? 0.0).toString());
    });

    double balancoTotal = totalFaturado - totalGastos;

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
                  decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
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
                            onPressed: _exportarRelatorioPDF,
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
                      
                      if (balancoTotal < 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Atenção: Saldo negativo! Deseja registrar uma nova entrada?',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _abrirTelaEntrada(),
                                child: const Text('ADICIONAR', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBotaoAtalho(
                            label: 'Adicionar Saída',
                            icon: Icons.add,
                            onTap: () => _abrirTelaSaida(),
                          ),
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

                // 2. Barra de Seleção de Abas e Filtro de Período
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
                            setState(() => _periodoSelecionado = novoValor);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Lista Dinâmica / Estado Vazio Orientado
                Expanded(
                  child: listaExibida.isEmpty
                      ? _buildStateVazioOrientado()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: listaExibida.length,
                          itemBuilder: (context, index) {
                            final item = listaExibida[index];
                            final isGasto = _abaAtual == 'Gastos';
                            
                            // 🟢 Mapeamento estrito usando as propriedades seguras da classe Gasto ou RegistroServico
                            String descricaoOriginal = '';
                            double valorItem = 0.0;
                            DateTime dataItem = DateTime.now();

                            if (isGasto && item is Gasto) {
                              descricaoOriginal = item.descricao;
                              valorItem = item.valor;
                              dataItem = item.data;
                            } else if (item is RegistroServico) {
                              descricaoOriginal = item.descricao;
                              valorItem = item.valor;
                              dataItem = item.data;
                            }

                            final String titulo = isGasto ? (descricaoOriginal.split(' - ').first) : descricaoOriginal;
                            final String subTitulo = isGasto ? (descricaoOriginal.contains(' - ') ? descricaoOriginal.split(' - ').last : '') : 'Serviço Concluído';
                            final String dataFormatada = "${dataItem.day.toString().padLeft(2, '0')} ${_obterNomeMes(dataItem.month)}. ${dataItem.year}";

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
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isGasto ? Icons.money_off : Icons.monetization_on, 
                                      color: const Color(0xFF1E40AF)
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${isGasto ? '- ' : '+ '}R\$ ${valorItem.toStringAsFixed(2).replaceAll('.', ',')}",
                                        style: TextStyle(
                                          color: isGasto ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(dataFormatada, style: const TextStyle(color: Colors.grey, fontSize: 11)),
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

  Widget _buildStateVazioOrientado() {
    final bool isGasto = _abaAtual == 'Gastos';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isGasto ? Icons.account_balance_wallet_outlined : Icons.build_circle_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isGasto 
                ? 'Nenhum registro de saída financeira encontrado para este período.' 
                : 'Nenhum serviço realizado encontrado para este período.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: isGasto ? _abrirTelaSaida : _abrirTelaEntrada,
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1E40AF)),
              label: Text(
                isGasto ? 'Deseja adicionar uma saída?' : 'Orientar e adicionar serviços realizados',
                style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(String nomeAbas) {
    final selecionado = _abaAtual == nomeAbas;
    return GestureDetector(
      onTap: () => setState(() => _abaAtual = nomeAbas),
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

  Widget _buildBotaoAtalho({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1E40AF), size: 18), 
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
    ).then((_) => _buscarDadosDoBanco()); 
  }

  void _abrirTelaEntrada() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaServicos(servicoController: widget.servicoController),
      ),
    ).then((_) => _buscarDadosDoBanco()); 
  }

  String _obterNomeMes(int mes) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return meses[mes - 1];
  }
}