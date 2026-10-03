class Gasto {
  final String? id;
  final String descricao;
  final double valor;
  final DateTime data;
  final String status;
  bool pago;

  Gasto({
    this.id,
    required this.descricao,
    required this.valor,
    DateTime? dataInformada,
    String? status,
    bool? pago,
  }) : data = dataInformada ?? DateTime.now(),
       // Define o status padrão ou baseia-se na flag 'pago'
       status = status ?? ((pago ?? true) ? 'Pago' : 'Pendente'),
       pago = pago ?? (status == null || status == 'Pago');

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao': descricao,
      'valor': valor,
      'data_gasto': data.toIso8601String(),
      'status': status,
      'pago': pago,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    final String statusLido = map['status']?.toString() ?? 'Pago';
    final bool pagoLido = map['pago'] ?? (statusLido == 'Pago');

    return Gasto(
      id: map['id']?.toString(),
      descricao: map['descricao'] ?? map['titulo'] ?? '',
      valor: double.tryParse(map['valor'].toString()) ?? 0.0,
      dataInformada: map['data_gasto'] != null
          ? DateTime.tryParse(map['data_gasto'].toString()) ?? DateTime.now()
          : (map['data'] != null
                ? DateTime.tryParse(map['data'].toString()) ?? DateTime.now()
                : DateTime.now()),
      status: statusLido,
      pago: pagoLido,
    );
  }
}