import 'package:flutter/material.dart';
import 'package:projeto_integrador/models/agendamento.dart';
// IMPORTANTE: Conexão real com o Supabase configurada
import 'package:supabase_flutter/supabase_flutter.dart'; 

class AgendamentoController {
  // Instancia o cliente do Supabase para conexão com a nuvem
  final _supabase = Supabase.instance.client;

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

      // 2. Chame o método do seu banco de dados aqui.
      // CORREÇÃO: Consulta real no Supabase para verificar se já existe agendamento na mesma data e com sobreposição de horário
      final resultados = await _supabase
          .from('agendamentos')
          .select()
          .eq('data', dataStr)
          .lt('inicio', fimStr)
          .gt('fim', inicioStr);

      return resultados.isNotEmpty;
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
      // CORREÇÃO: Busca real baseada na coluna 'cliente' da sua tabela agendamentos
      final resultados = await _supabase
          .from('agendamentos')
          .select()
          .eq('cliente', nome);

      return resultados.isNotEmpty; 
    } catch (e) {
      debugPrint("Erro ao verificar agendamentos do cliente: $e");
      return false;
    }
  }

  // Envia o objeto estruturado direto para a persistência do banco de dados
  Future<bool> salvarNoBancoDeDados() async {
    try {
      // 1. Formata os horários e data para texto compatível com o PostgreSQL do Supabase
      String inicioStr = '${horaInicioReal!.hour.toString().padLeft(2, '0')}:${horaInicioReal!.minute.toString().padLeft(2, '0')}';
      String fimStr = '${horaFimReal!.hour.toString().padLeft(2, '0')}:${horaFimReal!.minute.toString().padLeft(2, '0')}';
      String dataStr = dataReal!.toIso8601String().split('T')[0];

      // CORREÇÃO: Ajustado o mapa de inserção para conter EXATAMENTE as colunas da sua tabela 'agendamentos' do print
      await _supabase.from('agendamentos').insert({
        'servico': servicoController.text,
        'descricao': descricaoController.text,
        'data': dataStr,
        'inicio': inicioStr,
        'fim': fimStr,
        'cliente': clienteSelecionadoCompleto!['nome']!, // Coluna 'cliente' do tipo text no banco
      });
      
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