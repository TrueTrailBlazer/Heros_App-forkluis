import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/servico_model.dart';

/// Controller reativo do painel do Barbeiro.
class BarbeiroController extends ChangeNotifier {
  final DatabaseService _db;
  final AuthService _auth;

  BarbeiroController(this._db, this._auth) {
    _initStreams();
  }

  // --- Estado Observável ---
  List<ServicoModel> servicos = [];
  bool isLoadingServicos = true;
  String? erroServicos;

  // Estado local do carrinho
  final List<Map<String, dynamic>> servicosSelecionados = [];
  String formaPagamento = 'PIX';
  bool salvando = false;

  // --- Subscriptions ---
  StreamSubscription? _subServicos;

  void _initStreams() {
    _subServicos = _db.getServicos().listen(
      (data) {
        servicos = data;
        isLoadingServicos = false;
        erroServicos = null;
        notifyListeners();
      },
      onError: (e) {
        erroServicos = e.toString();
        isLoadingServicos = false;
        notifyListeners();
      },
    );
  }

  // --- Lógica de Negócio do Carrinho ---

  double get valorTotal => servicosSelecionados.fold(0, (sum, item) => sum + (item['preco'] as num).toDouble());
  double get comissaoExtra => servicosSelecionados.fold(0, (sum, item) => sum + (item['comissao'] as num).toDouble());

  void adicionarServico(String nome, double preco, double comissao) {
    servicosSelecionados.add({'nome': nome, 'preco': preco, 'comissao': comissao});
    notifyListeners();
  }

  void removerServico(int index) {
    servicosSelecionados.removeAt(index);
    notifyListeners();
  }

  void setFormaPagamento(String forma) {
    formaPagamento = forma;
    notifyListeners();
  }

  /// Finaliza o atendimento e grava no banco.
  /// Retorna erro se houver. Sucesso retorna null.
  Future<String?> finalizarAtendimento() async {
    if (servicosSelecionados.isEmpty) return "Carrinho vazio.";
    
    salvando = true;
    notifyListeners();

    try {
      List<String> nomesServicos = servicosSelecionados.map((s) => s['nome'].toString()).toList();
      
      await _db.registrarCorte(
        barbeiroNome: _auth.usuarioAtual?.nome ?? 'Barbeiro',
        barbeiroId: _auth.usuarioAtual?.id ?? '',
        servicosFeitos: nomesServicos,
        valorTotal: valorTotal,
        comissaoProdutos: comissaoExtra,
        formaPagamento: formaPagamento,
      );

      // Limpa após sucesso
      servicosSelecionados.clear();
      formaPagamento = 'PIX';
      salvando = false;
      notifyListeners();
      return null;
    } catch (e) {
      salvando = false;
      notifyListeners();
      return e.toString();
    }
  }

  @override
  void dispose() {
    _subServicos?.cancel();
    super.dispose();
  }
}
