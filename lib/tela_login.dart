import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/controllers/usuario_controller.dart';
import 'package:projeto_integrador/tela_principal.dart';
import 'package:projeto_integrador/tela_splash.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  // Instância do controlador compartilhado
  final UsuarioController _usuarioController = UsuarioController();

  // Controladores para capturar o input do usuário
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Estado que gerencia a exibição do indicador de progresso
  bool _estaCarregando = false;

  @override
  void dispose() {
    // Libera os recursos da memória ao fechar a tela de login
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Executa o fluxo de envio e resposta
  Future<void> _autenticar() async {
    setState(() {
      _estaCarregando = true;
    });

    // Envia os dados da tela para processamento no Controller
    String? mensagemErro = await _usuarioController.fazerLogin(
      cpfBruto: _cpfController.text,
      senha: _senhaController.text,
    );

    setState(() {
      _estaCarregando = false;
    });

    // Controle do fluxo visual baseado na resposta da arquitetura
    if (mensagemErro == null) {
      _mostrarSnackBar('Login realizado com sucesso!', Colors.green);

      if (mounted) {
        // Direciona para a home do aplicativo limpando o histórico de telas
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TelaPrincipal()),
          (route) => false,
        );
      }
    } else {
      // Exibe os erros tratados que retornaram do controlador
      _mostrarSnackBar(mensagemErro, Colors.red);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          'Fazer Login',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaSplash()), ///////// REQUISITO ATENDIDO: Voltar para a tela de splash ao invés de fechar o app
          ),
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
                // Ajustado de CNPJ para CPF para corresponder ao modelo padrão do Usuário
                _buildTextField('CPF', estiloBorda, controller: _cpfController, hint: '000.000.000-00', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField('Senha', estiloBorda, controller: _senhaController, obscure: true),
                const SizedBox(height: 24),
                
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
                      const TextSpan(text: 'Esqueceu a senha? '),
                      TextSpan(
                        text: 'Clique aqui',
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Lógica futura para recuperação
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Exibe loading ou botão ativo de acordo com o estado do app
                _estaCarregando
                    ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
                    : ElevatedButton(
                        onPressed: _autenticar,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                          backgroundColor: const Color(0xFF1E40AF), // Azul ativo para combinar com o layout
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar internalizada para herdar o comportamento e receber o controller devidamente
  Widget _buildTextField(
    String label, 
    OutlineInputBorder border, {
    required TextEditingController controller,
    bool obscure = false, 
    String? hint, 
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}