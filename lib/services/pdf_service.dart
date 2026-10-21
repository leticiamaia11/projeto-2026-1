import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Gera e abre/compartilha o PDF da Nota Fiscal nos moldes da NFS-e
  static Future<void> gerarRelatorioFiscal({
    required String periodo,
    required List<dynamic> servicos,
    required List<dynamic> gastos,
    required double totalFaturado,
    required double totalGastos,
    String numeroNota = '5678',
    String dataEmissao = '30/04/2026', // Garantido com o nome correto
    String prestadorNome = 'ENGETEC - Soluções Automotivas',
    String prestadorCnpj = '00.000.000/0001-00',
    String prestadorEndereco = 'Rua Fictícia, 123, Centro',
    String prestadorInscricaoMunicipal = '123456',
    String tomadorNome = 'Cliente / Tomador do Serviço',
    String tomadorCpfCnpj = '000.000.000-00',
    double aliquotaIss = 6.0,
  }) async {
    final pdf = pw.Document();

    final double valorIss = totalFaturado * (aliquotaIss / 100);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. CABEÇALHO DA PREFEITURA / MUNICÍPIO
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Prefeitura Municipal',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800)),
                    pw.Text('Secretaria da Fazenda',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                    pw.Text('Nota Fiscal de Serviços Eletrônica – NFS-e',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 2. NÚMERO E DATA DA NOTA
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Número: $numeroNota',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Período: $periodo',
                        style: pw.TextStyle(fontSize: 11)),
                    pw.Text('Data: $dataEmissao',
                        style: pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. PRESTADOR DE SERVIÇO
              pw.Text('PRESTADOR DE SERVIÇO',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text('Razão Social/Nome: $prestadorNome', style: const pw.TextStyle(fontSize: 10))),
                        pw.Text('Inscrição Municipal: $prestadorInscricaoMunicipal', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('CNPJ: $prestadorCnpj', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Endereço: $prestadorEndereco', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 4. TOMADOR DO SERVIÇO
              pw.Text('TOMADOR DO SERVIÇO',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Razão Social/Nome: $tomadorNome', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('CPF/CNPJ: $tomadorCpfCnpj', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 5. DISCRIMINAÇÃO DOS SERVIÇOS
              pw.Text('DISCRIMINAÇÃO DOS SERVIÇOS',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Table.fromTextArray(
                          context: context,
                          headers: ['Descrição do Serviço Prestado', 'Valor (R\$)'],
                          data: servicos.map((s) {
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
                          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                          cellStyle: const pw.TextStyle(fontSize: 10),
                          cellAlignments: {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerRight,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // 6. VALORES E IMPOSTOS (TABELA MODELO NFS-e)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor Serviço (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Base de Cálculo (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('% Alíquota (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor ISS (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(totalFaturado.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(totalFaturado.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${aliquotaIss.toStringAsFixed(2)}%', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(valorIss.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor Total (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor ISS Retido (R\$)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Outras Informações', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(totalFaturado.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('0,00', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // 7. RODAPÉ / AUTENTICAÇÃO
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Consultar autenticidade e emissão automática em:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('http://www.engetec.sp.gov.br', style: pw.TextStyle(fontSize: 9, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Emitido em: $dataEmissao', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('R\$ ${totalFaturado.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('ABYCCDEF', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('Documento Autenticado por: engetec.sp.gov.br',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'NotaFiscal_ENGETEC.pdf',
    );
  }
}