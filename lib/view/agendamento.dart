import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_cliente.dart';
import 'package:projeto_integrador/mock/agendamentos_mock.dart';

class TelaAgendamento extends StatefulWidget {
  const TelaAgendamento({super.key});

  @override
  State<TelaAgendamento> createState() => _TelaAgendamentoState();
}

class _TelaAgendamentoState extends State<TelaAgendamento> {
  // Variável para controlar qual cliente está selecionado. Começa nula para forçar o usuário a selecionar uma opção obrigatoriamente
  String? clienteSelecionado;

  // Chave global que gerencia o estado e validação do formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos normais (adicionados para capturar o texto do Serviço e Descrição)
  final TextEditingController _servicoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  // Controladores para capturar e mostrar os textos nos campos
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _inicioController = TextEditingController();
  final TextEditingController _fimController = TextEditingController();

  // Variáveis para guardar o horário puro (TimeOfDay) para fazer as contas de validação
  TimeOfDay? _horaInicioReal;
  TimeOfDay? _horaFimReal;
  DateTime? _dataReal;

  // Função para selecionar a data usando o DatePicker do Flutter
  void _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF), // Cor azul padrão
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E40AF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate != null) {
      setState(() {
        _dataReal = selectedDate;
        _dataController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"; // Formata para o padrão DD/MM/YYYY
      });
    }
  }

  // Função para selecionar o horário usando o TimePicker do Flutter
  void _showInicioTimePicker() async {
    TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: _horaInicioReal ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF), // Cor azul padrão
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E40AF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (horaSelecionada != null) {
      // Se o usuário já tinha selecionado um horário de fim, e o novo início for DEPOIS do fim, limpa o fim
      if (_horaFimReal != null) {
        final inicioMinutos =
            horaSelecionada.hour * 60 + horaSelecionada.minute;
        final fimMinutos = _horaFimReal!.hour * 60 + _horaFimReal!.minute;

        // Se o início for igual ou depois do fim, limpa o fim e avisa o usuário
        if (inicioMinutos >= fimMinutos) {
          setState(() {
             _horaFimReal = null;
              _fimController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "O horário de início mudou. Selecione o fim novamente.")),
          );
        }
      }
      setState(() {
        _horaInicioReal = horaSelecionada; // Guarda o horário puro para futuras validações
        // Formata para o padrão HH:MM (ex: 09:30)
        _inicioController.text =
            "${horaSelecionada.hour.toString().padLeft(2, '0')}:${horaSelecionada.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showFimTimePicker() async {
    // Impede de escolher o fim sem antes ter definido o início
    if (_horaInicioReal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione o horário de início primeiro.")),
      );
      return;
    }

    TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime:
          _horaInicioReal!, // Começa o picker já no horário de início selecionado
    );

    if (horaSelecionada != null) {
      // Convertendo tudo para minutos para comparar se o fim é antes do início
      final inicioMinutos =
          _horaInicioReal!.hour * 60 + _horaInicioReal!.minute;
      final fimMinutos = horaSelecionada.hour * 60 + horaSelecionada.minute;

      if (fimMinutos <= inicioMinutos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'O horário de término deve ser após o horário de início!'),
          ),
        );
        return; // Sai da função sem atualizar o campo
      }

      setState(() {
        _horaFimReal = horaSelecionada; // Guarda o horário puro para futuras validações
        _fimController.text = "${horaSelecionada.hour.toString().padLeft(2, '0')}:${horaSelecionada.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  // Limpa os controladores ao fechar a tela para evitar vazamento de memória
  void dispose() {
    _servicoController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Novo Agendamento',
          style: TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      //Envolvendo o corpo com o Form para ativar as validações automáticas
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Adicionado controller para o Serviço
                  _buildTextField(
                    'Serviço',
                    estiloBorda,
                    controller: _servicoController,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Data',
                    estiloBorda,
                    icon: Icons.calendar_today_outlined,
                    controller: _dataController,
                    readOnly: true,
                    onTap: _showDatePicker,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Descrição',
                    estiloBorda,
                    isLong: true,
                    controller: _descricaoController,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Mantém o alinhamento correto caso surja o texto de erro abaixo
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Início',
                          estiloBorda,
                          icon: Icons.access_time,
                          controller: _inicioController,
                          readOnly: true,
                          onTap: _showInicioTimePicker,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Fim',
                          estiloBorda,
                          icon: Icons.access_time,
                          controller: _fimController,
                          readOnly: true,
                          onTap: _showFimTimePicker,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Selecione Cliente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // seletor de cliente (simulação)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildClientChip("Emily", Colors.purple),
                      _buildClientChip("Letícia", Colors.green),
                      _buildClientChip("Thayná", Colors.blue),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TelaCadastroCliente(),
                            ),
                          );
                        },
                        child: const Text(
                          "+ Adicionar",
                          style: TextStyle(color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Botão Agendar
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Executa os validadores do Form antes de salvar
                        if (_formKey.currentState!.validate()) {
                          // Como o ChoiceChip não é um campo nativo do Form, validamos ele manualmente aqui
                          if (clienteSelecionado == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  "Selecione um cliente para continuar.",
                                ),
                              ),
                            );
                            return; // Sai da função sem fechar a tela
                          }

                          // Lógica para salvar o agendamento
                          // NOVO: Adiciona o objeto estruturado à lista simulada global antes de fechar a tela
                          setState(() {
                            listaAgendamentosGlobais.add(
                              AgendamentoModel(
                                servico: _servicoController.text,
                                descricao: _descricaoController.text,
                                data: _dataReal ?? DateTime.now(),
                                inicio: _inicioController.text,
                                fim: _fimController.text,
                                cliente: clienteSelecionado!,
                              ),
                            );
                          });
                          

                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ), // Largura total do container pai
                        backgroundColor: const Color(0xFF1E40AF),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Agendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar para criar os campos de texto
  Widget _buildTextField(
    String label,
    OutlineInputBorder estiloBorda, {
    bool isLong = false,
    IconData? icon,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller:
          controller, // Permite controlar o valor do campo (ex: para data)
      readOnly: readOnly, // Impede o teclado de aparecer
      onTap: onTap, // Executa a função ao clicar
      maxLines: isLong ? 3 : 1, // Se for campo longo, permite mais linhas
      // Adicionado validador padrão de obrigatoriedade
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: icon != null
            ? Icon(icon, color: Colors.grey, size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: estiloBorda,
        enabledBorder: estiloBorda,
        focusedBorder: estiloBorda.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),

        // Adicionada a estilização de erros customizada
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedErrorBorder: estiloBorda.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        errorBorder: estiloBorda.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  // Widget para os filtros de cliente (Chips)
  Widget _buildClientChip(String name, Color color) {
    bool isSelected = clienteSelecionado == name;
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (selected) {
        // Atualiza o cliente selecionado
        setState(() {
          clienteSelecionado = name;
        });
      },
      selectedColor: color.withValues(alpha: 0.1),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Deixa o nome em negrito quando selecionado
      ),
      avatar: CircleAvatar(radius: 4, backgroundColor: color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
