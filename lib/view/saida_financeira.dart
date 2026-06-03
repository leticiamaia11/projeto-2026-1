import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';

class TelaSaidaFinanceira extends StatefulWidget {
  final ServicoController servicoController;

  const TelaSaidaFinanceira({super.key, required this.servicoController});

  @override
  State<TelaSaidaFinanceira> createState() => _TelaSaidaFinanceiraState();
}

class _TelaSaidaFinanceiraState extends State<TelaSaidaFinanceira> {
  // Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  // Controllers para capturar o texto dos inputs
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  // Variável para armazenar o objeto DateTime selecionado
  DateTime? _dataSelecionada;

  // UX: Filtro de Proteção para o valor monetário (Apenas números)
  var mascaraValor = MaskTextInputFormatter(
    mask: '##########',
    filter: {"#": RegExp(r'[0-9.]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    // Limpando ao fechar a tela 
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _dataCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  // Abre o calendário nativo do aparelho para escolha da data
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
              primary: Color(0xFF1E40AF), // Cor azul identidade da oficina
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
        // Formata visualmente para o usuário dentro do input
        _dataCtrl.text = "${selecionado.day.toString().padLeft(2, '0')}/${selecionado.month.toString().padLeft(2, '0')}/${selecionado.year}";
      });
    }
  }

  // Realiza a validação local e salva os dados no Controller / Banco de Dados
  Future<void> _realizarRegistro() async {
    // 1. Validação Visual dos campos obrigatórios
    if (_formKey.currentState!.validate()) {
      
      // Converte o texto digitado para double puro aceito pelo sistema de somas
      final valorTratado = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

      // Unifica o título e a descrição para salvar na propriedade de histórico
      final descricaoCompleta = "${_tituloCtrl.text} - ${_descricaoCtrl.text}";

      // 2. Integração com o Controller / Sincronização futura com o Banco de dados
      // Criamos um objeto dinâmico temporário contendo valor e data conforme esperado pelo relatório
      final novoGasto = _ObjetoFinanceiro(
        descricao: descricaoCompleta,
        valor: valorTratado,
        data: _dataSelecionada ?? DateTime.now(),
      );

      // TODO: Conexão futura com o Banco de Dados (Supabase/Firebase):
      // No futuro, o método do seu controller fará um escopo assíncrono:
      // await widget.servicoController.enviarSaidaParaOBanco(novoGasto);
      
      // Armazena na lista reativa de gastos internos na memória estável
      widget.servicoController.listaDeGastos.add(novoGasto);

      // Feedback visual de sucesso para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saída financeira registrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Retorna fechando a tela e atualizando o relatório
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilo padrão arredondado sem bordas pretas (idêntico ao de Clientes)
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
            width: 350, // Largura padrão ideal para mobile e desktop comprimido
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CAMPO TÍTULO
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

                  // CAMPO DESCRIÇÃO
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

                  // CAMPO DATA (Com GestureDetector para disparar o DatePicker)
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

                  // CAMPO VALOR TOTAL
                  _buildTextField(
                    'Valor Total',
                    estiloBorda,
                    controller: _valorCtrl,
                    hint: 'R\$ 0,00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor total gasto';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Digite um valor numérico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // BOTÃO REGISTRAR (Estilo cápsula cinza/azul idêntico ao mockup)
                  ElevatedButton(
                    onPressed: _realizarRegistro,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: const Color(0xFFE5E7EB), // Fundo acinzentado conforme imagem
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

  // Componente de campo de texto customizado adaptado para suportar ícones de sufixo
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    List<dynamic>? inputFormatters,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
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
        fillColor: const Color(0xFFE5E7EB), // Cinza claro idêntico ao cadastro de clientes
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

// Classe de Modelo auxiliar para estruturar os dados de Gastos na ausência do arquivo definitivo
class _ObjetoFinanceiro {
  final String descricao;
  final double valor;
  final DateTime data;

  _ObjetoFinanceiro({
    required this.descricao,
    required this.valor,
    required this.data,
  });
}