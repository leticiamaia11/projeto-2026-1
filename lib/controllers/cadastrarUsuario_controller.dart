import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class UsuarioController {
  final supabase = Supabase.instance.client;

  // Modificado para retornar Future<bool> para a tela saber se deu certo ou errado
  Future<bool> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
  }) async {
    
    // ---- VALIDAÇÕES LOCAIS ----
    if (!email.contains('@')) {
      print('Erro: O e-mail digitado é inválido.');
      return false;
    }

    if (senha.length < 6) {
      print('Erro: A senha deve ter pelo menos 6 caracteres.');
      return false;
    }
    if (senha == senha.toLowerCase()) {
      print('Erro: A senha deve conter pelo menos uma letra maiúscula.');
      return false;
    }
    if (!senha.contains(RegExp(r'[0-9]'))) {
      print('Erro: a senha deve conter pelo menos um número.');
      return false;
    }
    if (!senha.contains(RegExp(r'[a-zA-Z]'))) {
      print('Erro: a senha deve conter pelo menos uma letra.');
      return false;
    }

    if (cpf.length != 11 || int.tryParse(cpf) == null) {
      print('Erro: O CPF deve conter exatamente 11 dígitos numéricos.');
      return false;
    }

    // ---- INTEGRAÇÃO COM SUPABASE ----
    try {
      // 1. Verifica se o e-mail ou CPF já existem na tabela 'usuarios'
      final checkExist = await supabase
          .from('usuarios')
          .select('id')
          .or('email.eq.$email,cpf.eq.$cpf')
          .maybeSingle();

      if (checkExist != null) {
        print('Erro: E-mail ou CPF já cadastrados no sistema.');
        return false;
      }

      // 2. Instancia o novo usuário
      var novoUsuario = Usuario(nome: nome, email: email, senha: senha, cpf: cpf);

      // 3. Insere na tabela 'usuarios' do Supabase
      await supabase.from('usuarios').insert(novoUsuario.toMap());

      print('Cadastro concluído com sucesso no Supabase!');
      return true;
      
    } catch (e) {
      print('Erro ao salvar usuário no Supabase: $e');
      return false;
    }
  }
}