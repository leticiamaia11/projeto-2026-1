class Gasto {
  int? id;
  String descricao;
  double valor;
  DateTime data;

  Gasto({
    this.id,
    required this.descricao,
    required this.valor,
    DateTime? dataInformada,
  }) : data = dataInformada ?? DateTime.now();

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num? ?? 0.0).toDouble(),
      dataInformada: map['data'] != null ? DateTime.parse(map['data']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
    };
  }
}