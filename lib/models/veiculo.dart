class Veiculo {
  String? id; // UUID do próprio veículo
  String modelo;
  String placa;
  int? ano;
  String? cor;
  String proprietario;
  String? observacoes;
  String? clienteId; // MUDADO PARA String? (UUID do Dono)

  Veiculo({
    this.id,
    required this.modelo,
    required this.placa,
    this.ano,
    this.cor,
    required this.proprietario,
    this.observacoes,
    this.clienteId,
  });

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      id: map['id']?.toString(),
      modelo: map['modelo'] ?? '',
      placa: map['placa'] ?? '',
      ano: map['ano'] != null ? int.tryParse(map['ano'].toString()) : null,
      cor: map['cor'],
      proprietario: map['proprietario'],
      observacoes: map['observacoes'],
      clienteId: map['cliente_id']?.toString(), // Lendo o UUID do dono com segurança
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'modelo': modelo,
      'placa': placa,
      if (ano != null) 'ano': ano,
      if (cor != null) 'cor': cor,
      'proprietario': proprietario,
      if (observacoes != null) 'observacoes': observacoes,
      if (clienteId != null) 'cliente_id': clienteId,
    };
  }
}