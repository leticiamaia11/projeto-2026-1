class NotaFiscal {
  String? id;
  String descricaoServico;
  double valorBruto;
  double aliquotaAplicada;
  double valorImposto;
  DateTime dataEmissao;
  String? registroServicoId; // Adicionado para manter o vínculo com o serviço

  NotaFiscal({
    this.id,
    required this.descricaoServico,
    required this.valorBruto,
    required this.aliquotaAplicada,
    required this.valorImposto,
    DateTime? dataEmissaoInformada,
    this.registroServicoId,
  }) : dataEmissao = dataEmissaoInformada ?? DateTime.now();

  factory NotaFiscal.fromMap(Map<String, dynamic> map) {
    return NotaFiscal(
      id: map['id']?.toString(),
      descricaoServico: map['descricao_servico'] ?? '',
      valorBruto: (map['valor_bruto'] as num? ?? 0.0).toDouble(),
      aliquotaAplicada: (map['aliquota_aplicada'] as num? ?? 0.0).toDouble(),
      valorImposto: (map['valor_imposto'] as num? ?? 0.0).toDouble(),
      dataEmissaoInformada: map['data_emissao'] != null 
          ? DateTime.parse(map['data_emissao']) 
          : null,
      registroServicoId: map['registro_servico_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao_servico': descricaoServico,
      'valor_bruto': valorBruto,
      'aliquota_aplicada': aliquotaAplicada,
      'valor_imposto': valorImposto,
      'data_emissao': dataEmissao.toIso8601String(),
      if (registroServicoId != null && registroServicoId!.isNotEmpty) 
        'registro_servico_id': registroServicoId,
    };
  }
}