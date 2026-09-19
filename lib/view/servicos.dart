import 'package:flutter/material.dart';
import 'package:projeto_integrador/controllers/servico_controller.dart';
import 'package:projeto_integrador/models/veiculo.dart';

class TelaServicos extends StatefulWidget {
  final ServicoController servicoController;

  const TelaServicos({super.key, required this.servicoController});

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();

  String? _placaSelecionada;
  List<Veiculo> _listaDeVeiculos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  Future<void> _carregarVeiculos() async {
    try {
      await widget.servicoController.veiculoController
          .carregarVeiculosDoBanco();
      if (mounted) {
        setState(() {
          _listaDeVeiculos = widget.servicoController.veiculoController
              .obterVeiculosOrdenados();
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
      }
      debugPrint("Erro ao carregar veículos para o dropdown: $e");
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _duracaoCtrl.dispose();
    super.dispose();
  }

  void _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      if (_placaSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Por favor, selecione um veículo."),
          ),
        );
        return;
      }

      setState(() => _carregando = true);

      bool sucesso = await widget.servicoController.adicionarServico(
        placa: _placaSelecionada!,
        descricao: _descricaoCtrl.text.trim(),
        valor: double.tryParse(_valorCtrl.text.trim()) ?? 0.0,
        duracao: int.tryParse(_duracaoCtrl.text.trim()) ?? 1,
        dataServico: DateTime.now(),
      );

      if (mounted) {
        setState(() => _carregando = false);
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text("Serviço registrado com sucesso!"),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text("Erro ao salvar serviço."),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantendo o padrão de borda definido na tela de veículos
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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _carregando
            ? const CircularProgressIndicator(color: Color(0xFF1E40AF))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: 350, // Mantém o tamanho fixo padrão do app
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // COMPONENTE DROPDOWN TOTALMENTE PADRONIZADO
                        DropdownButtonFormField<String>(
                          value: _placaSelecionada,
                          hint: const Text("Escolha o veículo"),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Selecione o Veículo',
                            filled: true,
                            fillColor: const Color(0xFFE5E7EB),
                            border: estiloBorda,
                            enabledBorder: estiloBorda,
                            focusedBorder: estiloBorda.copyWith(
                              borderSide: const BorderSide(
                                color: Color(0xFF1E40AF),
                                width: 1,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.redAccent,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          items: _listaDeVeiculos.map((Veiculo veiculo) {
                            return DropdownMenuItem<String>(
                              value: veiculo.placa,
                              child: Text(
                                "${veiculo.modelo} (${veiculo.placa})",
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? novoValor) {
                            setState(() {
                              _placaSelecionada = novoValor;
                            });
                          },
                          validator: (value) => value == null
                              ? "Selecione um veículo obrigatoriamente"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Descrição (Utilizando a estrutura padrão)
                        _buildTextField(
                          'Descrição do Serviço',
                          estiloBorda,
                          controller: _descricaoCtrl,
                          hint: 'ex: Troca de Óleo',
                          validator: (v) => v!.isEmpty
                              ? "A descrição não pode ser vazia"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Valor Cobrado
                        _buildTextField(
                          'Valor Cobrado (R\$)',
                          estiloBorda,
                          controller: _valorCtrl,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Insira um valor válido" : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Tempo Estimado
                        _buildTextField(
                          'Tempo Estimado (em horas)',
                          estiloBorda,
                          controller: _duracaoCtrl,
                          hint: 'ex: 2',
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? "Insira o tempo de duração" : null,
                        ),
                        const SizedBox(height: 32),

                        // BOTÃO GRAVAR ADAPTADO NO ESTILO STADIUM
                        ElevatedButton(
                          onPressed: _enviarFormulario,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Gravar Serviço',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

  // Função auxiliar herdada e unificada do padrão de inputs
  Widget _buildTextField(
    String label,
    OutlineInputBorder border, {
    TextEditingController? controller,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}