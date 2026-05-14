class Gasto {
  String descricao;
  double valor;
  DateTime data;

  Gasto({required this.descricao, required this.valor, DateTime? dataInformada})
    : data = dataInformada ?? DateTime.now();
}
