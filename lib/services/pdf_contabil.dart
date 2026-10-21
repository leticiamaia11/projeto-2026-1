import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/registroServico.dart';
import '../models/gasto.dart';

class PdfContabil {
  static String _dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _data(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  static Future<void> gerarRelatorioContabil({
    required String periodo,
    required List<RegistroServico> servicos,
    required List<Gasto> gastos,
    required double receitaBruta,
    required double impostos,
    required double receitaLiquida,
    required double despesas,
    required double lucroLiquido,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EngeTec',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 4),

              pw.Text(
                'Módulo Contábil',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Divider(),
            ],
          );
        },

        footer: (context) {
          return pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'EngeTec - Relatório Contábil',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),

              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },

        build: (context) {
          return [
            pw.Text(
              'Relatório Contábil',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              'Período: $periodo',
              style: const pw.TextStyle(
                fontSize: 11,
              ),
            ),

            pw.Text(
              'Gerado em: ${_data(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),

            pw.SizedBox(height: 20),

            // =====================================================
            // RESUMO DA DRE
            // =====================================================

            pw.Text(
              'Resumo Contábil',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _linhaResumo(
                  '(+) Receita Bruta (Serviços)',
                  _dinheiro(receitaBruta),
                  PdfColors.green800,
                ),

                _linhaResumo(
                  '(-) Impostos Fiscais (ISS - 6%)',
                  _dinheiro(impostos),
                  PdfColors.red700,
                ),

                _linhaResumo(
                  '(=) Receita Líquida',
                  _dinheiro(receitaLiquida),
                  PdfColors.blue900,
                ),

                _linhaResumo(
                  '(-) Despesas Operacionais',
                  _dinheiro(despesas),
                  PdfColors.red700,
                ),

                _linhaResumo(
                  lucroLiquido >= 0
                      ? '(=) LUCRO LÍQUIDO'
                      : '(=) PREJUÍZO LÍQUIDO',
                  _dinheiro(lucroLiquido),
                  lucroLiquido >= 0
                      ? PdfColors.green900
                      : PdfColors.red900,
                  destaque: true,
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // =====================================================
            // ENTRADAS
            // =====================================================

            pw.Text(
              'Entradas - Serviços',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            if (servicos.isEmpty)
              pw.Text(
                'Nenhum serviço registrado no período.',
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                ),
              )
            else
              pw.Table.fromTextArray(
                headers: [
                  'Data',
                  'Descrição',
                  'Placa',
                  'Valor',
                ],
                data: servicos.map((servico) {
                  return [
                    _data(servico.data),
                    servico.descricao,
                    servico.placaVeiculo,
                    _dinheiro(servico.valor),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
              ),

            pw.SizedBox(height: 30),

            // =====================================================
            // SAÍDAS
            // =====================================================

            pw.Text(
              'Saídas - Despesas',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            if (gastos.isEmpty)
              pw.Text(
                'Nenhuma despesa registrada no período.',
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                ),
              )
            else
              pw.Table.fromTextArray(
                headers: [
                  'Data',
                  'Descrição',
                  'Valor',
                ],
                data: gastos.map((gasto) {
                  return [
                    _data(gasto.data),
                    gasto.descricao,
                    _dinheiro(gasto.valor),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.red800,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
              ),

            pw.SizedBox(height: 30),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lucroLiquido >= 0
                    ? PdfColors.green50
                    : PdfColors.red50,
                border: pw.Border.all(
                  color: lucroLiquido >= 0
                      ? PdfColors.green300
                      : PdfColors.red300,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    lucroLiquido >= 0
                        ? 'Resultado do período'
                        : 'Resultado negativo do período',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _dinheiro(lucroLiquido),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: lucroLiquido >= 0
                          ? PdfColors.green900
                          : PdfColors.red900,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'relatorio_contabil_${periodo.toLowerCase()}.pdf',
    );
  }

  static pw.TableRow _linhaResumo(
    String titulo,
    String valor,
    PdfColor cor, {
    bool destaque = false,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: destaque ? 11 : 10,
              fontWeight: destaque
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: destaque ? 11 : 10,
              fontWeight: destaque
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: cor,
            ),
          ),
        ),
      ],
    );
  }
}