import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:projeto_integrador/view/agendamento.dart';
import 'package:projeto_integrador/models/agendamento.dart';
import 'package:projeto_integrador/controllers/calendario_controller.dart';

class TelaCalendario extends StatefulWidget {
  const TelaCalendario({super.key});

  @override
  State<TelaCalendario> createState() => _TelaCalendarioState();
}

class _TelaCalendarioState extends State<TelaCalendario> {
  final CalendarioController _controller = CalendarioController();
  DateTime _diaSelecionado = DateTime.now();
  DateTime _focoDia = DateTime.now();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    // Zera as horas do dia atual na inicialização para bater com as buscas do banco
    _diaSelecionado = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _atualizarListaDoDia(); 
  }

  // Busca assíncrona no banco de dados via controller
  Future<void> _atualizarListaDoDia() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    await _controller.carregarAgendamentosDoBanco(_diaSelecionado);
    if (mounted) setState(() => _carregando = false);
  }

  // Exibe confirmação antes de apagar o registro do banco
  void _confirmarExclusao(AgendamentoModel agendamento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: const Text("Deseja mesmo excluir este agendamento do sistema definitivamente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fecha o modal
              setState(() => _carregando = true);
              
              bool excluiu = await _controller.deletarAgendamentoDoBanco(agendamento);
              
              setState(() => _carregando = false);

              if (excluiu && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.green, content: Text("Agendamento excluído com sucesso!")),
                );
                _atualizarListaDoDia(); // Atualiza a tela após apagar
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.redAccent, content: Text("Erro ao excluir agendamento.")),
                );
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Calendário',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: 10),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
                  : _buildEventList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Aguarda o retorno da tela de cadastro.
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaAgendamento()),
          );
          // Atualiza a lista imediatamente ao voltar da tela de cadastro
          _atualizarListaDoDia();
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focoDia,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: const Color(0xFF1E40AF), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(color: Color(0xFF1E40AF), shape: BoxShape.circle),
          defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
          weekendTextStyle: const TextStyle(color: Colors.grey),
          outsideDaysVisible: false,
        ),
        selectedDayPredicate: (day) => isSameDay(_diaSelecionado, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            // Zera as horas para comparar puramente o dia civil (evita bugs de fuso horário)
            _diaSelecionado = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            _focoDia = focusedDay;
          });
          _atualizarListaDoDia(); // Busca no banco os dados do novo dia clicado
        },
      ),
    );
  }

  Widget _buildEventList() {
    final lista = _controller.agendamentosDoDiaSelecionado;

    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Nenhum agendamento para este dia.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaAgendamento()),
                  );
                  _atualizarListaDoDia();
                },
                icon: const Icon(Icons.add, color: Color(0xFF1E40AF)),
                label: const Text("Gostaria de realizar um agendamento?", style: TextStyle(color: Color(0xFF1E40AF))),
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final agendamento = lista[index];
        
        // Conversão dos horários do Model para String visível (HH:MM)
        String horaInicio = '${agendamento.inicio.hour.toString().padLeft(2, '0')}:${agendamento.inicio.minute.toString().padLeft(2, '0')}';
        String horaFim = '${agendamento.fim.hour.toString().padLeft(2, '0')}:${agendamento.fim.minute.toString().padLeft(2, '0')}';

        return _eventCard(
          agendamento,
          "$horaInicio - $horaFim",
          "${agendamento.servico} - ${agendamento.clienteNome}",
          "Obs: ${agendamento.descricao}",
          const Color(0xFF1E40AF),
        );
      },
    );
  }

  Widget _eventCard(AgendamentoModel model, String hora, String titulo, String sub, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hora, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmarExclusao(model),
          ),
        ],
      ),
    );
  }
}