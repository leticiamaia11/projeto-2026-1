import '../models/veiculo.dart';

class VeiculoController {
  List<Veiculo> listaDeVeiculos = [];
  List<Veiculo> obterVeiculos() {
    return listaDeVeiculos;
  }

  //===============================================================================
  //                            LISTA ALFABÉTICA
  //===============================================================================
  List<Veiculo> obterVeiculosOrdenados() {
    List<Veiculo> listaOrdenada = List.from(listaDeVeiculos);
    listaOrdenada.sort(
      (a, b) => a.modelo.toLowerCase().compareTo(b.modelo.toLowerCase()),
    );

    return listaOrdenada;
  }

  //===============================================================================
  //                            VALIDAÇÃO DA PLACA
  //===============================================================================

  //verifica se está vazio
  String? validarPlaca(String valor) {
    if (valor.isEmpty) {
      return "A placa não pode ser vazia";
    }
    //tranforma tudo em maiúsculo
    String placaFormatada = valor.toUpperCase();

    //Verificar o tamanho (extamente 7)
    if (placaFormatada.length != 7) {
      return "A placa deve conter exatamente 7 caracteres";
    }

    //peneiras
    final regexLetras = RegExp(r'[A-Z]');
    final regexNumeros = RegExp(r'[0-9]');

    //contando quantas letras e numeros possuem na placa
    int quantidadeLetras = regexLetras.allMatches(placaFormatada).length;
    int quantidadeNumeros = regexNumeros.allMatches(placaFormatada).length;

    //Lógica de 3 letras e 4 números
    if (quantidadeLetras != 3 || quantidadeNumeros != 4) {
      return "Placa inválida";
    }
    return null;
  }

  bool placaJaExiste(String placaNova) {
    return listaDeVeiculos.any((v) => v.placa == placaNova.toUpperCase());
  }

  //Busca de um veículo específico pela placa
  Veiculo? procuraPorPlaca(String placaParaBuscar) {
    try {
      //procura o primeiro veículo que tenha a placa igual à digitada
      return listaDeVeiculos.firstWhere(
        (v) => v.placa == placaParaBuscar.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  //===============================================================================
  //                            VALIDAÇÃO DE ANO
  //===============================================================================

  String? validarAno(String? valor) {
    if (valor == null || valor.isEmpty) {
      return null; //opcional, então aceita vazio
    }

    //transformar o texto em número
    int? anoConvertido = int.tryParse(valor);
    int anoAtual = DateTime.now().year;

    // se não for um número válido
    if (anoConvertido == null) {
      return "Digite um ano válido.";
    }

    if (anoConvertido < 1900 || anoConvertido > anoAtual) {
      return "O ano não é válido.";
    }
    return null;
  }

  //===============================================================================
  //                            CADASTRO DE VEÍCULO
  //===============================================================================

  //função que o botão da tela vai chamar
  bool processarCadastro({
    required String modelo,
    required String placa,
    String? ano,
    required String proprietario,
  }) {
    //usar validações
    String? erroPlaca = validarPlaca(placa);
    String? erroAno = validarAno(ano);

    // tomada de decisão
    if (erroPlaca != null) {
      print("Erro na lógica: $erroPlaca");
      return false;
    }

    if (erroAno != null) {
      print("Erro na lógica: $erroAno");
      return false;
    }

    if (placaJaExiste(placa)) {
      print("Esta placa já está cadastrada no sistema!");
      return false;
    }

    print("Lógica aprovada! Criando o pacote do veículo...");

    //"pacote" oficial
    Veiculo novoVeiculo = Veiculo(
      modelo: modelo,
      placa: placa.toUpperCase(),
      proprietario: proprietario,
      ano: int.tryParse(ano ?? ''), //coverte a string da tela para numero
    );

    print("Veículo criado com sucesso: ${novoVeiculo.modelo}");

    return salvarNoSistema(novoVeiculo);
  }

  //simula o envio para o banco PESSOA 3
  // PESSOA 1 desenha lista onde vai ser encaminhado o veículo mais recente
  // no topo e os adicionados anteriormente ficam para baixo
  bool salvarNoSistema(Veiculo veiculoPronto) {
    try {
      listaDeVeiculos.insert(0, veiculoPronto);
      print("${veiculoPronto.modelo} adicionado ao topo da lista!");
      return true;
    } catch (e) {
      print("Erro ao salvar: $e");
      return false;
    }
  }

  bool removerVeiculo(String placaParaRemover) {
    //verifica se a placa já existe
    if (!placaJaExiste(placaParaRemover)) {
      print(
        "Erro: O veículo com a placa $placaParaRemover não foi encontrado ",
      );
      return false;
    }
    listaDeVeiculos.removeWhere(
      (v) => v.placa == placaParaRemover.toUpperCase(),
    );

    print("Veículo da placa $placaParaRemover removido da lista.");
    return true;
  }

  //=============================================================================//
  //                       ATUALIZAR PROPRIETÁRIO                                //
  //=============================================================================//
  //Atualiza o nome do proprietário
  atualizarNomeDoClienteEmTodosOsCarros(String nomeAntigo, String nomeNovo) {
    //Percorre toda a lista de veículos
    for (var veiculo in listaDeVeiculos) {
      if (veiculo.proprietario.toUpperCase() == nomeAntigo.toUpperCase()) {
        veiculo.proprietario = nomeNovo;
      }
    }
    print("Nome atualizado em todos os rregistros de $nomeNovo");
  }
}