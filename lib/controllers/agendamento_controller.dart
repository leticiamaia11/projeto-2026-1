import 'package:flutter/material.dart';
import 'package:projeto_integrador/models/agendamento.dart';
// IMPORTANTE: Importe aqui a classe que gerencia seu banco (ex: BancoService, Supabase, etc.)
// import 'package:projeto_integrador/services/banco_service.dart'; 

class AgendamentoController {
  Map<String, String>? clienteSelecionadoCompleto;
  final formKey = GlobalKey<FormState>();

  final servicoController = TextEditingController();
  final descricaoController = TextEditingController();
  final dataController = TextEditingController();
  final inicioController = TextEditingController();
  final fimController = TextEditingController();

  TimeOfDay? horaInicioReal;
  TimeOfDay? horaFimReal;
  DateTime? dataReal;

  // FLUXO ALTERNATIVO: Agora consulta o banco de dados real para ver se há conflito
  Future<bool> verificarConflitoHorarioNoBanco() async {
    try {
      // 1. Converte o novo horário para o formato padrão do banco (HH:MM)
      String inicioStr = '${horaInicioReal!.hour.toString().padLeft(2, '0')}:${horaInicioReal!.minute.toString().padLeft(2, '0')}';
      String fimStr = '${horaFimReal!.hour.toString().padLeft(2, '0')}:${horaFimReal!.minute.toString().padLeft(2, '0')}';
      String dataStr = dataReal!.toIso8601String().split('T')[0]; // Pega apenas YYYY-MM-DD

      // 2. Chame o método do seu banco de dados aqui. Exemplo simulado:
      // List resultados = await BancoService.buscarAgendamentosPorHorario(dataStr, inicioStr, fimStr);
      // return resultados.isNotEmpty;

      return false; // Altere de acordo com o retorno do seu banco
    } catch (e) {
      debugPrint("Erro ao verificar conflito no banco: $e");
      return false;
    }
  }

  // FLUXO ALTERNATIVO: Verifica no banco se o cliente já tem agendamentos ativos
  Future<bool> clienteJaPossuiAgendamentoNoBanco() async {
    try {
      String nome = clienteSelecionadoCompleto!['nome']!;
      
      // Exemplo de consulta ao banco:
      // List resultados = await BancoService.buscarAgendamentosPorCliente(nome);
      // return resultados.isNotEmpty;

      return false; 
    } catch (e) {
      return false;
    }
  }

  // Envia o objeto estruturado direto para a persistência do banco de dados
  Future<bool> salvarNoBancoDeDados() async {
    try {
      final novoAgendamento = AgendamentoModel(
        servico: servicoController.text,
        descricao: descricaoController.text,
        data: dataReal!,
        inicio: horaInicioReal!,
        fim: horaFimReal!,
        clienteNome: clienteSelecionadoCompleto!['nome']!,
        veiculoInfo: clienteSelecionadoCompleto!['veiculo']!,
      );

      // Converte o Model para Map (JSON) para que o banco aceite facilmente
      Map<String, dynamic> dadosParaSalvar = novoAgendamento.toMap();

      // Exemplo de inserção real:
      // await BancoService.inserir('agendamentos', dadosParaSalvar);
      
      return true; // Retorna true se salvou com sucesso
    } catch (e) {
      debugPrint("Erro ao salvar no banco: $e");
      return false; // Retorna false se deu erro (ex: falta de internet)
    }
  }

  // Lógicas de interface controladas
  void atualizarData(DateTime selectedDate) {
    dataReal = selectedDate;
    dataController.text = "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}";
  }

  bool atualizarHorarioInicio(TimeOfDay horaSelecionada) {
    bool limpouHorarioFim = false;
    if (horaFimReal != null) {
      final inicioMinutos = horaSelecionada.hour * 60 + horaSelecionada.minute;
      final fimMinutos = horaFimReal!.hour * 60 + horaFimReal!.minute;
      if (inicioMinutos >= fimMinutos) {
        horaFimReal = null;
        fimController.clear();
        limpouHorarioFim = true;
      }
    }
    horaInicioReal = horaSelecionada;
    inicioController.text = "${horaSelecionada.hour.toString().padLeft(2, '0')}:${horaSelecionada.minute.toString().padLeft(2, '0')}";
    return limpouHorarioFim;
  }

  bool atualizarHorarioFim(TimeOfDay horaSelecionada) {
    if (horaInicioReal == null) return false;
    final inicioMinutos = horaInicioReal!.hour * 60 + horaInicioReal!.minute;
    final fimMinutos = horaSelecionada.hour * 60 + horaSelecionada.minute;
    if (fimMinutos <= inicioMinutos) return false;

    horaFimReal = horaSelecionada;
    fimController.text = "${horaSelecionada.hour.toString().padLeft(2, '0')}:${horaSelecionada.minute.toString().padLeft(2, '0')}";
    return true;
  }

  void dispose() {
    servicoController.dispose();
    descricaoController.dispose();
    dataController.dispose();
    inicioController.dispose();
    fimController.dispose();
  }
}