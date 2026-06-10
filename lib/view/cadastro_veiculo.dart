import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:projeto_integrador/models/veiculo.dart';
import 'package:projeto_integrador/controllers/veículo_controller.dart';
import 'package:projeto_integrador/view/lista_veiulos.dart';
import 'package:projeto_integrador/models/cliente.dart';
import 'package:projeto_integrador/controllers/cliente_controller.dart';

class TelaCadastroVeiculo extends StatefulWidget {
  // CORREÇÃO: Exige receber o controlador de clientes ativo vindo da listagem
  final ClienteController clienteController;

  const TelaCadastroVeiculo({
    super.key,
    required this.clienteController,
  });

  @override
  State<TelaCadastroVeiculo> createState() => _TelaCadastroVeiculoState();
}

class _TelaCadastroVeiculoState extends State<TelaCadastroVeiculo> {
  // Chave global para o formulário (necessária para validação)
  final _formKey = GlobalKey<FormState>();

  // Instância do Controller que gerencia a lógica de cadastro de veículos
  final _veiculoCtrl = VeiculoController();

  // CORREÇÃO: Removida a linha que criava um ClienteController isolado do zero.
  // Agora usamos diretamente o "widget.clienteController".

  // Controllers para capturar os dados da tela
  final _modeloCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  // Variável para armazenar o objeto do cliente selecionado no dropdown
  Cliente? _clienteSelecionado;

  // Estado para controlar o feedback visual de salvamento na nuvem
  bool _enviandoDados = false;

  // AJUSTE: Controla o estado de requisição do banco para o dropdown não quebrar
  bool _carregandoClientes = true; 

  // UX: Máscara para a placa (aceita formato antigo ABC-1234 e Mercosul ABC1D23)
  var mascaraPlaca = MaskTextInputFormatter(
    mask: '#######', // 7 caracteres alfanuméricos
    filter: {"#": RegExp(r'[a-zA-Z0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _buscarClientesParaDropdown();
  }

  // CORREÇÃO: Função assíncrona robusta para garantir que os dados do Supabase chegaram antes de desenhar o Dropdown
  Future<void> _buscarClientesParaDropdown() async {
    try {
      // CORREÇÃO: Garante que os clientes estão carregados no controlador compartilhado
      await widget.clienteController.carregarClientesDoBanco();
    } catch (e) {
      print("Erro ao carregar clientes no Dropdown: $e");
    } finally {
      if (mounted) {
        setState(() {
          _carregandoClientes = false; // Libera o dropdown para renderizar com segurança
        });
      }
    }
  }

  @override
  void dispose() {
    // Boa prática: limpar os controllers ao sair da tela
    _modeloCtrl.dispose();
    _placaCtrl.dispose();
    _anoCtrl.dispose();
    _corCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  // REQUISITO ATENDIDO: Método transformado em Future assíncrono para o Supabase
  Future<void> _realizarCadastro() async {
    // 1. Valida o formulário visualmente (chama os validators dos campos)
    if (_formKey.currentState!.validate() && _clienteSelecionado != null) {
      setState(() {
        _enviandoDados = true; // Ativa animação de carregamento
      });

      // 2. Chama a lógica de cadastro no controller aguardando a resposta do banco
      bool sucesso = await _veiculoCtrl.processarCadastro(
        modelo: _modeloCtrl.text,
        placa: _placaCtrl.text.toUpperCase(), // Garante placa em maiúscula no banco
        ano: _anoCtrl.text, 
        proprietario: _clienteSelecionado!.nomeCompleto,
      );

      if (sucesso) {
        // CORREÇÃO: Vincula o carro usando o controlador herdado (atualiza a memória local da listagem)
        await widget.clienteController.adicionarNovoVeiculo(
          placa: _placaCtrl.text.toUpperCase(),
          modelo: _modeloCtrl.text,
          donoSelecionado: _clienteSelecionado!,
        );
      }

      if (!mounted) return;

      setState(() {
        _enviandoDados = false; // Desativa animação de carregamento
      });

      // CRITÉRIOS DE ACEITE ATENDIDOS (Fluxo principal e alternativo)
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // UX: Volta para a lista com tudo atualizado
        Navigator.pop(context);
      } else {
        // Se a lógica falhar (ex: placa duplicada ou erro de conexão)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Esta placa já existe no sistema ou erro de rede.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um proprietário na lista.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantendo o estilo de borda definida
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Registrar Veículo', 
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CAMPO MODELO (Obrigatório)
                  _buildTextField(
                    'Modelo do Veículo',
                    estiloBorda,
                    controller: _modeloCtrl,
                    hint: 'ex: Toyota Corolla',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o modelo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO PLACA (Obrigatório com Validação)
                  _buildTextField(
                    'Placa',
                    estiloBorda,
                    controller: _placaCtrl,
                    hint: 'ABC1234',
                    inputFormatters: [mascaraPlaca], // Aplica a máscara
                    textCapitalization: TextCapitalization.characters, // Força maiúsculas
                    keyboardType: TextInputType.visiblePassword, // Evita corretor
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a placa';
                      }
                      return _veiculoCtrl.validarPlaca(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO PROPRIETÁRIO (Obrigatório) - CORRIGIDO: dropdown usando widget.clienteController + Feedback de Loading
                  _carregandoClientes
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                        )
                      : DropdownButtonFormField<Cliente>(
                          decoration: InputDecoration(
                            labelText: 'Nome do Proprietário',
                            filled: true,
                            fillColor: const Color(0xFFE5E7EB),
                            border: estiloBorda,
                            enabledBorder: estiloBorda,
                            focusedBorder: estiloBorda.copyWith(
                              borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
                            ),
                            errorStyle: const TextStyle(color: Colors.redAccent),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          // CORREÇÃO: Lê os clientes ordenados do controlador compartilhado ativo
                          items: widget.clienteController.obterClientesOrdenados().map((Cliente cliente) {
                            return DropdownMenuItem<Cliente>(
                              value: cliente,
                              child: Text(cliente.nomeCompleto),
                            );
                          }).toList(),
                          value: _clienteSelecionado,
                          onChanged: (Cliente? novoDono) {
                            setState(() {
                              _clienteSelecionado = novoDono;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Informe o nome do cliente';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),

                  // CAMPO ANO (Opcional com Validação)
                  _buildTextField(
                    'Ano (Opcional)',
                    estiloBorda,
                    controller: _anoCtrl,
                    hint: 'yyyy',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      return _veiculoCtrl.validarAno(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAMPO COR (Opcional)
                  _buildTextField(
                    'Cor (Opcional)',
                    estiloBorda,
                    controller: _corCtrl,
                  ),
                  const SizedBox(height: 16),

                  // CAMPO OBSERVAÇÕES (Opcional)
                  _buildTextField(
                    'Observações',
                    estiloBorda,
                    controller: _observacoesCtrl,
                    hint: 'ex: Risco na porta direita',
                    maxLines: 3, // Permite múltiplas linhas
                  ),

                  const SizedBox(height: 32),

                  // BOTÃO SALVAR ADAPTADO COM CARREGAMENTO
                  _enviandoDados
                      ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
                      : ElevatedButton(
                          onPressed: _realizarCadastro, 
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                            backgroundColor: const Color(0xFF1E40AF), 
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Registrar', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar CORRIGIDA para aceitar qualquer tipo de formatação sem quebrar o cast
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    List<dynamic>? inputFormatters,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters?.cast<TextInputFormatter>(),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true, 
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}