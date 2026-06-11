import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removido o mask_text_input_formatter que conflitava com decimais dinâmicos
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/models/gasto.dart'; 

class TelaSaidaFinanceira extends StatefulWidget {
  final ServicoController servicoController;

  const TelaSaidaFinanceira({super.key, required this.servicoController});

  @override
  State<TelaSaidaFinanceira> createState() => _TelaSaidaFinanceiraState();
}

class _TelaSaidaFinanceiraState extends State<TelaSaidaFinanceira> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  DateTime? _dataSelecionada;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _dataCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? selecionado = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF), 
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selecionado != null) {
      setState(() {
        _dataSelecionada = selecionado;
        _dataCtrl.text = "${selecionado.day.toString().padLeft(2, '0')}/${selecionado.month.toString().padLeft(2, '0')}/${selecionado.year}";
      });
    }
  }

  Future<void> _realizarRegistro() async {
    if (_formKey.currentState!.validate()) {
      
      // Converte o texto substituindo a vírgula por ponto para o double.parse funcionar de forma segura
      final valorTratado = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

      // Mantém a regra de negócio de unificar Título - Descrição
      final descricaoCompleta = "${_tituloCtrl.text} - ${_descricaoCtrl.text}";

      // Utiliza o modelo Gasto mapeando para a propriedade que alimenta o banco
      final novoGasto = Gasto(
        descricao: descricaoCompleta,
        valor: valorTratado,
        dataInformada: _dataSelecionada ?? DateTime.now(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool sucesso = await widget.servicoController.adicionarGasto(novoGasto);

      Navigator.pop(context); // Remove o CircularProgressIndicator

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saída financeira registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retorna ao relatório atualizado
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar no banco de dados. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Saída',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 350, 
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextField(
                    'Título',
                    estiloBorda,
                    controller: _tituloCtrl,
                    hint: 'ex: Peças, Ferramentas, Conta de Luz',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o título da saída';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Descrição',
                    estiloBorda,
                    controller: _descricaoCtrl,
                    hint: 'ex: Compra de amortecedores para estoque',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe uma descrição breve';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selecionarData(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        'Data',
                        estiloBorda,
                        controller: _dataCtrl,
                        hint: 'Escolha Data',
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione a data do gasto';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Valor Total',
                    estiloBorda,
                    controller: _valorCtrl,
                    hint: '0.00',
                    // 🟢 CORRIGIDO: Filtro limpo nativo que aceita apenas números, pontos e vírgulas sem tamanho fixo
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor total gasto';
                      }
                      final valorLimpo = value.replaceAll(',', '.');
                      if (double.tryParse(valorLimpo) == null) {
                        return 'Digite um valor numérico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _realizarRegistro,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: const Color(0xFFE5E7EB), 
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE5E7EB), 
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}