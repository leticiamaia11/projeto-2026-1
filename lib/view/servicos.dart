import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:intl/intl.dart';

class TelaServicos extends StatefulWidget {
  // Passa a receber o controller configurado por parâmetro
  final ServicoController servicoController;

  const TelaServicos({super.key, required this.servicoController});

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  final _formKey = GlobalKey<FormState>();
  
  // Remove o 'late final' anterior e usa diretamente o widget.servicoController
  late final ServicoController _servicoCtrl;

  final _placaCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();

  var mascaraPlaca = MaskTextInputFormatter(
    mask: '#######',
    filter: {"#": RegExp(r'[a-zA-Z0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    // Vincula a referência recebida da tela anterior
    _servicoCtrl = widget.servicoController;
    _dataCtrl.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _duracaoCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  // Seletor de data aplicando a regra de proibir datas futuras
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? colhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // CRITÉRIO DE ACEITE: Não permite escolher data futura
    );

    if (colhida != null && colhida != _dataSelecionada) {
      setState(() {
        _dataSelecionada = colhida;
        _dataCtrl.text = DateFormat('dd/MM/yyyy').format(colhida);
      });
    }
  }

  void _registrarServico() async {
    if (_formKey.currentState!.validate()) {
      String placaTratada = _placaCtrl.text.toUpperCase().trim();
      double valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));
      int duracao = int.parse(_duracaoCtrl.text);

      // FLUXO ALTERNATIVO: Validação de valor mínimo de R$ 50,00
      if (valor < 50.00) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: O valor mínimo do serviço deve ser R\$ 50,00.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      // Exibe indicador de progresso simples
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF))),
      );

      bool sucesso = await _servicoCtrl.adicionarServico(
        placa: placaTratada,
        descricao: _descricaoCtrl.text,
        valor: valor,
        duracao: duracao,
        dataServico: _dataSelecionada,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove o loading dialógico

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço registrado com sucesso no banco!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna verdadeiro para a tela de Perfil atualizar as listas
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Verifique se a placa do veículo está cadastrada no sistema.'),
            backgroundColor: Colors.red,
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
          'Registrar Serviço',
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
                    'Placa do Veículo',
                    estiloBorda,
                    controller: _placaCtrl,
                    hint: 'ABC1D23',
                    inputFormatters: [mascaraPlaca],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Insira a placa do veículo';
                      if (value.trim().length < 7) return 'A placa deve conter 7 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Descrição do Serviço',
                    estiloBorda,
                    controller: _descricaoCtrl,
                    hint: 'Ex: Troca de óleo, alinhamento...',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Insira a descrição do serviço';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Valor do Serviço (R\$)',
                    estiloBorda,
                    controller: _valorCtrl,
                    hint: 'Ex: 199.99',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')), // CRITÉRIO DE ACEITE: Apenas números/decimais
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Insira o valor do serviço';
                      final valorConvertido = double.tryParse(value.replaceAll(',', '.'));
                      if (valorConvertido == null) return 'Insira um número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Duração Estimada (horas)',
                    estiloBorda,
                    controller: _duracaoCtrl,
                    hint: 'Ex: 2',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // CRITÉRIO DE ACEITE: Apenas números inteiros
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Insira a duração estimada';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Novo campo visual para seleção de data sem digitação livre
                  TextFormField(
                    controller: _dataCtrl,
                    readOnly: true,
                    onTap: () => _selecionarData(context),
                    decoration: InputDecoration(
                      labelText: 'Data da Execução',
                      suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1E40AF)),
                      filled: true,
                      fillColor: const Color(0xFFE5E7EB),
                      border: estiloBorda,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _registrarServico,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    List<dynamic>? inputFormatters,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters?.cast<TextInputFormatter>(),
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
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1)),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}