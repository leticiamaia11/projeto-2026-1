import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:projeto_integrador/tela_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Supabase.initialize(
    url: 'https://cqpyqjiyhxbkojaazewg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxcHlxaml5aHhia29qYWF6ZXdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MDkwOTcsImV4cCI6MjA5NTA4NTA5N30.BuywIVTcvWQQUIEQ_44ttUGgxgUGiLQ7oopRiQto9qc',
  );

  try {
    // Tentamos ler apenas 1 linha de uma tabela qualquer (ex: 'todos' ou 'usuarios')
    // Se a tabela não existir, ele vai dar um erro específico de tabela, o que já prova que CONECTOU!
    await Supabase.instance.client.from('todos').select().limit(1);
    
    print('🟢 [Supabase] STATUS: Conectado com sucesso ao banco de dados!');
  } catch (erro) {
    print('🔴 [Supabase] STATUS: Falha na conexão!');
    print('Erro detalhado: $erro');
  }

  runApp(const MyApp());
}

// Atalho para acessar o cliente do Supabase de qualquer lugar do app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       locale: const Locale('pt', 'BR'),
  supportedLocales: const [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'Engetec',
      debugShowCheckedModeBanner: false,
      home: const TelaSplash(),
    );
  }
}

