import 'package:projeto_integrador/models/registroServico.dart';

class Veiculo {
  // Definindo as caracteristicas (variaveis)
  int? id;
  String modelo;
  String placa;
  int? ano;
  String? cor;
  String proprietario;
  String? observacoes;
  // os string que possuem "?" indicam que não são obrigatórios
  List<RegistroServico> historicoServicos;
  
  // Construtor  (regra para criar um veículo novo)
  Veiculo({
    this.id,
    required this.modelo,
    required this.placa,
    this.ano,
    this.cor,
    required this.proprietario,
    this.observacoes,
    List<RegistroServico>? historico,
  }) : historicoServicos = historico ?? [];

  //CONEXÃO COM O BANCO
  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      id: map['id'],
      modelo: map['modelo'] ?? '',
      placa: map['placa'] ?? '',
      ano: map['ano'],
      cor: map['cor'],
      proprietario: map['proprietario'] ?? '',
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'modelo': modelo,
      'placa': placa,
      'ano': ano,
      'cor': cor,
      'proprietario': proprietario,
      'observacoes': observacoes,
    };
  }
}