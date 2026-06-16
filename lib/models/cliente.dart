import 'veiculo.dart'; 

class Cliente {
  String? id;
  String nomeCompleto;
  String cpf;
  String telefone;
  String email;
  String? endereco;
  String? observacoes;
  List<Veiculo> meusVeiculos;

  Cliente({
    this.id,
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.email,
    this.endereco,
    this.observacoes,
    List<Veiculo>? veiculos,
  }) : meusVeiculos = veiculos ?? [];

  factory Cliente.fromMap(Map<String, dynamic> map) {
    List<Veiculo> veiculosCarregados = [];
    final dadosVeiculo = map['veiculo'] ?? map['veiculos'];
    if (dadosVeiculo != null && dadosVeiculo is List) {
      veiculosCarregados = dadosVeiculo
          .map((v) => Veiculo.fromMap(v as Map<String, dynamic>))
          .toList();
    }

    return Cliente(
      id: map['id']?.toString(), 
      nomeCompleto: map['nome_completo'] ?? map['nomeCompleto'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      endereco: map['endereco'],
      observacoes: map['observacoes'],
      veiculos: veiculosCarregados, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome_completo': nomeCompleto, 
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'observacoes': observacoes,
    };
  }
}