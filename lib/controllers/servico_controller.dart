import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'veículo_controller.dart';
import '../models/registroServico.dart';
import '../models/gasto.dart';

class ServicoController {
  final VeiculoController veiculoController;
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🟢 AS DUAS LISTAS QUE A TELA DE RELATÓRIO EXIGE:
  List<RegistroServico> historicoGlobal = [];
  List<Map<String, dynamic>> listaDeGastos = []; // Gastos/Saídas mapeados em tabelas

  ServicoController({required this.veiculoController});

  /// 🟢 NOVO MÉTODO: Busca os dados de Ganhos e Gastos do Supabase para alimentar o Relatório
  Future<void> buscarDadosParaRelatorio() async {
    try {
      // 1. Busca todos os serviços (Ganhos/Entradas)
      final dadosServicos = await _supabase
          .from('servicos')
          .select()
          .order('data_servico', ascending: false);

      // Converte as linhas do banco de volta para objetos do seu modelo RegistroServico
      historicoGlobal = List<Map<String, dynamic>>.from(dadosServicos)
          .map((mapa) => RegistroServico.fromMap(mapa)) // Certifique-se de ter o 'fromMap' no seu modelo
          .toList();

      // 2. Busca todas as saídas financeiras (Gastos/Saídas)
      final dadosGastos = await _supabase
          .from('saidas_financeiras') // Nome fictício da sua tabela de gastos, ajuste se necessário
          .select()
          .order('data_gasto', ascending: false);

      listaDeGastos = List<Map<String, dynamic>>.from(dadosGastos);

    } catch (e) {
      debugPrint("Erro ao buscar dados do relatório: $e");
    }
  }

  // Método para persistir de verdade no banco de dados Supabase
  Future<bool> adicionarServico({
    required String placa,
    required String descricao,
    required double valor,
    required int duracao,
    required DateTime dataServico,
  }) async {
    try {
      final veiculoExistente = await _supabase
          .from('veiculos')
          .select()
          .eq('placa', placa)
          .maybeSingle();

      if (veiculoExistente == null) {
        debugPrint("Erro: O veículo com a placa $placa não existe no Supabase.");
        return false;
      }

      var novoServico = RegistroServico(
        descricao: descricao,
        valor: valor,
        placaVeiculo: placa,
        duracaoEmHoras: duracao,
        dataInformada: dataServico,
        concluido: true,
      );

      await _supabase.from('servicos').insert(novoServico.toMap());
      return true;
      
    } catch (e) {
      debugPrint("Erro ao registrar serviço no Supabase: $e");
      return false;
    }
  }

  Future<bool> adicionarGasto(Gasto gasto) async {
  try {
    // Altere 'saidas_financeiras' para o nome exato da sua tabela de gastos no Supabase
    await _supabase.from('saidas_financeiras').insert(gasto.toMap());
    
    // Atualiza a lista local em memória para que o relatório mude instantaneamente
    listaDeGastos.add(gasto.toMap()); 
    return true;
  } catch (e) {
    debugPrint("Erro ao registrar saída financeira no Supabase: $e");
    return false;
  }
}
}