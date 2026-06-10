//import 'veículo.dart';
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
      final dados = await _supabase.from('cliente').select();
      listaDeClientes = (dados as List).map((map) => Cliente.fromMap(map)).toList();
      return listaDeClientes;
    } catch (e) {
      print('Erro ao carregar dados do Supabase: $e');
      return listaDeClientes;
    }
  }

  //===============================================================================
  //                              LISTA ALFABÉTICA
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

      // Salva fisicamente na nuvem dentro da tabela 'cliente'
      final List<dynamic> resposta = await _supabase
          .from('cliente')
          .insert(novoCliente.toMap())
          .select();

      if (resposta.isNotEmpty) {
        final dadosRetornados = resposta.first;
        // CORREÇÃO: O ID do banco agora é salvo diretamente como Texto (UUID)
        novoCliente.id = dadosRetornados['id']?.toString();
        
        listaDeClientes.add(novoCliente);
        print("Sucesso completo! Cliente salvo no Supabase com UUID: ${novoCliente.id}");
        return true;
      }
      
      return false;
    } catch (e) {
      print("Erro ao cadastrar no Supabase: $e");
      return false;
    }
  }

  //===============================================================================
  //                                 BUSCA
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
        // CORREÇÃO: Nome da tabela mudado de 'veiculos' para 'veiculo' conforme o print do banco
        await _supabase.from('veiculo').insert({
          'placa': carro.placa,
          'modelo': carro.modelo,
          'cliente_id': dono.id, // Envia o UUID sem estourar erro de tipo
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
        // CORREÇÃO: Tabela alterada para 'veiculo'
        await _supabase.from('veiculo').delete().eq('placa', placaAlvo);

        // Remove das locais de memória
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
    final String placaFormatada = placa.toUpperCase();
    
    Veiculo novoCarro = Veiculo(
      placa: placaFormatada,
      modelo: modelo,
      proprietario: donoSelecionado.nomeCompleto,
    );

    try {
      // CORREÇÃO: Tabela alterada para 'veiculo' e tratamento do cliente_id como UUID String
      await _supabase.from('veiculo').insert({
        'placa': placaFormatada,
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