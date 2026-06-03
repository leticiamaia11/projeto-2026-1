class Usuario {
  int? id;
  String nome;
  String email;
  String senha;
  String cpf;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.cpf,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      senha: map['senha'] ?? '',
      cpf: map['cpf'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'email': email,
      'senha': senha,
      'cpf': cpf,
    };
  }
}