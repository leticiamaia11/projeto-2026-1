import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nota_fiscal.dart';
import '../models/registroServico.dart';
import '../controllers/servico_controller.dart';
import '../services/pdf_service.dart';

class FiscalController extends ChangeNotifier {
  final ServicoController servicoController;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Alíquota fixa configurada (ex: 6% Simples Nacional)
  final double aliquotaFixa = 0.06;

  List<NotaFiscal> _notasEmitidas = [];
  List<NotaFiscal> get notasEmitidas => _notasEmitidas;

  bool carregando = false;
  bool erroConexao = false;

  FiscalController({required this.servicoController});

  /// Carrega o histórico de notas fiscais diretamente do Supabase usando fromMap
  Future<void> carregarHistoricoNotas() async {
    carregando = true;
    erroConexao = false;
    notifyListeners();

    try {
      final response = await _supabase
          .from('nota_fiscal')
          .select()
          .order('data_emissao', ascending: false);

      // Utilizando o NotaFiscal.fromMap integrado
      _notasEmitidas = (response as List).map((map) {
        return NotaFiscal.fromMap(map);
      }).toList();

      carregando = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar notas do Supabase: $e');
      carregando = false;
      erroConexao = true;
      notifyListeners();
    }
  }

  /// Emite uma nova nota fiscal utilizando o toMap do model
  Future<void> emitirNotaParaServico({
    required String descricao,
    required double valorBruto,
    String? registroServicoId,
  }) async {
    double impostoCalculado = valorBruto * aliquotaFixa;
    DateTime dataAtual = DateTime.now();

    try {
      // Instancia o objeto NotaFiscal com os dados informados
      final novaNota = NotaFiscal(
        descricaoServico: descricao,
        valorBruto: valorBruto,
        aliquotaAplicada: aliquotaFixa,
        valorImposto: impostoCalculado,
        dataEmissaoInformada: dataAtual,
        registroServicoId: registroServicoId,
      );

      // Envia ao Supabase usando o método toMap() (o ID vem nulo para o banco gerar o UUID)
      final response = await _supabase
          .from('nota_fiscal')
          .insert(novaNota.toMap())
          .select()
          .single();

      // Atualiza o ID local com o UUID gerado de verdade pelo Supabase
      novaNota.id = response['id']?.toString();

      // Insere no topo da lista e notifica a UI
      _notasEmitidas.insert(0, novaNota);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar nota no Supabase: $e');
    }
  }

  /// Baixar novamente / Visualizar PDF da nota fiscal selecionada
  Future<void> baixarNotaFiscal(NotaFiscal nota) async {
    await PdfService.gerarRelatorioFiscal(
      periodo: 'Comprovante Fiscal - ${nota.descricaoServico}',
      servicos: [
        RegistroServico(
          id: nota.id ?? '',
          descricao: nota.descricaoServico,
          valor: nota.valorBruto,
          dataInformada: nota.dataEmissao,
          
          placaVeiculo: 'N/A', 
          duracaoEmHoras: 0, 
        )
      ],
      gastos: [],
      totalFaturado: nota.valorBruto,
      totalGastos: 0.0,
    );
  }

  double get faturamentoTotal {
    return _notasEmitidas.fold(0.0, (sum, item) => sum + item.valorBruto);
  }

  double get impostoTotal {
    return _notasEmitidas.fold(0.0, (sum, item) => sum + item.valorImposto);
  }
}