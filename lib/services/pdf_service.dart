import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Gera e abre/compartilha o PDF do comprovante ou relatório financeiro
  static Future<void> gerarRelatorioFinanceiro({
    required String periodo,
    required List<dynamic> gastos,
    required List<dynamic> servicos,
    required double totalFaturado,
    required double totalGastos,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ENGETEC - Soluções Automotivas',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('Comprovante Fiscal',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
              
              // Informações do Período/Nota
              pw.Text(periodo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // Tabela de Serviços / Itens
              pw.Text('Detalhes do Faturamento:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              
              pw.Table.fromTextArray(
                context: context,
                headers: ['Descrição', 'Valor (R\$)'],
                data: servicos.map((s) {
                  // Compatibilidade caso seja Objeto ou Map
                  String desc = '';
                  double val = 0.0;
                  if (s is Map) {
                    desc = s['descricao'] ?? '';
                    val = double.tryParse((s['valor'] ?? 0.0).toString()) ?? 0.0;
                  } else {
                    desc = s.descricao ?? '';
                    val = s.valor ?? 0.0;
                  }
                  return [desc, 'R\$ ${val.toStringAsFixed(2)}'];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 30),

              // Rodapé de Totais
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Faturado: R\$ ${totalFaturado.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Abre a tela nativa do sistema para visualizar, salvar ou imprimir o PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Comprovante_Fiscal.pdf',
    );
  }
}