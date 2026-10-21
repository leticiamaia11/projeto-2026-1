import 'package:flutter/material.dart';

import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/models/registroServico.dart';
import 'package:projeto_integrador/models/gasto.dart';

import '../services/pdf_contabil.dart';
import '../services/excel_contabil.dart';

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
    _carregarDados();
  }

  // ============================================================
  // CARREGAR DADOS
  // ============================================================

  Future<void> _carregarDados() async {
    await widget.servicoController
        .buscarDadosParaRelatorio();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // SERVIÇOS DO PERÍODO
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
  // GASTOS DO PERÍODO
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
  // LINHA DA DRE
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

  // ============================================================
  // MENU DE EXPORTAÇÃO
  // ============================================================

  Future<void> _abrirMenuExportacao() async {
    final servicos = _servicosDoPeriodo();
    final gastos = _gastosDoPeriodo();

    final receitaBruta = servicos.fold<double>(
      0.0,
      (soma, servico) => soma + servico.valor,
    );

    final impostos = receitaBruta * 0.06;

    final receitaLiquida =
        receitaBruta - impostos;

    final despesas = gastos.fold<double>(
      0.0,
      (soma, gasto) => soma + gasto.valor,
    );

    final lucroLiquido =
        receitaLiquida - despesas;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Exportar relatório contábil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Período: $_periodoSelecionado',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PDF
                // =================================================

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red.shade700,
                    ),
                  ),

                  title: const Text(
                    'Exportar para PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: const Text(
                    'Relatório contábil completo',
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                  ),

                  onTap: () {
                    Navigator.pop(context);

                    _exportarPDF(
                      servicos: servicos,
                      gastos: gastos,
                      receitaBruta: receitaBruta,
                      impostos: impostos,
                      receitaLiquida: receitaLiquida,
                      despesas: despesas,
                      lucroLiquido: lucroLiquido,
                    );
                  },
                ),

                const Divider(),

                // =================================================
                // EXCEL
                // =================================================

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.table_chart,
                      color: Colors.green.shade700,
                    ),
                  ),

                  title: const Text(
                    'Exportar para Excel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: const Text(
                    'Resumo, entradas e saídas',
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                  ),

                  onTap: () {
                    Navigator.pop(context);

                    _exportarExcel(
                      servicos: servicos,
                      gastos: gastos,
                      receitaBruta: receitaBruta,
                      impostos: impostos,
                      receitaLiquida: receitaLiquida,
                      despesas: despesas,
                      lucroLiquido: lucroLiquido,
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EXPORTAR PDF
  // ============================================================

  Future<void> _exportarPDF({
    required List<RegistroServico> servicos,
    required List<Gasto> gastos,
    required double receitaBruta,
    required double impostos,
    required double receitaLiquida,
    required double despesas,
    required double lucroLiquido,
  }) async {
    try {
      await PdfContabil.gerarRelatorioContabil(
        periodo: _periodoSelecionado,
        servicos: servicos,
        gastos: gastos,
        receitaBruta: receitaBruta,
        impostos: impostos,
        receitaLiquida: receitaLiquida,
        despesas: despesas,
        lucroLiquido: lucroLiquido,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Relatório PDF gerado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao gerar PDF: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EXPORTAR EXCEL
  // ============================================================

  Future<void> _exportarExcel({
    required List<RegistroServico> servicos,
    required List<Gasto> gastos,
    required double receitaBruta,
    required double impostos,
    required double receitaLiquida,
    required double despesas,
    required double lucroLiquido,
  }) async {
    try {
      await ExcelContabil.gerarRelatorioContabil(
        periodo: _periodoSelecionado,
        servicos: servicos,
        gastos: gastos,
        receitaBruta: receitaBruta,
        impostos: impostos,
        receitaLiquida: receitaLiquida,
        despesas: despesas,
        lucroLiquido: lucroLiquido,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Relatório Excel gerado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao gerar Excel: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final servicos = _servicosDoPeriodo();
    final gastos = _gastosDoPeriodo();

    // ==========================================================
    // RECEITA BRUTA
    // ==========================================================

    final receitaBruta = servicos.fold<double>(
      0.0,
      (soma, servico) => soma + servico.valor,
    );

    // ==========================================================
    // ISS
    // ==========================================================

    final impostos =
        receitaBruta * 0.06;

    // ==========================================================
    // RECEITA LÍQUIDA
    // ==========================================================

    final receitaLiquida =
        receitaBruta - impostos;

    // ==========================================================
    // DESPESAS
    // ==========================================================

    final despesas = gastos.fold<double>(
      0.0,
      (soma, gasto) => soma + gasto.valor,
    );

    // ==========================================================
    // LUCRO LÍQUIDO
    // ==========================================================

    final lucroLiquido =
        receitaLiquida - despesas;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF9FAFC),

      appBar: AppBar(
        centerTitle: true,

        title: const Text(
          'Módulo Contábil',
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

        // ========================================================
        // BOTÃO DE DOWNLOAD
        // ========================================================

        actions: [
          IconButton(
            tooltip: 'Exportar relatório',
            icon: const Icon(
              Icons.download,
              color: Color(0xFF1E40AF),
            ),
            onPressed:
                _abrirMenuExportacao,
          ),
        ],
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
                'Módulo Contábil',
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
              // FILTRO
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
              // CARD DRE
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

              const SizedBox(height: 20),

              // ==================================================
              // BOTÃO VISUAL DE EXPORTAÇÃO
              // ==================================================

              OutlinedButton.icon(
                onPressed:
                    _abrirMenuExportacao,

                icon: const Icon(
                  Icons.download,
                  color: Color(0xFF1E40AF),
                ),

                label: const Text(
                  'Exportar relatório',
                  style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                style:
                    OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  side: const BorderSide(
                    color: Color(0xFF1E40AF),
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}