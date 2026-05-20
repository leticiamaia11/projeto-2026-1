import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:projeto_integrador/tela_splash.dart';

void main() {
  initializeDateFormatting();
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

