class RegistroServico {
  String? id; 
  String descricao;
  double valor;
  DateTime data;
  String placaVeiculo;
  bool concluido;
  int duracaoEmHoras;
  String? veiculoId; 
  RegistroServico({
    this.id,
    required this.descricao,
    required this.valor,
    required this.placaVeiculo,
    required this.duracaoEmHoras,
    this.concluido = false,
    this.veiculoId,
    DateTime? dataInformada,
  }) : data = dataInformada ?? DateTime.now();
  
  DateTime get horarioTermino => data.add(Duration(hours: duracaoEmHoras));

  factory RegistroServico.fromMap(Map<String, dynamic> map) {
    return RegistroServico(
      id: map['id'],
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num? ?? 0.0).toDouble(),
      // Mapeando a coluna 'data' do banco:
      dataInformada: map['data'] != null ? DateTime.parse(map['data']) : null,
      // Mapeando as colunas exatamente como estão na imagem do banco:
      placaVeiculo: map['placaveiculo'] ?? '',
      duracaoEmHoras: map['duracaoemhoras'] ?? 0,
      concluido: map['concluido'] ?? false,
      veiculoId: map['veiculo_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(), 
      'placaveiculo': placaVeiculo,   
      'duracaoemhoras': duracaoEmHoras, 
      'concluido': concluido,
      if (veiculoId != null) 'veiculo_id': veiculoId, 
    };
  }
}