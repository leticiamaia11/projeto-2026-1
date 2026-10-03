import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'veículo_controller.dart';
import '../models/registroServico.dart';
import '../models/gasto.dart';

class ServicoController extends ChangeNotifier {
  final VeiculoController veiculoController;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // LISTAS PRINCIPAIS
  // ============================================================

  // Todos os serviços registrados no banco.
  List<RegistroServico> historicoGlobal = [];

  // Todos os gastos registrados no banco.
  List<Gasto> listaDeGastos = [];

  // Guarda o último erro ocorrido.
  String? ultimoErro;

  // Indica se os dados estão sendo carregados.
  bool carregando = false;

  ServicoController({
    required this.veiculoController,
  });

  // ============================================================
  // BUSCAR SERVIÇOS E GASTOS
  // ============================================================

  Future<void> buscarDadosParaRelatorio() async {
    carregando = true;
    ultimoErro = null;

    notifyListeners();

    try {
      // ----------------------------------------------------------
      // BUSCA OS SERVIÇOS
      // ----------------------------------------------------------

      final dadosServicos = await _supabase
          .from('registro_servicos')
          .select()
          .order('data', ascending: false);

      historicoGlobal = (dadosServicos as List)
          .map(
            (item) => RegistroServico.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      // ----------------------------------------------------------
      // BUSCA OS GASTOS
      // ----------------------------------------------------------

      final dadosGastos = await _supabase
          .from('gasto')
          .select()
          .order('data', ascending: false);

      listaDeGastos = (dadosGastos as List)
          .map(
            (item) => Gasto.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      debugPrint(
        'Serviços encontrados: ${historicoGlobal.length}',
      );

      debugPrint(
        'Gastos encontrados: ${listaDeGastos.length}',
      );
    } catch (e, stackTrace) {
      ultimoErro = e.toString();

      debugPrint(
        'Erro ao buscar dados financeiros: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADICIONAR SERVIÇO
  // ============================================================

  Future<bool> adicionarServico({
    required String placa,
    required String descricao,
    required double valor,
    required int duracao,
    required DateTime dataServico,
  }) async {
    ultimoErro = null;

    try {
      final placaNormalizada = placa.trim().toUpperCase();
      final descricaoNormalizada = descricao.trim();

      // ----------------------------------------------------------
      // VALIDAÇÕES
      // ----------------------------------------------------------

      if (placaNormalizada.isEmpty) {
        ultimoErro = 'A placa não foi informada.';
        return false;
      }

      if (descricaoNormalizada.isEmpty) {
        ultimoErro = 'A descrição não foi informada.';
        return false;
      }

      if (valor <= 0) {
        ultimoErro = 'O valor deve ser maior que zero.';
        return false;
      }

      if (duracao <= 0) {
        ultimoErro = 'A duração deve ser maior que zero.';
        return false;
      }

      // ----------------------------------------------------------
      // BUSCA O VEÍCULO
      // ----------------------------------------------------------

      final veiculoExistente = await _supabase
          .from('veiculo')
          .select('id, placa')
          .eq('placa', placaNormalizada)
          .maybeSingle();

      if (veiculoExistente == null) {
        ultimoErro =
            'O veículo $placaNormalizada não foi encontrado.';

        return false;
      }

      final idVeiculo =
          veiculoExistente['id']?.toString();

      if (idVeiculo == null || idVeiculo.isEmpty) {
        ultimoErro =
            'O veículo foi encontrado, mas seu ID não foi retornado.';

        return false;
      }

      // ----------------------------------------------------------
      // CRIA O SERVIÇO
      // ----------------------------------------------------------

      final novoServico = RegistroServico(
        descricao: descricaoNormalizada,
        valor: valor,
        placaVeiculo: placaNormalizada,
        duracaoEmHoras: duracao,
        dataInformada: dataServico,
        concluido: true,
        veiculoId: idVeiculo,
      );

      // ----------------------------------------------------------
      // ENVIA PARA O SUPABASE
      // ----------------------------------------------------------

      await _supabase
          .from('registro_servicos')
          .insert(novoServico.toMap());

      // ----------------------------------------------------------
      // ATUALIZA A LISTA LOCAL
      // ----------------------------------------------------------

      historicoGlobal.insert(
        0,
        novoServico,
      );

      notifyListeners();

      debugPrint(
        'Serviço salvo com sucesso.',
      );

      return true;
    } on PostgrestException catch (e) {
      ultimoErro =
          'Código: ${e.code}\n'
          'Mensagem: ${e.message}\n'
          'Detalhes: ${e.details}\n'
          'Hint: ${e.hint}';

      debugPrint(
        'Erro do Supabase ao salvar serviço:\n$ultimoErro',
      );

      return false;
    } catch (e, stackTrace) {
      ultimoErro = e.toString();

      debugPrint(
        'Erro ao salvar serviço: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return false;
    }
  }

  // ============================================================
  // ADICIONAR GASTO
  // ============================================================

  Future<bool> adicionarGasto(Gasto gasto) async {
    ultimoErro = null;

    try {
      await _supabase
          .from('gasto')
          .insert(gasto.toMap());

      listaDeGastos.insert(
        0,
        gasto,
      );

      notifyListeners();

      return true;
    } on PostgrestException catch (e) {
      ultimoErro =
          'Código: ${e.code}\n'
          'Mensagem: ${e.message}\n'
          'Detalhes: ${e.details}';

      debugPrint(
        'Erro ao registrar gasto:\n$ultimoErro',
      );

      return false;
    } catch (e) {
      ultimoErro = e.toString();

      debugPrint(
        'Erro ao registrar gasto: $e',
      );

      return false;
    }
  }

  // ============================================================
  // FATURAMENTO BRUTO
  // ============================================================
  //
  // Como a tabela registro_servicos não possui status,
  // todo serviço registrado é considerado uma entrada financeira.
  //
  double get faturamentoBruto {
    return historicoGlobal.fold(
      0.0,
      (soma, servico) => soma + servico.valor,
    );
  }

  // ============================================================
  // IMPOSTO ISS
  // ============================================================

  double get totalImpostoIss {
    return faturamentoBruto * 0.06;
  }

  // ============================================================
  // RECEITA LÍQUIDA
  // ============================================================

  double get receitaLiquidaTotal {
    return faturamentoBruto - totalImpostoIss;
  }

  // ============================================================
  // DESPESAS
  // ============================================================

  double get totalDespesasPagas {
    return listaDeGastos.fold(
      0.0,
      (soma, gasto) => soma + gasto.valor,
    );
  }

  // ============================================================
  // LUCRO LÍQUIDO
  // ============================================================

  double get lucroLiquidoReal {
    return receitaLiquidaTotal - totalDespesasPagas;
  }

  // ============================================================
  // SALDO ATUAL
  // ============================================================

  double get saldoAtualReal {
    return faturamentoBruto - totalDespesasPagas;
  }
}