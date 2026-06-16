import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'veículo_controller.dart';
import '../models/registroServico.dart';
import '../models/gasto.dart';

class ServicoController {
  final VeiculoController veiculoController;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Listas fortemente tipadas como objetos (Perfeito para o Relatório)
  List<RegistroServico> historicoGlobal = [];
  List<Gasto> listaDeGastos = []; 

  ServicoController({required this.veiculoController});

  /// Busca e converte os dados do Supabase em Objetos do Modelo
  Future<void> buscarDadosParaRelatorio() async {
    try {
      // 1. Apontando para 'registro_servicos' e ordenando por 'data'
      final dadosServicos = await _supabase
          .from('registro_servicos')
          .select()
          .order('data', ascending: false);

      historicoGlobal = List<Map<String, dynamic>>.from(dadosServicos)
          .map((mapa) => RegistroServico.fromMap(mapa)) 
          .toList();

      // 2. Busca todos os gastos apontando para a tabela 'gasto'
      final dadosGastos = await _supabase
          .from('gasto') 
          .select()
          .order('data', ascending: false);

      listaDeGastos = List<Map<String, dynamic>>.from(dadosGastos)
          .map((mapa) => Gasto.fromMap(mapa))
          .toList();

    } catch (e) {
      debugPrint("Erro ao buscar dados do relatório: $e");
    }
  }

  /// Insere o serviço vinculando o UUID do veículo e usando a tabela 'registro_servicos'
  Future<bool> adicionarServico({
    required String placa,
    required String descricao,
    required double valor,
    required int duracao,
    required DateTime dataServico,
  }) async {
    try {
      // 1. Faz uma busca na tabela veiculo para achar o 'id' (UUID) correspondente à placa
      final veiculoExistente = await _supabase
          .from('veiculo')
          .select('id')
          .eq('placa', placa)
          .maybeSingle();

      if (veiculoExistente == null) {
        debugPrint("Erro: O veículo com a placa $placa não existe no Supabase.");
        return false;
      }

      final String uuidVeiculo = veiculoExistente['id'];

      // 2. Instancia o modelo passando o veiculoId populado
      var novoServico = RegistroServico(
        descricao: descricao,
        valor: valor,
        placaVeiculo: placa,
        duracaoEmHoras: duracao,
        dataInformada: dataServico,
        concluido: true,
        veiculoId: uuidVeiculo,
      );

      // 3. Insere na tabela correta do banco ('registro_servicos')
      await _supabase.from('registro_servicos').insert(novoServico.toMap());
      
      // Atualiza a lista local em memória
      historicoGlobal.insert(0, novoServico);
      return true;
      
    } catch (e) {
      debugPrint("Erro ao registrar serviço no Supabase: $e");
      return false;
    }
  }

  /// 🟢 AJUSTADO: Agora salvando na tabela correta 'gasto' sem renomear a data
  Future<bool> adicionarGasto(Gasto gasto) async {
    try {
      // Converte o objeto para Mapa. Como a tabela se chama 'gasto' e a 
      // coluna é 'data', o toMap() original do seu Gasto já encaixa perfeitamente!
      final mapaGasto = gasto.toMap();

      // Gravando na tabela correta informada na foto: 'gasto'
      await _supabase.from('gasto').insert(mapaGasto);
      
      // Atualiza a lista local em memória inserindo o Objeto completo
      listaDeGastos.add(gasto); 
      return true;
    } catch (e) {
      debugPrint("Erro ao registrar saída financeira no Supabase: $e");
      return false;
    }
  }
}