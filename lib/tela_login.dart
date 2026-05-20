import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/tela_principal.dart';

class TelaLogin extends StatelessWidget {
  const TelaLogin({super.key});

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
                _buildTextField('CNPJ', estiloBorda, hint: '00.000.000/0000-00', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField('Senha', estiloBorda, obscure: true),
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
                            // Lógica de recuperação
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TelaPrincipal()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ), // Fechamento do SingleChildScrollView
      ), // Fechamento do Center
    ); // Fechamento do Scaffold
  } // Fechamento do Build
} // Fechamento da Classe

// Função auxiliar (Fica fora da classe)
Widget _buildTextField(String label, OutlineInputBorder border, {bool obscure = false, String? hint, TextInputType? keyboardType}) {
  return TextFormField(
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
