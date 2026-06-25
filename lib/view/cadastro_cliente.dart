import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/cliente_controller.dart';
import '../models/cliente.dart';

class TelaCadastroCliente extends StatefulWidget {
  final ClienteController clienteController;
  // 🟢 Adicionado para permitir a edição
  final Cliente? clienteParaEditar; 

  const TelaCadastroCliente({
    super.key,
    required this.clienteController,
    this.clienteParaEditar, // Opcional
  });

  @override
  State<TelaCadastroCliente> createState() => _TelaCadastroClienteState();
}

class _TelaCadastroClienteState extends State<TelaCadastroCliente> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  bool _enviandoDados = false;

  var mascaraCpf = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  var mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    // 🟢 Se houver cliente, preenche os campos automaticamente
    if (widget.clienteParaEditar != null) {
      final c = widget.clienteParaEditar!;
      _nomeCtrl.text = c.nomeCompleto;
      _cpfCtrl.text = mascaraCpf.maskText(c.cpf);
      _telefoneCtrl.text = mascaraTelefone.maskText(c.telefone);
      _emailCtrl.text = c.email;
      _enderecoCtrl.text = c.endereco ?? '';
      _observacoesCtrl.text = c.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _enderecoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarDados() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _enviandoDados = true);
      
      String cpfLimpo = mascaraCpf.getUnmaskedText();
      bool sucesso = false;

      if (widget.clienteParaEditar == null) {
        // 🟢 LÓGICA DE CADASTRO
        sucesso = await widget.clienteController.processarCadastroCliente(
          nome: _nomeCtrl.text,
          cpf: cpfLimpo,
          telefone: _telefoneCtrl.text,
          email: _emailCtrl.text,
          endereco: _enderecoCtrl.text.isEmpty ? null : _enderecoCtrl.text,
          observacoes: _observacoesCtrl.text.isEmpty ? null : _observacoesCtrl.text,
        );
      } else {
        // 🟢 LÓGICA DE EDIÇÃO
        Cliente clienteAtualizado = Cliente(
          id: widget.clienteParaEditar!.id,
          nomeCompleto: _nomeCtrl.text,
          cpf: cpfLimpo,
          telefone: _telefoneCtrl.text,
          email: _emailCtrl.text,
          endereco: _enderecoCtrl.text,
          observacoes: _observacoesCtrl.text,
        );
        sucesso = await widget.clienteController.atualizarCliente(clienteAtualizado);
      }

      if (!mounted) return;
      setState(() => _enviandoDados = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.clienteParaEditar == null 
                ? 'Cliente cadastrado com sucesso!' 
                : 'Cliente atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Verifique os dados ou conexão.'),
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
        title: Text(
          widget.clienteParaEditar == null ? 'Registrar Cliente' : 'Editar Cliente',
          style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
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
                children: [
                  _buildTextField('Nome Completo', estiloBorda, controller: _nomeCtrl, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  const SizedBox(height: 16),
                  _buildTextField('CPF', estiloBorda, controller: _cpfCtrl, inputFormatters: [mascaraCpf], keyboardType: TextInputType.number, validator: (value) {
    if (value == null || value.isEmpty) return 'Informe o CPF';
    
    // 🟢 Limpa qualquer caractere que não seja número
    String apenasNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (apenasNumeros.length != 11) {
      return 'O CPF deve ter 11 dígitos';
    }
    return null;
  },
  ),
                  const SizedBox(height: 16),
                  _buildTextField('Telefone', estiloBorda, controller: _telefoneCtrl, inputFormatters: [mascaraTelefone], keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('E-mail', estiloBorda, controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField('Endereço', estiloBorda, controller: _enderecoCtrl),
                  const SizedBox(height: 16),
                  _buildTextField('Observações', estiloBorda, controller: _observacoesCtrl, maxLines: 3),
                  const SizedBox(height: 32),
                  _enviandoDados
                      ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
                      : ElevatedButton(
                          onPressed: _salvarDados,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            widget.clienteParaEditar == null ? 'Salvar Cliente' : 'Atualizar Cliente',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildTextField(String label, OutlineInputBorder border, {TextEditingController? controller, FormFieldValidator<String>? validator, List<dynamic>? inputFormatters, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters?.cast<TextInputFormatter>(),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}