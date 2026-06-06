import '../models/veiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VeiculoController {
  // Lista na memória que abastece a View
  List<Veiculo> listaDeVeiculos = [];

  final _supabase = Supabase.instance.client;

  //===============================================================================
  //                      BUSCAR DADOS REAIS DO BANCO
  //===============================================================================
  Future<void> carregarVeiculosDoBanco() async {
    try {
      // 1. Busca as linhas direto da tabela do banco de dados
      final response = await _supabase.from('veiculos').select();
      
      // 2. Transforma o formato do banco (Map) para a lista de objetos 'Veiculo'
      this.listaDeVeiculos = (response as List)
           .map((item) => Veiculo.fromMap(item)) 
           .toList();

      print("Banco de dados consultado. Total de veículos: ${listaDeVeiculos.length}");
    } catch (e) {
      print("Erro real ao buscar dados do banco: $e");
      rethrow; // Repassa o erro para a View tratar se necessário
    }
  }

  //===============================================================================
  //                      ENVIAR DADOS REAIS PARA O BANCO
  //===============================================================================
  Future<bool> salvarNoSistema(Veiculo veiculoPronto) async {
    try {
      // 1. Insere o objeto convertido em Map dentro da tabela do banco
       await _supabase.from('veiculos').insert(veiculoPronto.toMap());
      
      // 2. Atualiza a lista local para o usuário ver o novo carro imediatamente
      listaDeVeiculos.insert(0, veiculoPronto);
      return true;
    } catch (e) {
      print("Erro real ao salvar no banco de dados: $e");
      return false;
    }
  }

  //===============================================================================
  //                      MÉTODOS DE FILTRO E AUXILIARES
  //===============================================================================
  List<Veiculo> obterVeiculos() {
    return listaDeVeiculos;
  }

  List<Veiculo> obterVeiculosOrdenados() {
    List<Veiculo> listaOrdenada = List.from(listaDeVeiculos);
    listaOrdenada.sort(
      (a, b) => a.modelo.toLowerCase().compareTo(b.modelo.toLowerCase()),
    );
    return listaOrdenada;
  }

  //===============================================================================
  //                            VALIDAÇÕES DA TELA
  //===============================================================================
  String? validarPlaca(String valor) {
    if (valor.isEmpty) return "A placa não pode ser vazia";
    String placaFormatada = valor.toUpperCase();
    if (placaFormatada.length != 7) return "A placa deve conter exatamente 7 caracteres";

    final regexLetras = RegExp(r'[A-Z]');
    final regexNumeros = RegExp(r'[0-9]');
    int quantidadeLetras = regexLetras.allMatches(placaFormatada).length;
    int quantidadeNumeros = regexNumeros.allMatches(placaFormatada).length;

    if (quantidadeLetras != 3 || quantidadeNumeros != 4) return "Placa inválida";
    return null;
  }

  bool placaJaExiste(String placaNova) {
    return listaDeVeiculos.any((v) => v.placa == placaNova.toUpperCase());
  }

  String? validarAno(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    int? anoConvertido = int.tryParse(valor);
    int anoAtual = DateTime.now().year;
    if (anoConvertido == null) return "Digite um ano válido.";
    if (anoConvertido < 1900 || anoConvertido > anoAtual) return "O ano não é válido.";
    return null;
  }

  //===============================================================================
  //                           PROCESSAR FORMULÁRIO
  //===============================================================================
  Future<bool> processarCadastro({
    required String modelo,
    required String placa,
    String? ano,
    required String proprietario,
  }) async {
    String? erroPlaca = validarPlaca(placa);
    String? erroAno = validarAno(ano);

    if (erroPlaca != null || erroAno != null || placaJaExiste(placa)) {
      return false;
    }

    Veiculo novoVeiculo = Veiculo(
      modelo: modelo,
      placa: placa.toUpperCase(),
      proprietario: proprietario,
      ano: int.tryParse(ano ?? ''),
    );

    // Chame o método que faz o insert na nuvem
    return await salvarNoSistema(novoVeiculo);
  }

  Future<bool> removerVeiculo(String placaParaRemover) async {
    if (!placaJaExiste(placaParaRemover)) return false;
    
    try {
      // Deleta do banco de dados real usando a placa como identificador
       await _supabase.from('veiculos').delete().eq('placa', placaParaRemover.toUpperCase());
      
      listaDeVeiculos.removeWhere((v) => v.placa == placaParaRemover.toUpperCase());
      return true;
    } catch (e) {
      print("Erro ao deletar do banco: $e");
      return false;
    }
  }

  void atualizarNomeDoClienteEmTodosOsCarros(String nomeAntigo, String nomeNovo) {
    for (var veiculo in listaDeVeiculos) {
      if (veiculo.proprietario.toUpperCase() == nomeAntigo.toUpperCase()) {
        veiculo.proprietario = nomeNovo;
      }
    }
  }
}