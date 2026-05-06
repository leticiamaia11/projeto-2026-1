import 'package:flutter/material.dart';

class TelaUsuarios extends StatelessWidget {
  const TelaUsuarios({super.key});

  final List<String> usuarios = const [
    'Ana Santos',
    'João Silva',
    'Maria Lima',
    'Carlos Souza',
    'Paula Mendes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      body: ListView.builder(
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text(usuarios[index][0])),
            title: Text(usuarios[index]),
            subtitle: const Text('usuario@email.com'),
          );
        },
      ),
    );
  }
}
