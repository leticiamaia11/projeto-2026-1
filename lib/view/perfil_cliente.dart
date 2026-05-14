import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/tela_cadastro.dart';
import 'package:projeto_integrador/tela_login.dart';

class PerfilCliente extends StatelessWidget {
  const PerfilCliente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E40AF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Engetec',
              style: TextStyle(
                color: Color(0xFFB7E0EF),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.settings_suggest_sharp,
              size: 80,
              color: Color.fromARGB(255, 179, 179, 179),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 32),

            ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaCadastro()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48), // Largura fixa ou controlada pelo SizedBox pai
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: const StadiumBorder(), // Deixa o botão com bordas arredondadas
                  ),
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),

            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                children: [
                  const TextSpan(text: 'Já possui conta? '),
                  TextSpan(
                    text: 'Faça Login',
                    style: const TextStyle(
                      color: Color(0xFFB7E0EF),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaLogin()),
                        );
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
