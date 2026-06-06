import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilClienteController {
  final Map<String, dynamic> cliente;
  
  // Listas que vão armazenar os dados reais retornados pelo Supabase
  List<Map<String, dynamic>> veiculosDoCliente = [];
  List<Map<String, dynamic>> servicosDoVeiculo = [];

  final SupabaseClient _supabase = Supabase.instance.client;

  PerfilClienteController({required this.cliente});

  // Busca real utilizando os relacionamentos do banco de dados
  Future<void> buscarDadosRelacionados() async {
    try {
      final clienteId = cliente['id'];
      if (clienteId == null) return;

      // 1. Busca os veículos vinculados ao ID deste cliente
      final respostaVeiculos = await _supabase
          .from('veiculos') // Nome da sua tabela de veículos
          .select()
          .eq('cliente_id', clienteId); // Chave estrangeira no banco

      veiculosDoCliente = List<Map<String, dynamic>>.from(respostaVeiculos);

      // 2. Se o cliente tiver pelo menos um veículo, busca o histórico de serviços dele
      if (veiculosDoCliente.isNotEmpty) {
        final veiculoId = veiculosDoCliente[0]['id'];
        
        final respostaServicos = await _supabase
            .from('servicos') // Nome da sua tabela de serviços/histórico
            .select()
            .eq('veiculo_id', veiculoId); // Chave estrangeira no banco

        servicosDoVeiculo = List<Map<String, dynamic>>.from(respostaServicos);
      } else {
        servicosDoVeiculo.clear();
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do Supabase: $e");
      rethrow; // Repassa o erro para a View tratar se necessário
    }
  }

  // DELEÇÃO REAL NO SUPABASE: Remove a linha do banco usando a chave primária
  Future<bool> deletarVeiculoDoBanco(Map<String, dynamic> veiculo) async {
    try {
      final veiculoId = veiculo['id'];
      if (veiculoId == null) return false;

      // Executa o DELETE na tabela do Supabase
      await _supabase
          .from('veiculos')
          .delete()
          .eq('id', veiculoId);
      
      // Se o banco apagou com sucesso, atualiza o estado local limpando as listas
      veiculosDoCliente.removeWhere((v) => v['id'] == veiculoId);
      servicosDoVeiculo.clear(); 
      
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar veículo no Supabase: $e");
      return false;
    }
  }
}