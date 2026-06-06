import 'package:flutter/material.dart';

class AgendamentoModel {
  final String servico;
  final String descricao;
  final DateTime data;
  final TimeOfDay inicio;
  final TimeOfDay fim;
  final String clienteNome;
  final String veiculoInfo;

  AgendamentoModel({
    required this.servico,
    required this.descricao,
    required this.data,
    required this.inicio,
    required this.fim,
    required this.clienteNome,
    required this.veiculoInfo,
  });

  // Facilita para salvar direto no Supabase
  Map<String, dynamic> toMap() {
    return {
      'servico': servico,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'inicio': '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}',
      'fim': '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}',
      'cliente_nome': clienteNome,
      'veiculo_info': veiculoInfo,
    };
  }
}