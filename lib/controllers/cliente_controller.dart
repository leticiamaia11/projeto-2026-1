import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../controllers/veículo_controller.dart';

class ClienteController {
  List<Cliente> listaDeClientes = [];

  final VeiculoController veiculoController;
  ClienteController({required this.veiculoController});

  //===============================================================================
  //                            LISTA ALFABÉTICA
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

  //VERIFICA SE O CPF JA EXISTE
  bool cpfJaExiste(String cpfNovo) {
    return listaDeClientes.any((c) => c.cpf == cpfNovo);
  }

  //===============================================================================
  //                            CADASTRO CLIENTE
  //===============================================================================
  bool processarCadastroCliente({
    required String nome,
    required String cpf,
    required String telefone,
    required String email,
    String? endereco,
    String? observacoes,
  }) {
    //valida se os campos obrigatórios não estão vazios
    if (nome.isEmpty || cpf.isEmpty || telefone.isEmpty || email.isEmpty) {
      print("Erro: Preencha todos os campos obrigatórios.");
      return false;
    }

    //Aplica trava de CPF
    if (cpfJaExiste(cpf)) {
      print("Erro: Este CPF já está regustrado no sistema");
      return false;
    }

    //Acerto
    Cliente novoCliente = Cliente(
      nomeCompleto: nome,
      cpf: cpf,
      telefone: telefone,
      email: email,
      endereco: endereco,
      observacoes: observacoes,
    );

    listaDeClientes.add(novoCliente);
    return true;
  }

  //===============================================================================
  //                                  BUSCA
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
  //                             VEICULO DO CLIENTE
  //===============================================================================
  void vincularVeiculoAoCliente(String cpfDono, Veiculo carro) {
    // LOCALIZAR O CLIENTE PELO CPF
    Cliente? dono = localizarClientePorCpf(cpfDono);

    if (dono != null) {
      //adiciona carro na lista do cliente
      dono.meusVeiculos.add(carro);

      //SINCRONIZAR CARRO COM DONO
      carro.proprietario = dono.nomeCompleto;

      print("Sucesso: ${carro.modelo} vinculado a ${dono.nomeCompleto}");
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
  void excluirVeiculoComSeguranca({
    required Cliente cliente,
    required String placaAlvo,
    required String cpfConfirmacao,
  }) {
    //verifica se o cpf digitado é o mesmo do dono
    if (cpfConfirmacao == cliente.cpf) {
      //Remove da lista interna do cliente
      cliente.meusVeiculos.removeWhere((v) => v.placa == placaAlvo);

      veiculoController.listaDeVeiculos.removeWhere(
        (v) => v.placa == placaAlvo,
      );

      print("Sucesso: O veículo foi excluído do sistema.");
    } else {
      print("Erro: CPF de confirmação incorreto.  A exclusão foi cancelada.");
    }
  }

  //===============================================================================
  //                            ADICIONAR VEICULO
  //===============================================================================
  void adicionarNovoVeiculo({
    required String placa,
    required String modelo,
    required Cliente donoSelecionado,
  }) {
    Veiculo novoCarro = Veiculo(
      placa: placa,
      modelo: modelo,
      proprietario: donoSelecionado.nomeCompleto,
    );

    //adicionando na lista geral da oficina
    veiculoController.listaDeVeiculos.add(novoCarro);

    //adicionando na lista de veiculos dewntro do cadastro do cliente
    donoSelecionado.meusVeiculos.add(novoCarro);
    print(
      "Sucesso! O ${modelo} foi vinculado a ${donoSelecionado.nomeCompleto}.",
    );
  }
}