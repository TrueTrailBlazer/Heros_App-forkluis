import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/corte_model.dart';
import '../models/servico_model.dart';
import '../models/despesa_model.dart';
import '../models/usuario_model.dart';

/// Controller reativo central do painel Admin.
/// Escuta as Streams do Firestore e notifica a UI quando os dados mudam.
class AdminController extends ChangeNotifier {
  final DatabaseService _db;

  AdminController(this._db) {
    _initStreams();
  }

  // --- Estado Observável ---
  List<CorteModel> cortesHoje = [];
  List<UsuarioModel> barbeiros = [];
  List<ServicoModel> servicos = [];
  List<DespesaModel> despesas = [];

  bool isLoadingCortes = true;
  bool isLoadingBarbeiros = true;
  bool isLoadingServicos = true;
  bool isLoadingDespesas = true;

  String? erroCortes;
  String? erroBarbeiros;
  String? erroServicos;
  String? erroDespesas;

  // --- Subscriptions ---
  StreamSubscription? _subCortes;
  StreamSubscription? _subBarbeiros;
  StreamSubscription? _subServicos;
  StreamSubscription? _subDespesas;

  void _initStreams() {
    DateTime inicioHoje = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    _subCortes = _db.getTodosOsCortes(dataInicio: inicioHoje).listen(
      (data) {
        cortesHoje = data;
        isLoadingCortes = false;
        erroCortes = null;
        notifyListeners();
      },
      onError: (e) {
        erroCortes = e.toString();
        isLoadingCortes = false;
        notifyListeners();
      },
    );

    _subBarbeiros = _db.getBarbeiros().listen(
      (data) {
        barbeiros = data;
        isLoadingBarbeiros = false;
        erroBarbeiros = null;
        notifyListeners();
      },
      onError: (e) {
        erroBarbeiros = e.toString();
        isLoadingBarbeiros = false;
        notifyListeners();
      },
    );

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

    _subDespesas = _db.getDespesasEVales().listen(
      (data) {
        despesas = data;
        isLoadingDespesas = false;
        erroDespesas = null;
        notifyListeners();
      },
      onError: (e) {
        erroDespesas = e.toString();
        isLoadingDespesas = false;
        notifyListeners();
      },
    );
  }

  // --- Lógica de Negócio ---

  /// Verifica se o barbeiro precisa receber pagamento.
  bool precisaPagar(String diaPagamento, Timestamp? ultimoPag) {
    int hoje = DateTime.now().weekday;
    Map<String, int> dias = {
      'Segunda': 1,
      'Terça': 2,
      'Quarta': 3,
      'Quinta': 4,
      'Sexta': 5,
      'Sábado': 6,
      'Domingo': 7
    };
    int diaAlvo = dias[diaPagamento] ?? 6;
    int ontem = hoje - 1;
    if (ontem == 0) ontem = 7;
    if (hoje != diaAlvo && ontem != diaAlvo) return false;
    if (ultimoPag != null && DateTime.now().difference(ultimoPag.toDate()).inDays < 3) return false;
    return true;
  }

  double get faturamentoBrutoHoje => cortesHoje.fold(0, (s, c) => s + c.valor);
  int get qtdServicosHoje => cortesHoje.length;

  @override
  void dispose() {
    _subCortes?.cancel();
    _subBarbeiros?.cancel();
    _subServicos?.cancel();
    _subDespesas?.cancel();
    super.dispose();
  }
}
