import 'package:flutter/material.dart';
import 'package:projeto_integrador/view/cadastro_cliente.dart';

class TelaAgendamento extends StatefulWidget {
  const TelaAgendamento({super.key});

  @override
  State<TelaAgendamento> createState() => _TelaAgendamentoState();
}

class _TelaAgendamentoState extends State<TelaAgendamento> {
  // Variável para controlar qual cliente está selecionado
  String clienteSelecionado = 'Emily';
  final TextEditingController _dataController = TextEditingController();
  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Serviço*', estiloBorda),
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

                _buildTextField('Descrição', estiloBorda, isLong: true),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Início',
                        estiloBorda,
                        icon: Icons.access_time,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'Fim',
                        estiloBorda,
                        icon: Icons.access_time,
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
                      // Lógica para salvar o agendamento
                      Navigator.pop(context);
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
      controller: controller, // Permite controlar o valor do campo (ex: para data)
      readOnly: readOnly, // Impede o teclado de aparecer
      onTap: onTap, // Executa a função ao clicar
      maxLines: isLong ? 3 : 1,
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
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: CircleAvatar(radius: 4, backgroundColor: color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
