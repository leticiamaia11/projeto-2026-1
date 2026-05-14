import 'package:projeto_integrador/models/registro_servico.dart';

class Veiculo {
  String modelo;
  String placa;
  int? ano;
  String? cor;
  String proprietario;
  String? observacoes;
  //Os strings que possuem "?" não são obrigatórios
  List<RegistroServico> historicoServicos;
  //Construtor (regra para criar um veículo novo)
  Veiculo({
    required this.modelo,
    required this.placa,
    this.ano,
    this.cor,
    required this.proprietario,
    this.observacoes,
    List<RegistroServico>? historico,
  }) : historicoServicos = historico ?? [];
}