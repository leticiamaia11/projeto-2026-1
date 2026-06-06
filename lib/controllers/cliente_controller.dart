import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../controllers/veículo_controller.dart';

class ClienteController {
  // Instancia o cliente do Supabase para conexão com a nuvem
  final _supabase = Supabase.instance.client;

  // Lista local para servir de cache e manter a rapidez das buscas em tela
  List<Cliente> listaDeClientes = [];

  final VeiculoController veiculoController;
  ClienteController({required this.veiculoController});

  //===============================================================================
  //                            SINK COM O SUPABASE
  //===============================================================================
  /// Carrega a lista de clientes direto da nuvem e atualiza a memória local
  Future<List<Cliente>> carregarClientesDoBanco() async {
    try {
      final dados = await _supabase.from('clientes').select();
      listaDeClientes = (dados as List).map((map) => Cliente.fromMap(map)).toList();
      return listaDeClientes;
    } catch (e) {
      print('Erro ao carregar dados do Supabase: $e');
      return listaDeClientes;
    }
  }

  //===============================================================================
  //                               LISTA ALFABÉTICA
  //===============================================================================
  List<Cliente> obterClientesOrdenados() {
    //cópia para não mexer na lista original por acidente
    List<Cliente> listaOrdenada = List.from(listaDeClientes);

    //ORGANIZANDO OS ITENS
    listaOrdenada.sort(
      (a, b) =>
          a.nomeCompleto.toLowerCase().compareTo(b.nomeCompleto.toLowerCase()),
    );

    return listaOrdenada;
  }

  //FERRAMENTA DE PESQUISA
  List<Cliente> pesquisarCliente(String termoBusca) {
    return listaDeClientes.where((cliente) {
      String nome = cliente.nomeCompleto.toLowerCase();
      String busca = termoBusca.toLowerCase();
      return nome.contains(busca);
    }).toList();
  }

  //VERIFICA SE O CPF JA EXISTE (Agora checa em tempo real se necessário)
  bool cpfJaExiste(String cpfNovo) {
    return listaDeClientes.any((c) => c.cpf == cpfNovo);
  }

  //===============================================================================
  //                              CADASTRO CLIENTE
  //===============================================================================
  /// Realiza o cadastro do cliente salvando as informações no banco remoto
  Future<bool> processarCadastroCliente({
    required String nome,
    required String cpf,
    required String telefone,
    required String email,
    String? endereco,
    String? observacoes,
  }) async {
    //valida se os campos obrigatórios não estão vazios
    if (nome.isEmpty || cpf.isEmpty || telefone.isEmpty || email.isEmpty) {
      print("Erro: Preencha todos os campos obrigatórios.");
      return false;
    }

    //Aplica trava de CPF localmente para economizar requisições
    if (cpfJaExiste(cpf)) {
      print("Erro: Este CPF já está registrado no sistema");
      return false;
    }

    try {
      // Acerto
      Cliente novoCliente = Cliente(
        nomeCompleto: nome,
        cpf: cpf,
        telefone: telefone,
        email: email,
        endereco: endereco,
        observacoes: observacoes,
      );

      // Salva fisicamente na nuvem dentro da tabela 'clientes'
      final resposta = await _supabase
          .from('clientes')
          .insert(novoCliente.toMap())
          .select()
          .single();

      // Atualiza o objeto local adicionando o ID gerado automaticamente pelo banco
      novoCliente.id = resposta['id'];
      listaDeClientes.add(novoCliente);
      
      return true;
    } catch (e) {
      print("Erro ao cadastrar no Supabase: $e");
      return false;
    }
  }

  //===============================================================================
  //                                   BUSCA
  //===============================================================================
  Cliente? encontrarDono(String informacao) {
    try {
      return listaDeClientes.firstWhere(
        (c) =>
            c.nomeCompleto.toLowerCase().contains(informacao.toLowerCase()) ||
            c.cpf == informacao,
      );
    } catch (e) {
      return null; //Retorna nulo se não achar ninguém
    }
  }

  //===============================================================================
  //                              VEICULO DO CLIENTE
  //===============================================================================
  Future<void> vincularVeiculoAoCliente(String cpfDono, Veiculo carro) async {
    // LOCALIZAR O CLIENTE PELO CPF
    Cliente? dono = localizarClientePorCpf(cpfDono);

    if (dono != null) {
      //adiciona carro na lista do cliente
      dono.meusVeiculos.add(carro);

      //SINCRONIZAR CARRO COM DONO
      carro.proprietario = dono.nomeCompleto;

      try {
        // Atualiza a tabela de veículos relacionando o id do cliente cadastrado
        await _supabase.from('veiculos').insert({
          'placa': carro.placa,
          'modelo': carro.modelo,
          'cliente_id': dono.id, // Chave estrangeira ligando ao dono
          'proprietario': dono.nomeCompleto
        });
        print("Sucesso: ${carro.modelo} vinculado a ${dono.nomeCompleto}");
      } catch (e) {
        print("Erro ao salvar relacionamento de veículo no banco: $e");
      }
    } else {
      print("Erro: Cliente não encontrado para vinculação.");
    }
  }

  Cliente? localizarClientePorCpf(String cpfProcurado) {
    try {
      return listaDeClientes.firstWhere((c) => c.cpf == cpfProcurado);
    } catch (e) {
      return null;
    }
  }

  //===============================================================================
  //                             EXCLUIR VEICULO
  //===============================================================================
  Future<void> excluirVeiculoComSeguranca({
    required Cliente cliente,
    required String placaAlvo,
    required String cpfConfirmacao,
  }) async {
    //verifica se o cpf digitado é o mesmo do dono
    if (cpfConfirmacao == cliente.cpf) {
      try {
        // Remove fisicamente da tabela de veículos do Supabase
        await _supabase.from('veiculos').delete().eq('placa', placaAlvo);

        // Remove das listas locais de memória
        cliente.meusVeiculos.removeWhere((v) => v.placa == placaAlvo);
        veiculoController.listaDeVeiculos.removeWhere((v) => v.placa == placaAlvo);

        print("Sucesso: O veículo foi excluído do sistema.");
      } catch (e) {
        print("Erro ao excluir veículo do banco: $e");
      }
    } else {
      print("Erro: CPF de confirmação incorreto. A exclusão foi cancelada.");
    }
  }

  //===============================================================================
  //                             ADICIONAR VEICULO
  //===============================================================================
  Future<void> adicionarNovoVeiculo({
    required String placa,
    required String modelo,
    required Cliente donoSelecionado,
  }) async {
    Veiculo novoCarro = Veiculo(
      placa: placa,
      modelo: modelo,
      proprietario: donoSelecionado.nomeCompleto,
    );

    try {
      // Salva o novo veículo vinculando-o ao id correspondente na tabela do banco
      await _supabase.from('veiculos').insert({
        'placa': placa,
        'modelo': modelo,
        'cliente_id': donoSelecionado.id,
        'proprietario': donoSelecionado.nomeCompleto
      });

      //adicionando na lista geral da oficina
      veiculoController.listaDeVeiculos.add(novoCarro);

      //adicionando na lista de veiculos dentro do cadastro do cliente
      donoSelecionado.meusVeiculos.add(novoCarro);
      print("Sucesso! O $modelo foi vinculado a ${donoSelecionado.nomeCompleto}.");
    } catch (e) {
      print("Erro ao inserir veículo na nuvem: $e");
    }
  }
}