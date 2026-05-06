import 'package:flutter/material.dart';
import 'package:projeto_integrador/tela_splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Engetec',
      debugShowCheckedModeBanner: false,
      home: const TelaSplash(),
    );
  }
}

