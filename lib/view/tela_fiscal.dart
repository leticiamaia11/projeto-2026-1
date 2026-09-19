import 'package:flutter/material.dart';
import '../controllers/fiscal_controller.dart';
import '../controllers/servico_controller.dart';
import '../models/registroServico.dart';

class TelaFiscal extends StatefulWidget {
  final ServicoController servicoController;

  const TelaFiscal({super.key, required this.servicoController});

  @override
  State<TelaFiscal> createState() => _TelaFiscalState();
}

class _TelaFiscalState extends State<TelaFiscal> {
  late final FiscalController _fiscalController;

  @override
  void initState() {
    super.initState();
    _fiscalController = FiscalController(
      servicoController: widget.servicoController,
    );
    _fiscalController.carregarHistoricoNotas();
  }

  @override
  void dispose() {
    _fiscalController.dispose();
    super.dispose();
  }

  void _mostrarDialogEmissao() async {
    // 1. Verifica se há serviços cadastrados antes de abrir o diálogo
    await widget.servicoController.buscarDadosParaRelatorio();

    final servicos = widget.servicoController.historicoGlobal;
    
    if (servicos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum serviço cadastrado para emissão de nota.'),
        ),
      );
      return;
    }

    RegistroServico servicoAtual = servicos.last;
    double impostoCalculado =
        servicoAtual.valor * _fiscalController.aliquotaFixa;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Emitir Nova Nota Fiscal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione o Serviço:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),

                // Dropdown permitindo escolher qualquer serviço cadastrado
                DropdownButton<RegistroServico>(
                  value: servicoAtual,
                  isExpanded: true,
                  items: servicos.map((servico) {
                    return DropdownMenuItem<RegistroServico>(
                      value: servico,
                      child: Text(
                        '${servico.descricao} - R\$ ${servico.valor.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (novoServico) {
                    if (novoServico != null) {
                      setStateDialog(() {
                        servicoAtual = novoServico;
                        impostoCalculado =
                            servicoAtual.valor * _fiscalController.aliquotaFixa;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),
                Text(
                  'Valor Bruto: R\$ ${servicoAtual.valor.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Alíquota Fixa: ${(_fiscalController.aliquotaFixa * 100).toStringAsFixed(0)}%',
                ),
                const Divider(height: 20),
                Text(
                  'Imposto Calculado: R\$ ${impostoCalculado.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                ),
                onPressed: () async {
                  await _fiscalController.emitirNotaParaServico(
                    descricao: servicoAtual.descricao,
                    valorBruto: servicoAtual.valor,
                    registroServicoId:
                        servicoAtual.id, // ID dinâmico do serviço escolhido
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nota fiscal emitida e salva com sucesso!',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Emitir e Salvar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text(
          'Módulo Fiscal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Emitir Nova Nota',
            onPressed: _mostrarDialogEmissao,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fiscalController,
        builder: (context, child) {
          if (_fiscalController.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_fiscalController.erroConexao) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Erro de conexão ao buscar histórico de notas.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                    ),
                    onPressed: () => _fiscalController.carregarHistoricoNotas(),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de Resumo Fiscal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Faturado',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            'R\$ ${_fiscalController.faturamentoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Impostos (${(_fiscalController.aliquotaFixa * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'R\$ ${_fiscalController.impostoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notas Fiscais Emitidas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarDialogEmissao,
                      icon: const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: Color(0xFF1E40AF),
                      ),
                      label: const Text(
                        'Emitir Nota',
                        style: TextStyle(color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lista de Notas Fiscais
                Expanded(
                  child: _fiscalController.notasEmitidas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma nota fiscal emitida até o momento.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _fiscalController.notasEmitidas.length,
                          itemBuilder: (context, index) {
                            final nota = _fiscalController.notasEmitidas[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFEFF6FF),
                                  child: Icon(
                                    Icons.description,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                title: Text(
                                  nota.descricaoServico,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Data: ${nota.dataEmissao.day}/${nota.dataEmissao.month}/${nota.dataEmissao.year} • Imposto: R\$ ${nota.valorImposto.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Baixar novamente',
                                  onPressed: () =>
                                      _fiscalController.baixarNotaFiscal(nota),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
