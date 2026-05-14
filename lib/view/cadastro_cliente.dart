import 'package:flutter/material.dart';
import 'package:projeto_integrador/tela_cadastro.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/tela_principal.dart';

class TelaCadastroCliente extends StatelessWidget {
  const TelaCadastroCliente({super.key});
  @override
  Widget build(BuildContext context) {
    // Definimos um estilo padrão para evitar repetir código em todos os campos
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide:
          BorderSide.none, // Remove a linha para destacar a cor de fundo
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
        // Centraliza o conteúdo horizontalmente
        child: SingleChildScrollView(
          // Permite rolar a tela e evita erro de espaço
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 350, // Define a largura máxima dos campos e botão
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextField('Nome completo', estiloBorda),
                const SizedBox(height: 16),

                _buildTextField(
                  'E-mail',
                  estiloBorda,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Telefone',
                  estiloBorda,
                  hint: '(00) 00000-0000',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildTextField('Nome da Oficina', estiloBorda),
                const SizedBox(height: 16),

                _buildTextField(
                  'CNPJ',
                  estiloBorda,
                  hint: '00.000.000/0000-00',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildTextField('Senha', estiloBorda, obscure: true),
                const SizedBox(height: 16),

                _buildTextField('Confirmar senha', estiloBorda, obscure: true),
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

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaPrincipal()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Largura fixa ou controlada pelo SizedBox pai
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape:
                        const StadiumBorder(), // Deixa o botão com bordas arredondadas
                  ),
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: Colors.black,
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

  // Função auxiliar para não repetir código de TextFormField
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    bool obscure = false,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE5E7EB), // Cor de fundo cinza clara
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
