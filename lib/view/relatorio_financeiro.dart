import 'package:flutter/material.dart';

class TelaRelatorio extends StatelessWidget {
  const TelaRelatorio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Relatório',
          style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Tela de Relatório - Em construção',
          style: TextStyle(fontSize: 18, color: Color(0xFF1E40AF)),
        ),
       ),
     );
   }
}