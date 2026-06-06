import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_cliente.dart';
import 'package:projeto_integrador/controllers/agendamento_controller.dart';

class TelaAgendamento extends StatefulWidget {
  const TelaAgendamento({super.key});

  @override
  State<TelaAgendamento> createState() => _TelaAgendamentoState();
}

class _TelaAgendamentoState extends State<TelaAgendamento> {
  final AgendamentoController _controller = AgendamentoController();
  bool _carregando = false; // Controla o feedback visual de salvamento

  void _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _controller.atualizarData(selectedDate);
      });
    }
  }

  void _showInicioTimePicker() async {
    TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: _controller.horaInicioReal ?? TimeOfDay.now(),
    );
    if (horaSelecionada != null) {
      setState(() {
        bool limpouFim = _controller.atualizarHorarioInicio(horaSelecionada);
        if (limpouFim) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("O horário de início mudou. Selecione o fim novamente.")),
          );
        }
      });
    }
  }

  void _showFimTimePicker() async {
    if (_controller.horaInicioReal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione o horário de início primeiro.")),
      );
      return;
    }
    TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: _controller.horaInicioReal!,
    );
    if (horaSelecionada != null) {
      setState(() {
        bool valido = _controller.atualizarHorarioFim(horaSelecionada);
        if (!valido) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('O horário de término deve ser após o horário de início!'),
            ),
          );
        }
      });
    }
  }

  // Mudado para ASYNC para aguardar as respostas reais do Banco de Dados
  void _validarEProcessarAgendamento() async {
    if (!_controller.formKey.currentState!.validate()) return;

    if (_controller.clienteSelecionadoCompleto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Selecione um cliente para continuar.")),
      );
      return;
    }

    setState(() => _carregando = true); // Ativa o loading na tela

    // 1. FLUXO ALTERNATIVO: Aguarda validação assíncrona de conflito vinda do Banco
    bool existeConflito = await _controller.verificarConflitoHorarioNoBanco();
    if (existeConflito) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("O horário selecionado já possui um agendamento no banco de dados!"),
        ),
      );
      return;
    }

    // 2. FLUXO ALTERNATIVO: Aguarda verificação de histórico do cliente no Banco
    bool clienteJaTemServico = await _controller.clienteJaPossuiAgendamentoNoBanco();
    setState(() => _carregando = false); // Desativa antes de abrir o modal

    if (clienteJaTemServico) {
      _mostrarAlertaClienteRepetido();
    } else {
      _concluirAgendamento();
    }
  }

  void _mostrarAlertaClienteRepetido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cliente já Agendado"),
        content: const Text("Este cliente já possui um serviço registrado no banco. Deseja agendar novamente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _concluirAgendamento();
            },
            child: const Text("Agendar Novamente", style: TextStyle(color: Color(0xFF1E40AF))),
          ),
        ],
      ),
    );
  }

  // Envia a ordem de gravação final e monitora o sucesso da operação na nuvem/rede
  void _concluirAgendamento() async {
    setState(() => _carregando = true);
    
    bool sucesso = await _controller.salvarNoBancoDeDados();
    
    if (!mounted) return;
    setState(() => _carregando = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Agendamento salvo com sucesso no banco!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Falha ao salvar. Verifique a conexão.")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Serviço', estiloBorda, controller: _controller.servicoController),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Data',
                    estiloBorda,
                    icon: Icons.calendar_today_outlined,
                    controller: _controller.dataController,
                    readOnly: true,
                    onTap: _showDatePicker,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Descrição / Acordos do WhatsApp', estiloBorda, isLong: true, controller: _controller.descricaoController),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Início',
                          estiloBorda,
                          icon: Icons.access_time,
                          controller: _controller.inicioController,
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
                          controller: _controller.fimController,
                          readOnly: true,
                          onTap: _showFimTimePicker,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selecione Cliente & Veículo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildClientChip("Emily", "Celta - ABC1234", Colors.purple),
                      _buildClientChip("Letícia", "Onix - ABC0000", Colors.green),
                      _buildClientChip("Thayná", "Gol - ABC1111", Colors.blue),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TelaCadastroCliente()),
                          );
                        },
                        child: const Text("+ Adicionar", style: TextStyle(color: Color(0xFF1E40AF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: _carregando
                        ? const CircularProgressIndicator(color: Color(0xFF1E40AF)) // Carregamento visual para rede lenta
                        : ElevatedButton(
                            onPressed: _validarEProcessarAgendamento,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: const Color(0xFF1E40AF),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Agendar',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildTextField(String label, OutlineInputBorder estiloBorda, {bool isLong = false, IconData? icon, TextEditingController? controller, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: isLong ? 3 : 1,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Este campo é obrigatório';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: estiloBorda,
        enabledBorder: estiloBorda,
        focusedBorder: estiloBorda.copyWith(borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1)),
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedErrorBorder: estiloBorda.copyWith(borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        errorBorder: estiloBorda.copyWith(borderSide: const BorderSide(color: Colors.redAccent, width: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildClientChip(String name, String veiculo, Color color) {
    bool isSelected = _controller.clienteSelecionadoCompleto?['nome'] == name;
    return ChoiceChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontSize: 14)),
          Text(veiculo, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black54 : Colors.grey)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _controller.clienteSelecionadoCompleto = {'nome': name, 'veiculo': veiculo};
          } else {
            _controller.clienteSelecionadoCompleto = null;
          }
        });
      },
      selectedColor: color.withAlpha(30),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}