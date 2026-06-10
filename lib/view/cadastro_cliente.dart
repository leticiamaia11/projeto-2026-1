import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/veículo_controller.dart'; 
import '../models/cliente.dart';

class TelaCadastroCliente extends StatefulWidget {
  // CORREÇÃO: Agora a tela exige receber o controlador ativo vindo da listagem
  final ClienteController clienteController;

  const TelaCadastroCliente({
    super.key,
    required this.clienteController,
  });

  @override
  State<TelaCadastroCliente> createState() => _TelaCadastroClienteState();
}

class _TelaCadastroClienteState extends State<TelaCadastroCliente> {
  // O Grampo da pasta (Chave do formulário)
  final _formKey = GlobalKey<FormState>();

  // CORREÇÃO: O Gerente da Oficina agora usa o controlador compartilhado ("widget.clienteController")
  // Apagada a linha antiga que criava um controlador do zero.

  // As Canetas Mágicas (Controllers para capturar o texto da tela)
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  // Estado para controlar a animação de envio ao Supabase
  bool _enviandoDados = false;

  // UX: Filtros de Proteção (Máscaras de preenchimento)
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
    // Não precisamos mais forçar carregarClientesDoBanco() aqui, 
    // pois a tela anterior já cuidou disso!
  }

  @override
  void dispose() {
    // Limpando as canetas ao fechar a tela para não pesar a memória
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _enderecoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  // REQUISITO ATENDIDO: Método transformado em assíncrono para esperar o Supabase
  Future<void> _realizarCadastro() async {
    // 1. Validação Visual do Formulário
    if (_formKey.currentState!.validate()) {
      setState(() {
        _enviandoDados = true; // Ativa o modo de carregamento
      });
      
      // Pegamos o CPF limpo (sem os pontos e traço da máscara) para mandar para o controller
      String cpfLimpo = mascaraCpf.getUnmaskedText();

      // 2. CORREÇÃO: Chama o método usando o prefixo "widget." para acessar o controlador injetado
      bool sucesso = await widget.clienteController.processarCadastroCliente(
        nome: _nomeCtrl.text,
        cpf: cpfLimpo, 
        telefone: _telefoneCtrl.text,
        email: _emailCtrl.text,
        endereco: _enderecoCtrl.text.isEmpty ? null : _enderecoCtrl.text,
        observacoes: _observacoesCtrl.text.isEmpty ? null : _observacoesCtrl.text,
      );

      if (!mounted) return;

      setState(() {
        _enviandoDados = false; // Desativa o carregamento após a resposta do servidor
      });

      // FLUXO PRINCIPAL E ALTERNATIVO ATENDIDOS
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retorna com sucesso para a tela de listagem atualizada
      } else {
        // Se cai aqui, é porque a trava de CPF foi acionada ou houve falha de conexão
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Este CPF já está registrado ou os dados são inválidos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilo padrão arredondado sem linhas pretas
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Registrar Cliente',
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
            width: 350, // Mantendo o padrão de largura ideal para mobile/desktop
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CAMPO NOME (Obrigatório)
                  _buildTextField(
                    'Nome Completo',
                    estiloBorda,
                    controller: _nomeCtrl,
                    hint: 'ex: João da Silva',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO CPF (Obrigatório com Máscara)
                  _buildTextField(
                    'CPF',
                    estiloBorda,
                    controller: _cpfCtrl,
                    hint: '000.000.000-00',
                    inputFormatters: [mascaraCpf],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o CPF';
                      }
                      if (mascaraCpf.getUnmaskedText().length != 11) {
                        return 'O CPF deve ter 11 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO TELEFONE (Obrigatório com Máscara)
                  _buildTextField(
                    'Telefone',
                    estiloBorda,
                    controller: _telefoneCtrl,
                    hint: '(00) 00000-0000',
                    inputFormatters: [mascaraTelefone],
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o telefone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO E-MAIL (Obrigatório)
                  _buildTextField(
                    'E-mail',
                    estiloBorda,
                    controller: _emailCtrl,
                    hint: 'joao@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'Digite um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO ENDEREÇO (Opcional)
                  _buildTextField(
                    'Endereço (Opcional)',
                    estiloBorda,
                    controller: _enderecoCtrl,
                    hint: 'Rua, Número, Bairro',
                  ),
                  const SizedBox(height: 16),

                  // CAMPO OBSERVAÇÕES (Opcional)
                  _buildTextField(
                    'Observações (Opcional)',
                    estiloBorda,
                    controller: _observacoesCtrl,
                    hint: 'ex: Cliente prefere contato via WhatsApp',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // BOTÃO SALVAR COM FEEDBACK DE PROGRESSO
                  _enviandoDados
                      ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
                      : ElevatedButton(
                          onPressed: _realizarCadastro,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                            backgroundColor: const Color(0xFF1E40AF), // Azul Identidade Engetec
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Salvar Cliente',
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

  // Função auxiliar idêntica à de veículo para reuso de design
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
        fillColor: const Color(0xFFE5E7EB), // Cinza claro padrão
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}