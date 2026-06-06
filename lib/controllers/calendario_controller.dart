import 'package:flutter/material.dart';
import 'package:projeto_integrador/models/agendamento.dart';
// IMPORTANTE: Importe o seu serviço de banco de dados real aqui
// import 'package:projeto_integrador/services/banco_service.dart';

class CalendarioController {
  // Guarda todos os agendamentos baixados do banco para o dia selecionado
  List<AgendamentoModel> agendamentosDoDiaSelecionado = [];

  // Puxa os dados do banco filtrando pelo dia que o usuário clicou no TableCalendar
  Future<void> carregarAgendamentosDoBanco(DateTime dataFiltrada) async {
    try {
      String dataStr = dataFiltrada.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD para o banco

      // CRITÉRIO DE ACEITE: "Quando eu for visualizar um dia, mostra todos os horários cheios"
      // Exemplo de busca real:
      // final dadosBrutos = await BancoService.buscarPorData('agendamentos', dataStr);
      // agendamentosDoDiaSelecionado = dadosBrutos.map((map) => AgendamentoModel.fromMap(map)).toList();

      // NOTA: Ordene a lista por horário de início para ficar organizado na tela
      agendamentosDoDiaSelecionado.sort((a, b) {
        final aMinutos = a.inicio.hour * 60 + a.inicio.minute;
        final bMinutos = b.inicio.hour * 60 + b.inicio.minute;
        return aMinutos.compareTo(bMinutos);
      });
    } catch (e) {
      debugPrint("Erro ao carregar os agendamentos do dia: $e");
    }
  }

  // FLUXO ALTERNATIVO: Solicitação e execução de exclusão no banco de dados
  Future<bool> deletarAgendamentoDoBanco(AgendamentoModel agendamento) async {
    try {
      // Exemplo de exclusão real usando um identificador exclusivo (como ID ou combinação única)
      // await BancoService.deletar('agendamentos', agendamento.id);
      
      // Remove da lista local para atualizar a tela sem precisar recarregar tudo do banco
      agendamentosDoDiaSelecionado.remove(agendamento);
      return true;
    } catch (e) {
      debugPrint("Erro ao excluir agendamento: $e");
      return false;
    }
  }
}