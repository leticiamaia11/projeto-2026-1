class RegistroServico {
  String descricao;
  DateTime data;
  double valor;
  String palacaVeiculo;
  bool concluido;
  int duracaoEmHoras;

  RegistroServico({
    required this.descricao,
    required this.valor,
    required this.palacaVeiculo,
    required this.duracaoEmHoras,
    this.concluido = false,
    DateTime? dataInformada,
  }) : data = dataInformada ?? DateTime.now();
  DateTime get horarioTermino => data.add(Duration(hours: duracaoEmHoras));
}
