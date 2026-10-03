import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/models/veiculo.dart';

class TelaServicos extends StatefulWidget {
  final ServicoController servicoController;

  const TelaServicos({
    super.key,
    required this.servicoController,
  });

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos.
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();

  String? _placaSelecionada;

  List<Veiculo> _listaDeVeiculos = [];

  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  // ============================================================
  // CARREGA OS VEÍCULOS DO SUPABASE
  // ============================================================
  Future<void> _carregarVeiculos() async {
    try {
      await widget.servicoController.veiculoController
          .carregarVeiculosDoBanco();

      if (!mounted) return;

      setState(() {
        _listaDeVeiculos = widget
            .servicoController
            .veiculoController
            .obterVeiculosOrdenados();

        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar veículos para o dropdown: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Erro ao carregar veículos: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _duracaoCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // CONVERTE O VALOR DIGITADO
  // ============================================================
  double? _converterValor(String texto) {
    String valor = texto.trim();

    if (valor.isEmpty) {
      return null;
    }

    // Aceita tanto:
    // 150.50
    // 150,50
    valor = valor.replaceAll(',', '.');

    return double.tryParse(valor);
  }

  // ============================================================
  // SALVAR SERVIÇO
  // ============================================================
  Future<void> _enviarFormulario() async {
    // Primeiro valida os campos do formulário.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verifica se algum veículo foi selecionado.
    if (_placaSelecionada == null ||
        _placaSelecionada!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Por favor, selecione um veículo.',
          ),
        ),
      );

      return;
    }

    // Converte o valor corretamente.
    final valor = _converterValor(
      _valorCtrl.text,
    );

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Digite um valor válido maior que zero.',
          ),
        ),
      );

      return;
    }

    // Converte a duração.
    final duracao = int.tryParse(
      _duracaoCtrl.text.trim(),
    );

    if (duracao == null || duracao <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Digite uma duração válida maior que zero.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _salvando = true;
    });

    // ----------------------------------------------------------
    // CHAMA O CONTROLLER
    // ----------------------------------------------------------
    final sucesso =
        await widget.servicoController.adicionarServico(
      placa: _placaSelecionada!,
      descricao: _descricaoCtrl.text.trim(),
      valor: valor,
      duracao: duracao,
      dataServico: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _salvando = false;
    });

    // ----------------------------------------------------------
    // SUCESSO
    // ----------------------------------------------------------
    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Serviço registrado com sucesso!',
          ),
        ),
      );

      Navigator.pop(context, true);

      return;
    }

    // ----------------------------------------------------------
    // ERRO
    // ----------------------------------------------------------
    final erro =
        widget.servicoController.ultimoErro ??
        'Erro desconhecido ao salvar o serviço.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
              ),
              SizedBox(width: 8),
              Text('Erro ao salvar'),
            ],
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              erro,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mantém o padrão visual das outras telas.
    final estiloBorda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),

      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Registrar Serviço',
          style: TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1E40AF),
          ),
          onPressed: _salvando
              ? null
              : () => Navigator.pop(context),
        ),
      ),

      body: Center(
        child: _carregando
            ? const CircularProgressIndicator(
                color: Color(0xFF1E40AF),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: 350,

                  child: Form(
                    key: _formKey,

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        // ==================================================
                        // VEÍCULO
                        // ==================================================
                        DropdownButtonFormField<String>(
                          value: _placaSelecionada,

                          hint: const Text(
                            'Escolha o veículo',
                          ),

                          isExpanded: true,

                          decoration: InputDecoration(
                            labelText:
                                'Selecione o Veículo',

                            filled: true,

                            fillColor:
                                const Color(0xFFE5E7EB),

                            border: estiloBorda,

                            enabledBorder:
                                estiloBorda,

                            focusedBorder:
                                estiloBorda.copyWith(
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(0xFF1E40AF),
                                width: 1,
                              ),
                            ),

                            errorStyle:
                                const TextStyle(
                              color:
                                  Colors.redAccent,
                            ),

                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),

                          items: _listaDeVeiculos
                              .map(
                            (Veiculo veiculo) {
                              return DropdownMenuItem<
                                  String>(
                                value: veiculo.placa,

                                child: Text(
                                  '${veiculo.modelo} (${veiculo.placa})',

                                  style:
                                      const TextStyle(
                                    fontSize: 14,
                                  ),

                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              );
                            },
                          ).toList(),

                          onChanged: _salvando
                              ? null
                              : (novoValor) {
                                  setState(() {
                                    _placaSelecionada =
                                        novoValor;
                                  });
                                },

                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Selecione um veículo obrigatoriamente';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DESCRIÇÃO
                        // ==================================================
                        _buildTextField(
                          'Descrição do Serviço',
                          estiloBorda,
                          controller:
                              _descricaoCtrl,
                          hint:
                              'ex: Troca de Óleo',
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'A descrição não pode ser vazia';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // VALOR
                        // ==================================================
                        _buildTextField(
                          'Valor Cobrado (R\$)',
                          estiloBorda,
                          controller:
                              _valorCtrl,
                          hint: '0,00',

                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),

                          validator: (v) {
                            final valor =
                                _converterValor(
                              v ?? '',
                            );

                            if (valor == null ||
                                valor <= 0) {
                              return 'Insira um valor maior que zero';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DURAÇÃO
                        // ==================================================
                        _buildTextField(
                          'Tempo Estimado (em horas)',
                          estiloBorda,
                          controller:
                              _duracaoCtrl,
                          hint: 'ex: 2',

                          keyboardType:
                              TextInputType.number,

                          validator: (v) {
                            final duracao =
                                int.tryParse(
                              v?.trim() ?? '',
                            );

                            if (duracao == null ||
                                duracao <= 0) {
                              return 'Insira uma duração válida';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // ==================================================
                        // BOTÃO
                        // ==================================================
                        ElevatedButton(
                          onPressed:
                              _salvando
                                  ? null
                                  : _enviarFormulario,

                          style:
                              ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(
                              200,
                              48,
                            ),

                            backgroundColor:
                                const Color(
                              0xFF1E40AF,
                            ),

                            shape:
                                const StadiumBorder(),
                          ),

                          child: _salvando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Gravar Serviço',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
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

  // ============================================================
  // CAMPO PADRÃO
  // ============================================================
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    required TextEditingController controller,
    FormFieldValidator<String>? validator,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,

      validator: validator,

      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        hintText: hint,

        filled: true,

        fillColor:
            const Color(0xFFE5E7EB),

        border: border,

        enabledBorder: border,

        focusedBorder:
            border.copyWith(
          borderSide:
              const BorderSide(
            color:
                Color(0xFF1E40AF),
            width: 1,
          ),
        ),

        errorStyle:
            const TextStyle(
          color: Colors.redAccent,
        ),

        focusedErrorBorder:
            border.copyWith(
          borderSide:
              const BorderSide(
            color:
                Colors.redAccent,
            width: 1,
          ),
        ),

        errorBorder:
            border.copyWith(
          borderSide:
              const BorderSide(
            color:
                Colors.redAccent,
            width: 0.5,
          ),
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}