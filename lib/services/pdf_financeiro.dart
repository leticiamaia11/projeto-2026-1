import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/gasto.dart';
import '../models/registroServico.dart';

class PdfService {
  /// Gera o relatório financeiro real em PDF e abre a janela nativa
  /// de visualização/impressão/compartilhamento do sistema.
  static Future<void> gerarRelatorioFinanceiro({
    required String periodo,
    required List<Gasto> gastos,
    required List<RegistroServico> servicos,
    required double totalFaturado,
    required double totalGastos,
  }) async {
    final pdf = pw.Document();
    final saldo = totalFaturado - totalGastos;

    String dinheiro(double valor) =>
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

    String dataFormatada(DateTime data) =>
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ENGETEC',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Relatório Financeiro',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Período: $periodo'),
            pw.Text('Gerado em: ${dataFormatada(DateTime.now())}'),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.blue900, thickness: 1.5),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Resumo financeiro',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _celula('Ganhos', negrito: true),
                  _celula('Gastos', negrito: true),
                  _celula('Saldo', negrito: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _celula(dinheiro(totalFaturado), cor: PdfColors.green800),
                  _celula(dinheiro(totalGastos), cor: PdfColors.red800),
                  _celula(dinheiro(saldo), cor: saldo >= 0 ? PdfColors.green800 : PdfColors.red800),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Ganhos do período',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (servicos.isEmpty)
            pw.Text('Nenhum ganho registrado neste período.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Data', 'Serviço', 'Placa', 'Valor'],
              data: servicos
                  .map(
                    (servico) => [
                      dataFormatada(servico.data),
                      servico.descricao,
                      servico.placaVeiculo,
                      dinheiro(servico.valor),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Gastos do período',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (gastos.isEmpty)
            pw.Text('Nenhum gasto registrado neste período.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Data', 'Descrição', 'Valor'],
              data: gastos
                  .map(
                    (gasto) => [
                      dataFormatada(gasto.data),
                      gasto.descricao,
                      dinheiro(gasto.valor),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
            ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Saldo do período: ${dinheiro(saldo)}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Financeiro_${periodo.toLowerCase()}.pdf',
    );
  }

  static pw.Widget _celula(
    String texto, {
    bool negrito = false,
    PdfColor? cor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: cor,
        ),
      ),
    );
  }
}