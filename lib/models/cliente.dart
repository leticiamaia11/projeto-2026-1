import 'veiculo.dart';

class Cliente {
  // Campos Obrigatórios
  int? id; /////////////////////////////
  String nomeCompleto;
  String cpf;
  String telefone;
  String email;
  String? endereco;
  String? observacoes;
  List<Veiculo> meusVeiculos;

  Cliente({
    this.id, ///////////////////////
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.email,
    this.endereco,
    this.observacoes,
    List<Veiculo>? veiculos,
  }) : meusVeiculos = veiculos ?? [];

  //CONEXÃO COM BANCO DE DADOS (Atualizado com os nomes de colunas padrão de banco)
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nomeCompleto: map['nome_completo'] ?? map['nomeCompleto'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      endereco: map['endereco'],
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, ///////////////////////
      'nome_completo': nomeCompleto, // Mapeado para snake_case do banco
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'observacoes': observacoes,
    };
  }
}