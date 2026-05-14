import 'veiculo.dart';

class Cliente {
  String nomeCompleto;
  String cpf;
  String telefone;
  String email;
  String? endereco;
  String? observacoes;
  List<Veiculo> meusVeiculos;

  Cliente({
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.email,
    this.endereco,
    this.observacoes,
    List<Veiculo>? veiculos,
  }) : meusVeiculos = veiculos ?? [];
}
