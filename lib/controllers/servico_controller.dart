import '../models/registroServico.dart';
import 'veículo_controller.dart';
import '../models/veiculo.dart';
import '../models/gasto.dart';

class ServicoController {
  //===============================================================================
  //                      LISTA DE TODOS OS SERVIÇOS
  //===============================================================================
  List<RegistroServico> _historicoGlobal = [];

  final VeiculoController veiculoController;
  ServicoController({required this.veiculoController});
  //getter para que PESSOA 1 E PESSOA 3 possam ler a lista
  List<RegistroServico> get historicoGlobal => _historicoGlobal;

  //===============================================================================
  //                                  AGENDA
  //===============================================================================
  List<RegistroServico> carregarAgendaDoDia(DateTime dataAlvo) {
    List<RegistroServico> filtrados = [];

    for (var servico in _historicoGlobal) {
      if (servico.data.day == dataAlvo.day &&
          servico.data.month == dataAlvo.month &&
          servico.data.year == dataAlvo.year &&
          servico.concluido == false) {
        filtrados.add(servico);
      }
    }
    return filtrados;
  }

  List<RegistroServico> carregarAgendaPriorizada() {
    // ignore: unused_local_variable
    DateTime hoje = DateTime.now();

    //serviços que não estão concluídos
    List<RegistroServico> pendentes = _historicoGlobal
        .where((s) => s.concluido == false)
        .toList();

    //ordenar por horário
    pendentes.sort((a, b) => a.data.compareTo(b.data));

    return pendentes;
  }

  //CONCLUSÃO DE SERVIÇO
  void finalizarServico(RegistroServico servico) {
    servico.concluido = true;

    print(
      "Sucesso: O serviço '${servico.descricao}' foi marcado como concluído!",
    );
  }

  //FUNÇÃO QUE RETORNA POSSÍVEIS HORÁRIOS PARA AGENDAR SERVIÇOS
  List<String> gerarHorariosDisponiveis() {
    return [
      "08:00",
      "09:00",
      "10:00",
      "11:00",
      "12:00",
      "13:00",
      "14:00",
      "15:00",
      "16:00",
      "17:00",
      "18:00",
      "19:00",
      "20:00",
    ];
  }

  //HORARIOS OCUPADOS
  bool isHorarioOcupado(DateTime dataDesejada) {
    for (var servico in _historicoGlobal) {
      if (servico.data.year == dataDesejada.year &&
          servico.data.month == dataDesejada.month &&
          servico.data.day == dataDesejada.day &&
          servico.data.hour == dataDesejada.hour &&
          servico.data.minute == dataDesejada.minute) {
        return true;
      }
    }
    return false;
  }

  bool verificarSeEstaBloqueado(DateTime horarioClicado) {
    for (var servico in _historicoGlobal) {
      //se o serviço já terminou
      if (servico.concluido) continue;

      DateTime inicio = servico.data;
      DateTime termino = servico.horarioTermino;

      if (horarioClicado.isAtSameMomentAs(inicio) ||
          (horarioClicado.isAfter(inicio) &&
              horarioClicado.isBefore(termino))) {
        return true;
      }
    }
    return false;
  }

  //===============================================================================
  //                      ADICIONAR SERVIÇO (ENTRADAS)
  //===============================================================================
  void adicionarServico({
    required String placa,
    required String descricao,
    required double valor,
    required int duracao,
  }) {
    //Regra de segurança: valor deve ser maior que zero
    if (valor <= 0) {
      print("Erro: O valor do serviço deve ser maior que zero");
      return;
    }

    //buscar veiculo na lista veiculoController
    Veiculo? veiculoEncontrado;

    for (var v in veiculoController.listaDeVeiculos) {
      if (v.placa == placa) {
        veiculoEncontrado = v;
        break;
      }
    }
    if (veiculoEncontrado != null) {
      var novoServico = RegistroServico(
        descricao: descricao,
        valor: valor,
        placaVeiculo: placa,
        duracaoEmHoras: duracao,
      );

      _historicoGlobal.add(novoServico);

      veiculoEncontrado.historicoServicos.add(novoServico);

      print("Sucesso: Serviço registrado para a placa $placa");
    } else {
      print("Erro: Veículo não encontrado no sistema.");
    }
  }

  //FUNÇÃO DE SOMA DE VALORES
  double calcularTotalFaturado() {
    double total = 0.0;

    //passando por cada serviço da lista
    for (var servico in _historicoGlobal) {
      total += servico.valor;
    }
    return total;
  }

  //===============================================================================
  //                             GASTOS (SAÍDAS)
  //===============================================================================
  List<Gasto> _historicoGastos = [];
  List<Gasto> get historicoGastos => _historicoGastos;

  double calcularTotalGastos() {
    double totalGasto = 0.0;

    for (var gasto in _historicoGastos) {
      totalGasto += gasto.valor;
    }
    return totalGasto;
  }

  double calcularBalancoTotal() {
    double entradas = calcularTotalFaturado();
    double saidas = calcularTotalGastos();

    return entradas - saidas;
  }

  //ADICIONAR GASTOS (SAÍDA)
  void adicionarGasto({
    required String descricao,
    required double valor,
    DateTime? data,
  }) {
    if (valor <= 0) {
      print("Erro: O valor do gasto deve ser maior que zero.");
      return;
    }

    var novoGasto = Gasto(
      descricao: descricao,
      valor: valor,
      dataInformada: data,
    );

    _historicoGastos.add(novoGasto);
    print("Sucesso: Gasto '$descricao' registrado!");
  }

  //===============================================================================
  //                                 AGENDA
  //===============================================================================

  void agendarServico({
    required String descricao,
    required double valor,
    required String placa,
    required DateTime dataHora,
    required int duracao,
  }) {
    bool bloqueado = verificarSeEstaBloqueado(dataHora);
    if (bloqueado) {
      print("Não foi possível agendar: Este horário já está ocupado!");
      return;
    }
    //criando serviço caso o horário esteja disponível
    var novoAgendamento = RegistroServico(
      descricao: descricao,
      valor: valor,
      placaVeiculo: placa,
      duracaoEmHoras: duracao,
      dataInformada: dataHora,
      concluido: false,
    );

    //salvando na lista global
    _historicoGlobal.add(novoAgendamento);
    print(
      "Sucesso: Serviço agendado para ${dataHora}/${dataHora.month} às ${dataHora.hour}:00",
    );
  }

  //PROCURAR UM CARRO PELA PLACA

  List<RegistroServico> buscarHistoricoPorPlaca(String placaDigitada) {
    List<RegistroServico> resultados = [];

    for (var servico in _historicoGlobal) {
      //se a placa do serviço for correspondente a placa que o usuário procura
      if (servico.placaVeiculo == placaDigitada) {
        //guardando o serviço  na lista de resultados
        resultados.add(servico);
      }
    }
    return resultados;
  }

  //CALCULAR LUCRO ENTRE DATAS
  double calcularLucroPorPeriodo(DateTime dataInicio, DateTime dataFim) {
    double totalEntradas = 0.0;
    double totalSaidas = 0.0;

    //soma as entradas (serviços) no período
    for (var servico in _historicoGlobal) {
      if (servico.data.isAfter(dataInicio) && servico.data.isBefore(dataFim)) {
        totalEntradas += servico.valor;
      }
    }

    //soma as saídas (despesas) no período
    for (var despesa in _historicoGastos) {
      if (despesa.data.isAfter(dataInicio) && despesa.data.isBefore(dataFim)) {
        totalSaidas += despesa.valor;
      }
    }
    return totalEntradas - totalSaidas;
  }
}