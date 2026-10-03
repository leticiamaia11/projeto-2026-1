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

  // Retorna o horário estimado de término do serviço.
  DateTime get horarioTermino {
    return data.add(Duration(hours: duracaoEmHoras));
  }

  // ============================================================
  // CONVERTE DADOS DO SUPABASE PARA O OBJETO
  // ============================================================
  factory RegistroServico.fromMap(Map<String, dynamic> map) {
    return RegistroServico(
      id: map['id']?.toString(),

      descricao: map['descricao']?.toString() ?? '',

      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,

      dataInformada: map['data'] != null
          ? DateTime.tryParse(map['data'].toString())
          : null,

      placaVeiculo: map['placaveiculo']?.toString() ?? '',

      duracaoEmHoras:
          int.tryParse(map['duracaoemhoras']?.toString() ?? '') ?? 0,

      concluido: map['concluido'] == true,

      // UUID deve permanecer como String.
      veiculoId: map['veiculo_id']?.toString(),
    );
  }

  // ============================================================
  // CONVERTE O OBJETO PARA O FORMATO DO SUPABASE
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'placaveiculo': placaVeiculo,
      'concluido': concluido,
      'duracaoemhoras': duracaoEmHoras,

      // Só envia se existir.
      if (veiculoId != null && veiculoId!.isNotEmpty)
        'veiculo_id': veiculoId,
    };
  }
}