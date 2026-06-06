class RegistroServico {
  int? id;
  String descricao;
  double valor;
  DateTime data;
  String placaVeiculo;
  bool concluido;
  int duracaoEmHoras;

  RegistroServico({
    this.id,
    required this.descricao,
    required this.valor,
    required this.placaVeiculo,
    required this.duracaoEmHoras,
    this.concluido = false,
    DateTime? dataInformada,
  }) : data = dataInformada ?? DateTime.now();
  
  DateTime get horarioTermino => data.add(Duration(hours: duracaoEmHoras));

  factory RegistroServico.fromMap(Map<String, dynamic> map) {
    return RegistroServico(
      id: map['id'],
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num? ?? 0.0).toDouble(),
      dataInformada: map['data_servico'] != null ? DateTime.parse(map['data_servico']) : null,
      placaVeiculo: map['placa_veiculo'] ?? '',
      duracaoEmHoras: map['duracao_horas'] ?? 0,
      concluido: map['concluido'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao': descricao,
      'valor': valor,
      'data_servico': data.toIso8601String(),
      'placa_veiculo': placaVeiculo,
      'duracao_horas': duracaoEmHoras,
      'concluido': concluido,
    };
  }
}