import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/models/registroServico.dart';
import 'package:projeto_integrador/models/gasto.dart';

class TelaDRE extends StatefulWidget {
  final ServicoController servicoController;

  const TelaDRE({
    super.key,
    required this.servicoController,
  });

  @override
  State<TelaDRE> createState() => _TelaDREState();
}

class _TelaDREState extends State<TelaDRE> {
  String _periodoSelecionado = 'Mensal';

  @override
  void initState() {
    super.initState();

    // Garante que os dados mais recentes sejam carregados
    // quando a tela do DRE for aberta.
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await widget.servicoController.buscarDadosParaRelatorio();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // FILTRA SERVIÇOS PELO PERÍODO
  // ============================================================

  List<RegistroServico> _servicosDoPeriodo() {
    final agora = DateTime.now();

    final inicioHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    return widget.servicoController.historicoGlobal
        .where((servico) {
      final data = DateTime(
        servico.data.year,
        servico.data.month,
        servico.data.day,
      );

      // ----------------------------------------------------------
      // DIÁRIO
      // ----------------------------------------------------------

      if (_periodoSelecionado == 'Diário') {
        return data == inicioHoje;
      }

      // ----------------------------------------------------------
      // QUINZENAL
      // ----------------------------------------------------------

      if (_periodoSelecionado == 'Quinzenal') {
        final inicio = inicioHoje.subtract(
          const Duration(days: 14),
        );

        return !data.isBefore(inicio) &&
            !data.isAfter(inicioHoje);
      }

      // ----------------------------------------------------------
      // MENSAL
      // ----------------------------------------------------------

      return data.year == agora.year &&
          data.month == agora.month;
    }).toList();
  }

  // ============================================================
  // FILTRA GASTOS PELO PERÍODO
  // ============================================================

  List<Gasto> _gastosDoPeriodo() {
    final agora = DateTime.now();

    final inicioHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    return widget.servicoController.listaDeGastos
        .where((gasto) {
      final data = DateTime(
        gasto.data.year,
        gasto.data.month,
        gasto.data.day,
      );

      if (_periodoSelecionado == 'Diário') {
        return data == inicioHoje;
      }

      if (_periodoSelecionado == 'Quinzenal') {
        final inicio = inicioHoje.subtract(
          const Duration(days: 14),
        );

        return !data.isBefore(inicio) &&
            !data.isAfter(inicioHoje);
      }

      return data.year == agora.year &&
          data.month == agora.month;
    }).toList();
  }

  // ============================================================
  // FORMATA DINHEIRO
  // ============================================================

  String _dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // LINHA DO DRE
  // ============================================================

  Widget _buildLinhaDRE({
    required String titulo,
    required double valor,
    required Color corTexto,
    bool isBold = false,
    double tamanhoFonte = 15,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: tamanhoFonte,
              fontWeight: isBold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _dinheiro(valor),
          style: TextStyle(
            fontSize: tamanhoFonte,
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.w600,
            color: corTexto,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Busca os dados de acordo com o período selecionado.
    final servicos = _servicosDoPeriodo();
    final gastos = _gastosDoPeriodo();

    // ----------------------------------------------------------
    // RECEITA BRUTA
    // ----------------------------------------------------------

    final receitaBruta = servicos.fold<double>(
      0.0,
      (soma, servico) => soma + servico.valor,
    );

    // ----------------------------------------------------------
    // ISS
    // ----------------------------------------------------------
    //
    // Mantemos a alíquota de 6% que já estava sendo utilizada
    // no projeto.
    //

    final impostos = receitaBruta * 0.06;

    // ----------------------------------------------------------
    // RECEITA LÍQUIDA
    // ----------------------------------------------------------

    final receitaLiquida =
        receitaBruta - impostos;

    // ----------------------------------------------------------
    // DESPESAS
    // ----------------------------------------------------------

    final despesas = gastos.fold<double>(
      0.0,
      (soma, gasto) => soma + gasto.valor,
    );

    // ----------------------------------------------------------
    // LUCRO LÍQUIDO
    // ----------------------------------------------------------

    final lucroLiquido =
        receitaLiquida - despesas;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF9FAFC),

      appBar: AppBar(
        centerTitle: true,

        title: const Text(
          'DRE Simples',
          style: TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1E40AF),
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _carregarDados,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              const Text(
                'Demonstrativo do Resultado do Exercício',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color: Colors.black54,
                ),
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FILTRO DE PERÍODO
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child:
                    DropdownButtonHideUnderline(
                  child:
                      DropdownButton<String>(
                    value:
                        _periodoSelecionado,

                    isExpanded: true,

                    items: const [
                      DropdownMenuItem(
                        value: 'Diário',
                        child:
                            Text('Diário'),
                      ),
                      DropdownMenuItem(
                        value: 'Quinzenal',
                        child:
                            Text('Quinzenal'),
                      ),
                      DropdownMenuItem(
                        value: 'Mensal',
                        child:
                            Text('Mensal'),
                      ),
                    ],

                    onChanged:
                        (valor) {
                      if (valor == null) {
                        return;
                      }

                      setState(() {
                        _periodoSelecionado =
                            valor;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CARD PRINCIPAL
              // ==================================================

              Card(
                elevation: 2,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      _buildLinhaDRE(
                        titulo:
                            '(+) Receita Bruta (Serviços)',
                        valor:
                            receitaBruta,
                        corTexto:
                            Colors.green[800]!,
                        isBold: true,
                      ),

                      const Divider(
                        height: 24,
                      ),

                      _buildLinhaDRE(
                        titulo:
                            '(-) Impostos Fiscais (ISS - 6%)',
                        valor:
                            impostos,
                        corTexto:
                            Colors.red[700]!,
                      ),

                      const Divider(
                        height: 24,
                      ),

                      _buildLinhaDRE(
                        titulo:
                            '(=) Receita Líquida',
                        valor:
                            receitaLiquida,
                        corTexto:
                            Colors.blue[900]!,
                        isBold: true,
                      ),

                      const Divider(
                        height: 24,
                      ),

                      _buildLinhaDRE(
                        titulo:
                            '(-) Despesas Operacionais',
                        valor:
                            despesas,
                        corTexto:
                            Colors.red[700]!,
                      ),

                      const Divider(
                        height: 32,
                        thickness: 1.5,
                      ),

                      _buildLinhaDRE(
                        titulo: lucroLiquido >= 0
                            ? '(=) LUCRO LÍQUIDO'
                            : '(=) PREJUÍZO LÍQUIDO',
                        valor:
                            lucroLiquido,
                        corTexto:
                            lucroLiquido >= 0
                                ? Colors.green[900]!
                                : Colors.red[900]!,
                        isBold: true,
                        tamanhoFonte: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // INFORMAÇÃO
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(14),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEFF6FF),

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          Color(0xFF1E40AF),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Os ganhos são calculados a partir dos serviços registrados no período selecionado. As despesas são obtidas dos gastos registrados no mesmo período.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}