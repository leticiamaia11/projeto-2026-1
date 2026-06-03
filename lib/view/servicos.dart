import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';

class TelaServicos extends StatefulWidget {
  //final VeiculoController veiculoController;

  const TelaServicos({super.key});

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  final _formKey = GlobalKey<FormState>();
  late final ServicoController _servicoCtrl;

  // Controllers para capturar as entradas do usuário
  final _placaCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();

  // UX: Máscara padrão Mercosul e Antiga (ABC-1234 ou ABC1D23)
  var mascaraPlaca = MaskTextInputFormatter(
    mask: '#######',
    filter: {
      "#": RegExp(r'[a-zA-Z0-9]'),
    }, // Permite letras e números, sem restrição de posição
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Limpa os controllers para evitar vazamento de memória
    _placaCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _duracaoCtrl.dispose();
    super.dispose();
  }

  // Método assíncrono simplificado, apenas aguardando o retorno do controller
  void _registrarServico() async {
    if (_formKey.currentState!.validate()) {
      // Converte a placa para maiúscula para garantir consistência
      String placaTratada = _placaCtrl.text.toUpperCase().trim();
      double valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));
      int duracao = int.parse(_duracaoCtrl.text);

      // Aguarda o controller processar e dizer se deu certo ou não
      bool sucesso = await _servicoCtrl.adicionarServico(
        placa: placaTratada,
        descricao: _descricaoCtrl.text,
        valor: valor,
        duracao: duracao,
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volta para a tela anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro: Não foi possível registrar o serviço. Verifique se o veículo está cadastrado.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Converte a placa para maiúscula para garantir consistência
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
          style: TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
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
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a placa do veículo';
                      }
                      if (value.trim().length < 7) {
                        return 'A placa deve conter 7 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Descrição do Serviço',
                    estiloBorda,
                    controller: _descricaoCtrl,
                    hint: 'Ex: Troca de óleo, alinhamento, etc.',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a descrição do serviço';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Valor do Serviço (R\$)',
                    estiloBorda,
                    controller: _valorCtrl,
                    hint: 'Ex: 199.99',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o valor do serviço';
                      }
                      final valorConvertido = double.tryParse(
                        value.replaceAll(',', '.'),
                      );
                      if (valorConvertido == null) {
                        return 'Por favor, insira um valor numérico válido';
                      }
                      if (valorConvertido <= 0) {
                        return 'O valor do serviço deve ser maior que zero';
                      }
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a duração estimada do serviço';
                      }
                      final duracaoConvertida = int.tryParse(value);
                      if (duracaoConvertida == null) {
                        return 'Por favor, insira um número inteiro válido';
                      }
                      if (duracaoConvertida <= 0) {
                        return 'A duração do serviço deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botão simples apenas com texto estático
                  ElevatedButton(
                    onPressed: _registrarServico,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  // Método auxiliar para construir os campos de texto com estilo consistente
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
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
