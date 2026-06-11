class AgendamentoModel {
  final String id; // UUID no Supabase vira String no Dart
  final DateTime data;
  final DateTime inicio;
  final DateTime fim;
  final String servico;
  final String clienteNome;
  final String descricao;
  final String veiculoInfo; // Campo opcional na view

  AgendamentoModel({
    required this.id,
    required this.data,
    required this.inicio,
    required this.fim,
    required this.servico,
    required this.clienteNome,
    required this.descricao,
    this.veiculoInfo = "Não informado",
  });

  factory AgendamentoModel.fromMap(Map<String, dynamic> mapa) {
    // 1. Parse da data base do agendamento
    DateTime dataBase = mapa['data'] != null 
        ? DateTime.parse(mapa['data']).toLocal() 
        : DateTime.now();

    // Helper interno para juntar a data com a string de hora (ex: "14:30")
    DateTime combinarDataHora(String? horaTexto) {
      if (horaTexto == null || !horaTexto.contains(':')) return dataBase;
      try {
        final partes = horaTexto.split(':');
        final hora = int.parse(partes[0]);
        final minuto = int.parse(partes[1]);
        return DateTime(dataBase.year, dataBase.month, dataBase.day, hora, minuto);
      } catch (_) {
        return dataBase;
      }
    }

    return AgendamentoModel(
      id: mapa['id']?.toString() ?? '',
      data: dataBase,
      // MAPEAMENTO CONFORME O BANCO:
      inicio: combinarDataHora(mapa['inicio']),
      fim: combinarDataHora(mapa['fim']),
      servico: mapa['servico'] ?? '',
      clienteNome: mapa['cliente'] ?? '', // Coluna 'cliente' do print
      descricao: mapa['descricao'] ?? '', // Coluna 'descricao' do print
      veiculoInfo: mapa['veiculo'] ?? 'Não informado', // Caso tenha adicionado um campo de veículo depois
    );
  }
}