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
      final clienteId = cliente['id'].toString(); // Garantindo que o ID seja uma string
      if (clienteId == null) {
        debugPrint("ERRO: O ID do cliente está nulo!");
        return;
      }

      // 1. Busca os veículos
      final respostaVeiculos = await _supabase
          .from('veiculo')
          .select()
          .eq('cliente_id', clienteId);

      veiculosDoCliente = List<Map<String, dynamic>>.from(respostaVeiculos);
      debugPrint("Veículos carregados: ${veiculosDoCliente.length}");

      // 2. Busca serviços de forma segura
      if (veiculosDoCliente.isNotEmpty) {
        // Conversão segura: aceita tanto int quanto string convertida para int
        final List<int> idsVeiculos = veiculosDoCliente
            .map<int>((v) => int.tryParse(v['id'].toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
        
        debugPrint("Buscando serviços para os IDs: $idsVeiculos");

        final respostaServicos = await _supabase
            .from('registro_servicos')
            .select()
            .inFilter('veiculo_id', idsVeiculos);

        servicosDoVeiculo = List<Map<String, dynamic>>.from(respostaServicos);
        debugPrint("Serviços carregados: ${servicosDoVeiculo.length}");
      } else {
        servicosDoVeiculo.clear();
      }
    } catch (e) {
      debugPrint("ERRO NO SUPABASE: $e");
    }
  }

  // DELEÇÃO REAL NO SUPABASE: Remove a linha do banco usando a chave primária
  Future<bool> deletarVeiculoDoBanco(Map<String, dynamic> veiculo) async {
    try {
      final veiculoId = veiculo['id'];
      if (veiculoId == null) return false;

      // Executa o DELETE na tabela do Supabase
      await _supabase
          .from('veiculo')
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