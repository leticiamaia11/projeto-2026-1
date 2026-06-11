import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projeto_integrador/models/agendamento.dart';

class CalendarioController {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<AgendamentoModel> agendamentosDoDiaSelecionado = [];

  Future<void> carregarAgendamentosDoBanco(DateTime dataFiltrada) async {
    try {
      final DateTime inicioDia = DateTime(dataFiltrada.year, dataFiltrada.month, dataFiltrada.day, 0, 0, 0);
      final DateTime fimDia = DateTime(dataFiltrada.year, dataFiltrada.month, dataFiltrada.day, 23, 59, 59);

      // 🟢 CORREÇÃO: Filtrando pela coluna real 'data' indicada no seu print
      final dadosBrutos = await _supabase
          .from('agendamentos')
          .select()
          .gte('data', inicioDia.toIso8601String())
          .lte('data', fimDia.toIso8601String());

      agendamentosDoDiaSelecionado = List<Map<String, dynamic>>.from(dadosBrutos)
          .map((map) => AgendamentoModel.fromMap(map))
          .toList();

      // Ordena por horário de início
      agendamentosDoDiaSelecionado.sort((a, b) {
        final aMinutos = a.inicio.hour * 60 + a.inicio.minute;
        final bMinutos = b.inicio.hour * 60 + b.inicio.minute;
        return aMinutos.compareTo(bMinutos);
      });
    } catch (e) {
      debugPrint("Erro ao carregar os agendamentos do dia: $e");
      agendamentosDoDiaSelecionado = [];
    }
  }

  Future<bool> deletarAgendamentoDoBanco(AgendamentoModel agendamento) async {
    try {
      await _supabase
          .from('agendamentos')
          .delete()
          .eq('id', agendamento.id); 
      
      agendamentosDoDiaSelecionado.removeWhere((item) => item.id == agendamento.id);
      return true;
    } catch (e) {
      debugPrint("Erro ao excluir agendamento: $e");
      return false;
    }
  }
}