import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/view/saida_financeira.dart';
import 'package:projeto_integrador/view/servicos.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import '../models/registroServico.dart';
import '../models/gasto.dart';
import '../services/pdf_financeiro.dart';

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
  // Aba que está sendo exibida atualmente.
  String _abaAtual = 'Gastos';

  // Período padrão do relatório.
  String _periodoSelecionado = 'Mensal';

  bool _carregandoDoBanco = false;

  @override
  void initState() {
    super.initState();
    _buscarDadosDoBanco();
  }

  // ============================================================
  // BUSCA OS DADOS ATUALIZADOS DO SUPABASE
  // ============================================================

  Future<void> _buscarDadosDoBanco() async {
    if (mounted) {
      setState(() {
        _carregandoDoBanco = true;
      });
    }

    try {
      await widget.servicoController.buscarDadosParaRelatorio();
    } catch (e) {
      debugPrint(
        'Erro ao buscar dados financeiros: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _carregandoDoBanco = false;
    });
  }

  // ============================================================
  // FILTRO POR PERÍODO
  // ============================================================

  List<dynamic> _filtrarPorPeriodo(List<dynamic> lista) {
    final agora = DateTime.now();

    final inicioHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    return lista.where((item) {
      DateTime? dataItem;

      // ----------------------------------------------------------
      // SERVIÇOS
      // ----------------------------------------------------------

      if (item is RegistroServico) {
        dataItem = item.data;
      }

      // ----------------------------------------------------------
      // GASTOS
      // ----------------------------------------------------------

      else if (item is Gasto) {
        dataItem = item.data;
      }

      // ----------------------------------------------------------
      // COMPATIBILIDADE COM MAP
      // ----------------------------------------------------------

      else if (item is Map) {
        final valorData =
            item['data_gasto'] ?? item['data'];

        if (valorData != null) {
          dataItem = DateTime.tryParse(
            valorData.toString(),
          );
        }
      }

      // Se não houver uma data válida,
      // o registro não entra no relatório.
      if (dataItem == null) {
        return false;
      }

      final dataSomenteDia = DateTime(
        dataItem.year,
        dataItem.month,
        dataItem.day,
      );

      // ----------------------------------------------------------
      // DIÁRIO
      // ----------------------------------------------------------

      if (_periodoSelecionado == 'Diário') {
        return dataSomenteDia == inicioHoje;
      }

      // ----------------------------------------------------------
      // QUINZENAL
      // ----------------------------------------------------------
      // Inclui hoje + os 14 dias anteriores.
      // Total: 15 dias de calendário.
      // ----------------------------------------------------------

      if (_periodoSelecionado == 'Quinzenal') {
        final inicio = inicioHoje.subtract(
          const Duration(days: 14),
        );

        return !dataSomenteDia.isBefore(inicio) &&
            !dataSomenteDia.isAfter(inicioHoje);
      }

      // ----------------------------------------------------------
      // MENSAL
      // ----------------------------------------------------------
      // Considera somente o mês e ano atuais.
      // ----------------------------------------------------------

      return dataItem.year == agora.year &&
          dataItem.month == agora.month;
    }).toList();
  }

  // ============================================================
  // SERVIÇOS DO PERÍODO
  // ============================================================
  //
  // A tabela registro_servicos não possui a coluna "status".
  //
  // Portanto, todo serviço registrado é considerado uma
  // entrada financeira.
  //
  // O único filtro aplicado aos serviços é o período selecionado.
  // ============================================================

  List<RegistroServico> _servicosDoPeriodo() {
    final servicos = _filtrarPorPeriodo(
      widget.servicoController.historicoGlobal,
    );

    return servicos
        .whereType<RegistroServico>()
        .toList();
  }

  // ============================================================
  // GASTOS DO PERÍODO
  // ============================================================
  //
  // Os gastos continuam utilizando o status caso esse campo
  // exista no modelo/tabela de gastos.
  // ============================================================

  List<Gasto> _gastosPagosDoPeriodo() {
    final gastos = _filtrarPorPeriodo(
      widget.servicoController.listaDeGastos,
    );

    return gastos
        .whereType<Gasto>()
        .where(
          (gasto) =>
              gasto.status.trim().toLowerCase() == 'pago',
        )
        .toList();
  }

  // ============================================================
  // EXPORTAÇÃO DO PDF
  // ============================================================

  Future<void> _exportarRelatorioPDF() async {
    // Serviços do período selecionado.
    final servicosFiltrados =
        _servicosDoPeriodo();

    // Gastos do período selecionado.
    final gastosFiltrados =
        _gastosPagosDoPeriodo();

    // ----------------------------------------------------------
    // TOTAL DE ENTRADAS
    // ----------------------------------------------------------
    //
    // Todos os serviços do período representam entradas.
    //

    final totalFaturado =
        servicosFiltrados.fold<double>(
      0.0,
      (soma, servico) => soma + servico.valor,
    );

    // ----------------------------------------------------------
    // TOTAL DE SAÍDAS
    // ----------------------------------------------------------

    final totalGastos =
        gastosFiltrados.fold<double>(
      0.0,
      (soma, gasto) => soma + gasto.valor,
    );

    // ----------------------------------------------------------
    // CONFIRMAÇÃO
    // ----------------------------------------------------------

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: Color(0xFF1E40AF),
            ),
            SizedBox(width: 10),
            Text('Exportar Relatório'),
          ],
        ),
        content: Text(
          'Deseja gerar o relatório '
          '$_periodoSelecionado em formato PDF?\n\n'
          'Ganhos: R\$ '
          '${totalFaturado.toStringAsFixed(2).replaceAll('.', ',')}\n'
          'Gastos: R\$ '
          '${totalGastos.toStringAsFixed(2).replaceAll('.', ',')}\n'
          'Saldo: R\$ '
          '${(totalFaturado - totalGastos).toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Gerar PDF',
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) {
      return;
    }

    // ----------------------------------------------------------
    // GERA O PDF
    // ----------------------------------------------------------

    try {
      await PdfServiceFinanceiro
          .gerarRelatorioFinanceiro(
        periodo: _periodoSelecionado,
        gastos: gastosFiltrados,
        servicos: servicosFiltrados,
        totalFaturado: totalFaturado,
        totalGastos: totalGastos,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível gerar o PDF: $e',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // CONSTRUÇÃO DA TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // BUSCA OS DADOS DO CONTROLLER
    // ----------------------------------------------------------

    final listaGastosFiltrados =
        _gastosPagosDoPeriodo();

    final listaServicosFiltrados =
        _servicosDoPeriodo();

    // ==========================================================
    // TOTAL DE ENTRADAS
    // ==========================================================
    //
    // Todos os serviços do período são considerados entradas.
    //
    // Não existe mais verificação de status para serviços.
    // ==========================================================

    final double totalFaturado =
        listaServicosFiltrados.fold<double>(
      0.0,
      (soma, servico) =>
          soma + servico.valor,
    );

    // ==========================================================
    // TOTAL DE SAÍDAS
    // ==========================================================

    final double totalGastos =
        listaGastosFiltrados.fold<double>(
      0.0,
      (soma, gasto) =>
          soma + gasto.valor,
    );

    // ==========================================================
    // BALANÇO
    // ==========================================================

    final double balancoTotal =
        totalFaturado - totalGastos;

    // ==========================================================
    // LISTA EXIBIDA
    // ==========================================================

    final List<dynamic> listaExibida =
        _abaAtual == 'Gastos'
            ? listaGastosFiltrados
            : listaServicosFiltrados;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF9FAFC),

      body: _carregandoDoBanco
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                // ==================================================
                // CABEÇALHO AZUL
                // ==================================================

                Container(
                  width: double.infinity,

                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFF1E40AF),
                  ),

                  padding:
                      const EdgeInsets.only(
                    top: 40,
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // ------------------------------------------------
                      // TÍTULO
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          IconButton(
                            icon:
                                const Icon(
                              Icons
                                  .arrow_back_ios,
                              color:
                                  Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.pop(
                              context,
                            ),
                          ),

                          const Text(
                            'Relatório',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 24,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          IconButton(
                            icon:
                                const Icon(
                              Icons.download,
                              color:
                                  Colors.white,
                            ),
                            onPressed:
                                _exportarRelatorioPDF,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ------------------------------------------------
                      // PERÍODO
                      // ------------------------------------------------

                      Text(
                        'Balanço $_periodoSelecionado',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      // ------------------------------------------------
                      // BALANÇO
                      // ------------------------------------------------

                      Text(
                        'R\$ ${balancoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 32,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      // ------------------------------------------------
                      // AVISO DE SALDO NEGATIVO
                      // ------------------------------------------------

                      if (balancoTotal < 0) ...[
                        const SizedBox(
                          height: 8,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .amberAccent
                                .shade700,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .warning_amber_rounded,
                                color:
                                    Colors.white,
                                size: 18,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              const Expanded(
                                child: Text(
                                  'Atenção: Saldo negativo! Deseja registrar uma nova entrada?',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed:
                                    _abrirTelaEntrada,
                                child:
                                    const Text(
                                  'ADICIONAR',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    decoration:
                                        TextDecoration
                                            .underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 16,
                      ),

                      // ------------------------------------------------
                      // ATALHOS
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          _buildBotaoAtalho(
                            label:
                                'Adicionar Saída',
                            icon:
                                Icons.add,
                            onTap:
                                _abrirTelaSaida,
                          ),

                          _buildBotaoAtalho(
                            label:
                                'Adicionar Entrada',
                            icon:
                                Icons.add,
                            onTap:
                                _abrirTelaEntrada,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // ABAS E FILTRO
                // ==================================================

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      Row(
                        children: [
                          _buildTabSelector(
                            'Gastos',
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          _buildTabSelector(
                            'Ganhos',
                          ),
                        ],
                      ),

                      DropdownButton<String>(
                        value:
                            _periodoSelecionado,

                        underline:
                            const SizedBox(),

                        icon:
                            const Icon(
                          Icons
                              .arrow_drop_down,
                          color:
                              Colors.black,
                        ),

                        style:
                            const TextStyle(
                          color:
                              Colors.black,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'Diário',
                            child:
                                Text(
                              'Diário',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Quinzenal',
                            child:
                                Text(
                              'Quinzenal',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Mensal',
                            child:
                                Text(
                              'Mensal',
                            ),
                          ),
                        ],

                        onChanged:
                            (novoValor) {
                          if (novoValor ==
                              null) {
                            return;
                          }

                          setState(() {
                            _periodoSelecionado =
                                novoValor;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // LISTA
                // ==================================================

                Expanded(
                  child:
                      listaExibida.isEmpty
                          ? _buildStateVazioOrientado()
                          : ListView
                              .builder(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    16,
                              ),

                              itemCount:
                                  listaExibida
                                      .length,

                              itemBuilder:
                                  (context,
                                      index) {
                                final item =
                                    listaExibida[
                                        index];

                                final bool
                                    isGasto =
                                    _abaAtual ==
                                        'Gastos';

                                String
                                    descricaoOriginal =
                                    '';

                                double
                                    valorItem =
                                    0.0;

                                DateTime
                                    dataItem =
                                    DateTime
                                        .now();

                                // ------------------------------------
                                // GASTO
                                // ------------------------------------

                                if (isGasto &&
                                    item
                                        is Gasto) {
                                  descricaoOriginal =
                                      item.descricao;

                                  valorItem =
                                      item.valor;

                                  dataItem =
                                      item.data;
                                }

                                // ------------------------------------
                                // SERVIÇO
                                // ------------------------------------

                                else if (item
                                    is RegistroServico) {
                                  descricaoOriginal =
                                      item.descricao;

                                  valorItem =
                                      item.valor;

                                  dataItem =
                                      item.data;
                                }

                                // ------------------------------------
                                // TÍTULO
                                // ------------------------------------

                                final String
                                    titulo =
                                    isGasto
                                        ? descricaoOriginal
                                            .split(
                                              ' - ',
                                            )
                                            .first
                                        : descricaoOriginal;

                                // ------------------------------------
                                // SUBTÍTULO
                                // ------------------------------------

                                final String
                                    subTitulo =
                                    isGasto
                                        ? (
                                            descricaoOriginal
                                                    .contains(
                                              ' - ',
                                            )
                                                ? descricaoOriginal
                                                    .split(
                                                      ' - ',
                                                    )
                                                    .last
                                                : ''
                                          )
                                        : 'Serviço Realizado';

                                // ------------------------------------
                                // DATA
                                // ------------------------------------

                                final String
                                    dataFormatada =
                                    '${dataItem.day.toString().padLeft(2, '0')} '
                                    '${_obterNomeMes(dataItem.month)}. '
                                    '${dataItem.year}';

                                return Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom: 12,
                                  ),

                                  padding:
                                      const EdgeInsets
                                          .all(
                                    16,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.white,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .black
                                            .withOpacity(
                                          0.03,
                                        ),
                                        blurRadius:
                                            10,
                                        offset:
                                            const Offset(
                                          0,
                                          4,
                                        ),
                                      ),
                                    ],
                                  ),

                                  child: Row(
                                    children: [
                                      // --------------------------------
                                      // ÍCONE
                                      // --------------------------------

                                      Container(
                                        width: 44,
                                        height: 44,

                                        decoration:
                                            BoxDecoration(
                                          color:
                                              const Color(
                                            0xFFE5E7EB,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),

                                        child:
                                            Icon(
                                          isGasto
                                              ? Icons
                                                  .money_off
                                              : Icons
                                                  .monetization_on,
                                          color:
                                              const Color(
                                            0xFF1E40AF,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 16,
                                      ),

                                      // --------------------------------
                                      // DESCRIÇÃO
                                      // --------------------------------

                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            Text(
                                              titulo,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize:
                                                    15,
                                              ),
                                            ),

                                            const SizedBox(
                                              height:
                                                  2,
                                            ),

                                            Text(
                                              subTitulo,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors
                                                        .grey,
                                                fontSize:
                                                    13,
                                              ),
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // --------------------------------
                                      // VALOR E DATA
                                      // --------------------------------

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .end,

                                        children: [
                                          Text(
                                            '${isGasto ? '- ' : '+ '}'
                                            'R\$ ${valorItem.toStringAsFixed(2).replaceAll('.', ',')}',

                                            style:
                                                TextStyle(
                                              color:
                                                  isGasto
                                                      ? const Color(
                                                          0xFFEF4444,
                                                        )
                                                      : const Color(
                                                          0xFF10B981,
                                                        ),
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  15,
                                            ),
                                          ),

                                          const SizedBox(
                                            height:
                                                4,
                                          ),

                                          Text(
                                            dataFormatada,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .grey,
                                              fontSize:
                                                  11,
                                            ),
                                          ),
                                        ],
                                      ),
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

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildStateVazioOrientado() {
    final bool isGasto =
        _abaAtual == 'Gastos';

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24.0),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              isGasto
                  ? Icons
                      .account_balance_wallet_outlined
                  : Icons
                      .build_circle_outlined,
              size: 64,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              isGasto
                  ? 'Nenhum registro de saída financeira encontrado para este período.'
                  : 'Nenhum serviço encontrado para este período.',
              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 15,
                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed: isGasto
                  ? _abrirTelaSaida
                  : _abrirTelaEntrada,

              icon: const Icon(
                Icons
                    .add_circle_outline,
                color:
                    Color(0xFF1E40AF),
              ),

              label: Text(
                isGasto
                    ? 'Deseja adicionar uma saída?'
                    : 'Adicionar serviço realizado',

                style:
                    const TextStyle(
                  color:
                      Color(0xFF1E40AF),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELETOR DAS ABAS
  // ============================================================

  Widget _buildTabSelector(
    String nomeAba,
  ) {
    final selecionado =
        _abaAtual == nomeAba;

    return GestureDetector(
      onTap: () {
        setState(() {
          _abaAtual = nomeAba;
        });
      },

      child: Text(
        nomeAba,

        style: TextStyle(
          fontSize: 16,

          fontWeight:
              FontWeight.bold,

          color: selecionado
              ? const Color(
                  0xFF1E40AF,
                )
              : Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO DE ATALHO
  // ============================================================

  Widget _buildBotaoAtalho({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(6),

            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),

            child: Icon(
              icon,
              color:
                  const Color(0xFF1E40AF),
              size: 18,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ABRIR TELA DE SAÍDA
  // ============================================================

  void _abrirTelaSaida() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            TelaSaidaFinanceira(
          servicoController:
              widget.servicoController,
        ),
      ),
    ).then(
      (_) => _buscarDadosDoBanco(),
    );
  }

  // ============================================================
  // ABRIR TELA DE ENTRADA / SERVIÇOS
  // ============================================================

  void _abrirTelaEntrada() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            TelaServicos(
          servicoController:
              widget.servicoController,
        ),
      ),
    ).then(
      (_) => _buscarDadosDoBanco(),
    );
  }

  // ============================================================
  // NOME DOS MESES
  // ============================================================

  String _obterNomeMes(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return meses[mes - 1];
  }
}