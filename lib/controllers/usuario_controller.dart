import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class UsuarioController {
  final supabase = Supabase.instance.client;

  /// Faz o cadastro completo do usuário. 
  /// Retorna uma [String?] que será nula em caso de sucesso, 
  /// ou conterá a mensagem de erro caso falhe.
  Future<String?> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String cpfBruto,
  }) async {
    
    // ---- HIGIENIZAÇÃO DOS DADOS (Regra de Negócio) ----
    final cpf = cpfBruto.replaceAll(RegExp(r'[^0-9]'), ''); // Remove pontos e traços

    // ---- VALIDAÇÕES LOCAIS (Antigas e Novas) ----
    if (nome.isEmpty || email.isEmpty || cpf.isEmpty || senha.isEmpty) {
      return 'Erro: Preencha todos os campos obrigatórios.';
    }

    if (senha != confirmarSenha) {
      return 'Erro: As senhas digitadas não coincidem.';
    }

    if (!email.contains('@')) {
      return 'Erro: O e-mail digitado é inválido.';
    }

    if (senha.length < 6) {
      return 'Erro: A senha deve ter pelo menos 6 caracteres.';
    }
    
    if (senha == senha.toLowerCase()) {
      return 'Erro: A senha deve conter pelo menos uma letra maiúscula.';
    }
    
    if (!senha.contains(RegExp(r'[0-9]'))) {
      return 'Erro: A senha deve conter pelo menos um número.';
    }
    
    if (!senha.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Erro: A senha deve conter pelo menos uma letra.';
    }

    if (cpf.length != 11) {
      return 'Erro: O CPF deve conter exatamente 11 dígitos numéricos.';
    }

    // ---- INTEGRAÇÃO COM SUPABASE ----
    try {
      // Verifica se o e-mail ou CPF já existem na tabela 'usuarios'
      final checkExist = await supabase
          .from('usuarios')
          .select('id')
          .or('email.eq.$email,cpf.eq.$cpf')
          .maybeSingle();

      if (checkExist != null) {
        return 'Erro: E-mail ou CPF já cadastrados no sistema.';
      }

      // Instancia o novo usuário com os dados validados
      var novoUsuario = Usuario(nome: nome, email: email, senha: senha, cpf: cpf);

      // Insere na tabela do Supabase
      await supabase.from('usuarios').insert(novoUsuario.toMap());

      return null; // Retornar null indica que não houve erros! Sucesso absoluto.
      
    } catch (e) {
      return 'Erro ao salvar no banco de dados: $e';
    }
  }

  //===============================================================================
  //                      REGRA DE NEGÓCIO E AUTENTICAÇÃO
  //===============================================================================
  /// Realiza o login do usuário baseado no CPF e Senha.
  /// Retorna [null] se o login der certo, ou uma [String] com a mensagem de erro.
  Future<String?> fazerLogin({
    required String cpfBruto,
    required String senha,
  }) async {
    // Higienização dos dados: Remove pontos e traços deixados pela máscara
    final cpf = cpfBruto.replaceAll(RegExp(r'[^0-9]'), '');

    // Validações locais rápidas
    if (cpf.isEmpty || senha.isEmpty) {
      return 'Erro: Preencha todos os campos para entrar.';
    }

    if (cpf.length != 11) {
      return 'Erro: O CPF digitado deve conter 11 dígitos.';
    }

    try {
      // Busca na tabela 'usuarios' se existe alguém com este CPF e Senha
      final resultado = await supabase
          .from('usuarios')
          .select()
          .eq('cpf', cpf)
          .eq('senha', senha) // Em produção, lembre-se de comparar hashes criptografados!
          .maybeSingle();

      // Tomada de decisão lógica baseada no retorno da nuvem
      if (resultado == null) {
        return 'Erro: Usuário não encontrado ou senha incorreta.';
      }

      return null; // Login validado com sucesso!
    } catch (e) {
      return 'Erro na conexão com o servidor: $e';
    }
  }

  //===============================================================================
  //                      GERENCIAMENTO DE SESSÃO (LOGOUT)
  //===============================================================================
  /// Remove os dados da sessão ativa do usuário no Supabase.
  /// Retorna [true] em caso de sucesso ou [false] se falhar.
  Future<bool> deslogarUsuario() async {
    try {
      await supabase.auth.signOut();
      return true;
    } catch (e) {
      print('Erro ao tentar fazer logout no Supabase: $e');
      return false;
    }
  }
  
  //===============================================================================
  //                      BUSCA DE DADOS DO USUÁRIO LOGADO
  //===============================================================================
  /// Recupera o nome do usuário atualmente autenticado.
  /// Retorna o nome ou 'Usuário' caso não encontre.
  Future<String> obterNomeUsuarioLogado() async {
    try {
      // Pega o usuário atual da sessão do Supabase Auth
      final usuarioAtual = supabase.auth.currentUser;
      
      if (usuarioAtual != null && usuarioAtual.email != null) {
        // Busca o nome correspondente na tabela 'usuarios' usando o e-mail da sessão
        final dados = await supabase
            .from('usuarios')
            .select('nome')
            .eq('email', usuarioAtual.email!)
            .maybeSingle();
            
        if (dados != null && dados['nome'] != null) {
          return dados['nome'] as String;
        }
      }
      return 'Mecânico'; // Nome padrão caso não encontre no banco
    } catch (e) {
      print('Erro ao obter nome do usuário: $e');
      return 'Oficina';
    }
  }
}