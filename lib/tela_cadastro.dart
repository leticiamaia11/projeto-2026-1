import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/controllers/usuario_controller.dart';
import 'package:projeto_integrador/tela_principal.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final UsuarioController _cadastrarUsuarioController = UsuarioController();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _estaCarregando = false;

  // UX: Filtros de Proteção (Máscaras de preenchimento idênticas à tela de cliente)
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
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  //===============================================================================
  //                      FLUXO DE INTERAÇÃO DA TELA (VIEW)
  //===============================================================================
  Future<void> _executarCadastro() async {
    setState(() {
      _estaCarregando = true;
    });

    // Envia os dados direto para o controller validar e processar
    String? mensagemErro = await _cadastrarUsuarioController.cadastrarUsuario(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      confirmarSenha: _confirmarSenhaController.text,
      cpfBruto: mascaraCpf.getUnmaskedText(), // Captura apenas os números limpos do CPF
    );

    //String? mensagemErro = null; // REMOVER ESTA LINHA APÓS IMPLEMENTAR O MÉTODO DE CADASTRO NO CONTROLLER

    setState(() {
      _estaCarregando = false;
    });

    // Tomada de decisão puramente visual baseada no retorno do Controller
    if (mensagemErro == null) {
      // FLUXO PRINCIPAL: Sucesso
      _mostrarSnackBar('Cadastro concluído com sucesso!', Colors.green);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TelaPrincipal()),
        );
      }
    } else {
      // FLUXO ALTERNATIVO: O controller devolveu um erro (validação ou banco)
      _mostrarSnackBar(mensagemErro, Colors.red);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cor,
        duration: const Duration(seconds: 3),
      ),
    );
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
          'Crie sua conta',
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextField(
                  'Nome completo',
                  estiloBorda,
                  controller: _nomeController,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'E-mail',
                  estiloBorda,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Telefone (Opcional)',
                  estiloBorda,
                  controller: _telefoneController,
                  hint: '(00) 00000-0000',
                  inputFormatters: [mascaraTelefone], // Vincula a máscara de telefone
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'CPF',
                  estiloBorda,
                  controller: _cpfController,
                  hint: '000.000.000-00',
                  inputFormatters: [mascaraCpf], // Vincula a máscara de CPF
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Senha',
                  estiloBorda,
                  controller: _senhaController,
                  obscure: true,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Confirmar senha',
                  estiloBorda,
                  controller: _confirmarSenhaController,
                  obscure: true,
                ),
                const SizedBox(height: 24),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Ao criar uma conta, você aceita os ',
                      ),
                      TextSpan(
                        text: 'termos e condições',
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Lógica dos termos
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _estaCarregando
                    ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
                    : ElevatedButton(
                        onPressed: _executarCadastro,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                          backgroundColor: const Color(0xFF1E40AF),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Criar conta',
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
    );
  }

  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    required TextEditingController controller,
    bool obscure = false,
    String? hint,
    List<dynamic>? inputFormatters, // Suporte para listas de formatação de texto
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters?.cast<TextInputFormatter>(), // Converte de forma segura os formatadores
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}