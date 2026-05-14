import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/lista_clientes.dart';
import 'view/cadastro_veiculo.dart';
import 'view/cadastro_cliente.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int indiceSelecionado = 0; //controla qual dia está marcado
  late List<DiaCalendario> listaDias; //lista de datas reais

  @override
  void initState() {
    super.initState();
    //gera os dias apenas uma vez, quando a tela abre
    listaDias = gerarDias();
  }

  List<DiaCalendario> gerarDias() {
    List<DiaCalendario> dias = [];
    DateTime hoje = DateTime.now();
    List<String> nomesDias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];

    for (int i = 0; i < 7; i++) {
      DateTime data = hoje.add(
        Duration(days: i),
      ); //gera a data do dia atual + i dias
      dias.add(
        DiaCalendario(
          numero: data.day.toString(),
          diaSemana:
              nomesDias[data.weekday -
                  1], //ajusta para pegar o nome correto do dia
          dataCompleta: data,
        ),
      );
    }
    return dias;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.logout, color: Color(0xFF1E40AF)),
        title: const Text(
          'Oficina Souza',
          style: TextStyle(color: Color(0xFF1E40AF)),
        ),
        actions: const [
          Center(
            child: Text('Fernanda', style: TextStyle(color: Color(0xFF1E40AF))),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        // Permite rolar a tela e evita erro de espaço
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Bloco da agenda
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0091FF), Color(0xFF6AB5E2)],
                ),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      "Agenda",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 85,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listaDias.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemBuilder: (context, index) {
                        final dia = listaDias[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              indiceSelecionado =
                                  index; //marca o dia selecionado
                            });
                          },
                          child: CardDia(
                            numero: dia.numero,
                            diaSemana: dia.diaSemana,
                            selecionado: indiceSelecionado == index,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Funcionalidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                selectionColor: Color(0xFF1E40AF),
              ),
            ),

            //grid de botões
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap:
                    true, // Permite que o GridView ocupe apenas o espaço necessário
                crossAxisCount: 3, // Número de colunas
                crossAxisSpacing: 15, // Espaçamento horizontal entre os itens
                mainAxisSpacing: 15, // Espaçamento vertical entre os itens
                children: [
                  BotaoMenu(
                    label: 'Clientes',
                    icon: Icons.person_outline,
                    onTap: () => _navegar(context, const ListaClientes()),
                  ),
                  BotaoMenu(
                    label: 'Veículos',
                    icon: Icons.directions_car_filled_outlined,
                    onTap: () => _navegar(context, const TelaVeiculos()),
                  ),
                  BotaoMenu(
                    label: 'Agendar',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _navegar(context, const TelaAgendamento()),
                  ),
                  BotaoMenu(
                    label: 'Serviços',
                    icon: Icons.build_outlined,
                    onTap: () => _navegar(context, const TelaServicos()),
                  ),
                  BotaoMenu(
                    label: 'Relatório',
                    icon: Icons.attach_money_outlined,
                    onTap: () => _navegar(context, const TelaRelatorio()),
                  ),
                  BotaoMenu(
                    label: 'Histórico',
                    icon: Icons.access_time_outlined,
                    onTap: () => _navegar(context, const TelaHistorico()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navegar(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => tela));
  }
}

//Widget personalizado do card
class BotaoMenu extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const BotaoMenu({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF91B9D1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Telas de exemplo para o teste
class TelaClientes extends StatelessWidget {
  const TelaClientes({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Clientes")));
}

class TelaVeiculos extends StatelessWidget {
  const TelaVeiculos({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Veículos")));
}

class TelaAgendamento extends StatelessWidget {
  const TelaAgendamento({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Agendamento")));
}

class TelaServicos extends StatelessWidget {
  const TelaServicos({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Serviços")));
}

class TelaRelatorio extends StatelessWidget {
  const TelaRelatorio({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Relatório")));
}

class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Histórico")));
}

class DiaCalendario {
  final String numero;
  final String diaSemana;
  final DateTime dataCompleta;

  DiaCalendario({
    required this.numero,
    required this.diaSemana,
    required this.dataCompleta,
  });
}

class CardDia extends StatelessWidget {
  final String diaSemana;
  final String numero;
  final bool selecionado;

  const CardDia({
    super.key,
    required this.diaSemana,
    required this.numero,
    this.selecionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 60,
      decoration: BoxDecoration(
        color: selecionado ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            numero,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: selecionado ? const Color(0xFF1E40AF) : Colors.white,
            ),
          ),
          Text(
            diaSemana,
            style: TextStyle(
              fontSize: 12,
              color: selecionado ? const Color(0xFF1E40AF) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
