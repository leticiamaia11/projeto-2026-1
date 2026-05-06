import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/tela_cadastro.dart';
import 'package:projeto_integrador/tela_login.dart';

class TelaSplash extends StatelessWidget {
  const TelaSplash({super.key});

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
              child: const Text(
                'Criar conta',
                style: TextStyle(color: Color(0xFF000000), fontSize: 24),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB7E0EF),
                minimumSize: const Size(200, 48),
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
                      color: Color(0xFFFFFFFFF),
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
