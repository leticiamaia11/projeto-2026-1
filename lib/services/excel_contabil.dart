import 'package:excel/excel.dart';

import '../models/registroServico.dart';
import '../models/gasto.dart';

class ExcelContabil {
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
    final excel = Excel.createExcel();

    // ==========================================================
    // ABA RESUMO
    // ==========================================================

    final resumo = excel['Resumo'];

    resumo.appendRow([
      TextCellValue('EngeTec - Módulo Contábil'),
    ]);

    resumo.appendRow([
      TextCellValue('Período'),
      TextCellValue(periodo),
    ]);

    resumo.appendRow([
      TextCellValue('Data de geração'),
      TextCellValue(_data(DateTime.now())),
    ]);

    resumo.appendRow([]);

    resumo.appendRow([
      TextCellValue('Descrição'),
      TextCellValue('Valor'),
    ]);

    resumo.appendRow([
      TextCellValue('Receita Bruta'),
      DoubleCellValue(receitaBruta),
    ]);

    resumo.appendRow([
      TextCellValue('Impostos Fiscais - ISS 6%'),
      DoubleCellValue(impostos),
    ]);

    resumo.appendRow([
      TextCellValue('Receita Líquida'),
      DoubleCellValue(receitaLiquida),
    ]);

    resumo.appendRow([
      TextCellValue('Despesas Operacionais'),
      DoubleCellValue(despesas),
    ]);

    resumo.appendRow([
      TextCellValue(
        lucroLiquido >= 0
            ? 'LUCRO LÍQUIDO'
            : 'PREJUÍZO LÍQUIDO',
      ),
      DoubleCellValue(lucroLiquido),
    ]);

    // ==========================================================
    // ABA ENTRADAS
    // ==========================================================

    final entradas = excel['Entradas'];

    entradas.appendRow([
      TextCellValue('Data'),
      TextCellValue('Descrição'),
      TextCellValue('Placa'),
      TextCellValue('Valor'),
    ]);

    for (final servico in servicos) {
      entradas.appendRow([
        TextCellValue(_data(servico.data)),
        TextCellValue(servico.descricao),
        TextCellValue(servico.placaVeiculo),
        DoubleCellValue(servico.valor),
      ]);
    }

    entradas.appendRow([]);

    entradas.appendRow([
      TextCellValue('TOTAL DE ENTRADAS'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(receitaBruta),
    ]);

    // ==========================================================
    // ABA SAÍDAS
    // ==========================================================

    final saidas = excel['Saídas'];

    saidas.appendRow([
      TextCellValue('Data'),
      TextCellValue('Descrição'),
      TextCellValue('Valor'),
    ]);

    for (final gasto in gastos) {
      saidas.appendRow([
        TextCellValue(_data(gasto.data)),
        TextCellValue(gasto.descricao),
        DoubleCellValue(gasto.valor),
      ]);
    }

    saidas.appendRow([]);

    saidas.appendRow([
      TextCellValue('TOTAL DE SAÍDAS'),
      TextCellValue(''),
      DoubleCellValue(despesas),
    ]);

    // ==========================================================
    // REMOVE A ABA PADRÃO
    // ==========================================================

    if (excel.sheets.containsKey('Sheet1') &&
        excel.sheets.length > 1) {
      excel.delete('Sheet1');
    }

    // ==========================================================
    // GERA E BAIXA O ARQUIVO
    // ==========================================================

    final nomeArquivo =
        'relatorio_contabil_${periodo.toLowerCase()}.xlsx';

    final bytes = excel.save(
      fileName: nomeArquivo,
    );

    if (bytes == null) {
      throw Exception(
        'Não foi possível gerar o arquivo Excel.',
      );
    }
  }
}