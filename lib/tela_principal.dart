import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/controllers/usuario_controller.dart'; 
import 'package:projeto_integrador/tela_login.dart'; 
import 'package:projeto_integrador/view/lista_clientes.dart';
import 'package:projeto_integrador/view/lista_veiulos.dart'; 
import 'package:projeto_integrador/view/agendamento.dart';
import 'package:projeto_integrador/view/servicos.dart';
import 'package:projeto_integrador/view/relatorio_financeiro.dart'; // 🟢 Verificado o nome do arquivo
import 'package:projeto_integrador/view/historico_servicos.dart';
import 'package:projeto_integrador/view/calendario.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final VeiculoController _veiculoCtrl = VeiculoController();
  final UsuarioController _usuarioCtrl = UsuarioController(); 
  late final ServicoController _servicoCtrl;
  
  int indiceSelecionado = 0; 
  late List<DiaCalendario> listaDias; 

  String _nomeUsuario = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _servicoCtrl = ServicoController(veiculoController: _veiculoCtrl);
    listaDias = gerarDias();
    _carregarNomeDoUsuario();
  }

  Future<void> _carregarNomeDoUsuario() async {
    String nome = await _usuarioCtrl.obterNomeUsuarioLogado();
    if (mounted) {
      setState(() {
        _nomeUsuario = nome; 
      });
    }
  }

  List<DiaCalendario> gerarDias() {
    List<DiaCalendario> dias = [];
    DateTime hoje = DateTime.now();
    List<String> nomesDias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];

    for (int i = 0; i < 7; i++) {
      DateTime data = hoje.add(Duration(days: i)); 
      dias.add(
        DiaCalendario(
          numero: data.day.toString(),
          diaSemana: nomesDias[data.weekday - 1], 
          dataCompleta: data,
        ),
      );
    }
    return dias;
  }

  Future<void> _executarLogout() async {
    bool deslogou = await _usuarioCtrl.deslogarUsuario();
    if (deslogou && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF1E40AF)),
          onPressed: _executarLogout,
        ),
        title: const Text(
          'Engetec - Soluções Automotivas',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Text(_nomeUsuario, style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        fontSize: 16,
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
                              indiceSelecionado = index; 
                            });
                            _navegar(context, const TelaCalendario());
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), // Evita conflitos de rolagem dentro do SingleChildScrollView
                crossAxisCount: 3, 
                crossAxisSpacing: 15, 
                mainAxisSpacing: 15, 
                children: [
                  BotaoMenu(
                    label: 'Clientes',
                    icon: Icons.person_outline,
                    onTap: () => _navegar(context, const ListaClientes()),
                  ),
                  BotaoMenu(
                    label: 'Veículos',
                    icon: Icons.directions_car_filled_outlined,
                    onTap: () => _navegar(context, const ListaVeiculos()), //  Corrigido o nome da classe da View externa
                  ),
                  BotaoMenu(
                    label: 'Agendar',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _navegar(context, const TelaAgendamento()),
                  ),
                  BotaoMenu(
                    label: 'Serviços',
                    icon: Icons.build_outlined,
                    onTap: () => _navegar(context, TelaServicos(servicoController: _servicoCtrl)),
                  ),
                  BotaoMenu(
                    label: 'Relatório',
                    icon: Icons.attach_money_outlined,
                    // Injetados os controllers obrigatórios exigidos pela TelaRelatorio
                    onTap: () => _navegar(context, TelaRelatorio(servicoController: _servicoCtrl, veiculoController: _veiculoCtrl)),
                  ),
                  BotaoMenu(
                    label: 'Histórico',
                    icon: Icons.access_time_outlined,
                    onTap: () => _navegar(
    context, 
   const TelaHistorico(
      veiculo: {})), // Corrigido o nome da classe da View externa
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _navegar(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => tela));
  }
}

//===============================================================================
//                          COMPONENTES AUXILIARES
//===============================================================================

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
            Icon(icon, size: 40, color: Colors.white), // Reduzido levemente de 50 para 40 para evitar overflow em telas menores
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
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