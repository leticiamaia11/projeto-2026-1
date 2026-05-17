import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/models/veiculo.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/view/lista_veiulos.dart';
import 'package:projeto_integrador/view/lista_veiulos.dart';
// Importe os arquivos da sua colega
// import 'package:app_engetec/controllers/veiculo_controller.dart';
// Importe sua tela principal/lista
// import 'package:app_engetec/tela_lista_veiculos.dart';

class TelaCadastroVeiculo extends StatefulWidget {
  const TelaCadastroVeiculo({super.key});

  @override
  State<TelaCadastroVeiculo> createState() => _TelaCadastroVeiculoState();
}

class _TelaCadastroVeiculoState extends State<TelaCadastroVeiculo> {
  // Chave global para o formulário (necessária para validação)
  final _formKey = GlobalKey<FormState>();

  // Instância do Controller da sua colega
  final _veiculoCtrl = VeiculoController();

  // Controllers para capturar os dados da tela
  final _modeloCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _proprietarioCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  // UX: Máscara para a placa (aceita formato antigo ABC-1234 e Mercosul ABC1D23)
  var mascaraPlaca = MaskTextInputFormatter(
    mask: '#######', // 7 caracteres alfanuméricos
    filter: {"#": RegExp(r'[a-zA-Z0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    // Boa prática: limpar os controllers ao sair da tela
    _modeloCtrl.dispose();
    _placaCtrl.dispose();
    _anoCtrl.dispose();
    _proprietarioCtrl.dispose();
    _corCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _realizarCadastro() {
    // 1. Valida o formulário visualmente (chama os validators dos campos)
    if (_formKey.currentState!.validate()) {
      // 2. Se visualmente estiver ok, chama a lógica complexa da colega
      
      bool sucesso = _veiculoCtrl.processarCadastro(
        modelo: _modeloCtrl.text,
        placa: _placaCtrl.text,
        ano: _anoCtrl.text, // O controller dela trata o opcional
        proprietario: _proprietarioCtrl.text,
      );

      // SIMULAÇÃO (Remova quando conectar o controller dela)
      // bool sucesso = true;
      //print("Placa formatada: ${mascaraPlaca.getMaskedText().toUpperCase()}");

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // UX: Volta para a lista de veículos
        Navigator.pop(context);
      } else {
        // Se a lógica falhar (ex: placa duplicada)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Esta placa já existe no sistema.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantendo o estilo de borda definida
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Registrar Veículo', 
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
            // Envolver a coluna com o Widget Form
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CAMPO MODELO (Obrigatório)
                  _buildTextField(
                    'Modelo do Veículo',
                    estiloBorda,
                    controller: _modeloCtrl,
                    hint: 'ex: Toyota Corolla',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o modelo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO PLACA (Obrigatório com Validação)
                  _buildTextField(
                    'Placa',
                    estiloBorda,
                    controller: _placaCtrl,
                    hint: 'ABC1234',
                    inputFormatters: [mascaraPlaca], // Aplica a máscara
                    textCapitalization: TextCapitalization.characters, // Força maiúsculas
                    keyboardType: TextInputType.visiblePassword, // Evita corretor
                    validator: (value) {
                      // UX: Primeiro valida se está vazio
                      if (value == null || value.isEmpty) {
                        return 'Informe a placa';
                      }
                      // UX: Depois chama a validação lógica 
                      return _veiculoCtrl.validarPlaca(value);
                      
                      // SIMULAÇÃO (Remova quando conectar o controller dela)
                      //if (value.length != 7) return "Placa inválida (7 caracteres)";
                      //return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO PROPRIETÁRIO (Obrigatório)
                  // UX Future: Mudar para Dropdown buscando do Model Cliente
                  _buildTextField(
                    'Nome do Proprietário',
                    estiloBorda,
                    controller: _proprietarioCtrl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o nome do cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO ANO (Opcional com Validação)
                  _buildTextField(
                    'Ano (Opcional)',
                    estiloBorda,
                    controller: _anoCtrl,
                    hint: 'yyyy',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      // UX: Chama a validação opcional 
                      return _veiculoCtrl.validarAno(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO COR (Opcional no Model)
                  _buildTextField(
                    'Cor (Opcional)',
                    estiloBorda,
                    controller: _corCtrl,
                  ),
                  const SizedBox(height: 16),

                  // CAMPO OBSERVAÇÕES (Opcional)
                  _buildTextField(
                    'Observações',
                    estiloBorda,
                    controller: _observacoesCtrl,
                    hint: 'ex: Risco na porta direita',
                    maxLines: 3, // Permite múltiplas linhas
                  ),

                  const SizedBox(height: 32),

                  // BOTÃO SALVAR
                  ElevatedButton(
                    onPressed: _realizarCadastro, // Chama a função de cadastro
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                      backgroundColor: const Color(0xFF1E40AF), // Mudei para o azul para destacar
                      shape: const StadiumBorder(),
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

  // Função auxiliar ADAPTADA para receber Controller, Validator e Formatters
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    List<dynamic>? inputFormatters,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      // inputFormatters precisa de List<TextInputFormatter>, convertendo dinamicamente
      inputFormatters: inputFormatters?.cast<MaskTextInputFormatter>(),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true, // Para alinhar label em campos maxLines > 1
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),

        // Estilo para a mensagem de erro (UX)
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}