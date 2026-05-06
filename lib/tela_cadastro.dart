import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:projeto_integrador/tela_principal.dart';

class TelaCadastro extends StatelessWidget {
  const TelaCadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),

      appBar: AppBar(
        title: const Text('Crie sua conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Voltar para a tela anterior (TelaSplash)
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              keyboardType: TextInputType.number, // Para exibir o teclado numérico
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: '(00) 00000-0000',
                border: OutlineInputBorder(),
              ),
            ),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome da Oficina',
                border: OutlineInputBorder(),
              ),
            ),

            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                hintText: '00.000.000/0000-00',
                border: OutlineInputBorder(),
              ),
            ),

            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color.fromARGB(195, 0, 0, 0),
                  fontSize: 16,
                ),
                children: [
                  const TextSpan(text: 'Aceito os'),
                  TextSpan(
                    text: 'termos e condições',
                    style: const TextStyle(
                      color: Color(0x00000000),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaPrincipal(),
                          ), // Substitua pelos termos e condições quando implementados
                        );
                      },
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TelaPrincipal()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
