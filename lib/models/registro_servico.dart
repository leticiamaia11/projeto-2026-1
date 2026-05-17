class RegistroServico {
  String descricao;
  DateTime data;
  double valor;
  String placaVeiculo;
  bool concluido;
  int duracaoEmHoras;

  RegistroServico({
    required this.descricao,
    required this.valor,
    required this.placaVeiculo,
    required this.duracaoEmHoras,
    this.concluido = false,
    DateTime? dataInformada,
  }) : data = dataInformada ?? DateTime.now();
  DateTime get horarioTermino => data.add(Duration(hours: duracaoEmHoras));
}
