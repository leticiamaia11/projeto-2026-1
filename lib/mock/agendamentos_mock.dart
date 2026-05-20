class AgendamentoModel {
  final String servico;
  final String descricao;
  final DateTime data;
  final String inicio;
  final String fim;
  final String cliente;

  AgendamentoModel({
    required this.servico,
    required this.descricao,
    required this.data,
    required this.inicio,
    required this.fim,
    required this.cliente,
  });
}

// Essa lista global vai simular o seu Banco de Dados por enquanto!
List<AgendamentoModel> listaAgendamentosGlobais = [
  AgendamentoModel(
    servico: "Revisão Básica",
    descricao: "Nenhuma Observação.",
    data: DateTime.now(), // Hoje
    inicio: "10:00",
    fim: "12:00",
    cliente: "Letícia",
  ),
];