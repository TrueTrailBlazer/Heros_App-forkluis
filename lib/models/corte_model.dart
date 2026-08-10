import 'package:cloud_firestore/cloud_firestore.dart';

class CorteModel {
  final String id;
  final String barbeiroNome;
  final String barbeiroId;
  final List<String> servicos;
  final double valor;
  final double comissaoProdutos;
  final String formaPagamento;
  final DateTime data;

  CorteModel({
    required this.id,
    required this.barbeiroNome,
    required this.barbeiroId,
    required this.servicos,
    required this.valor,
    this.comissaoProdutos = 0,
    required this.formaPagamento,
    required this.data,
  });

  factory CorteModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CorteModel(
      id: doc.id,
      barbeiroNome: d['barbeiroNome'] ?? '',
      barbeiroId: d['barbeiroId'] ?? '',
      servicos: List<String>.from(d['servicos'] ?? []),
      valor: (d['valor'] as num?)?.toDouble() ?? 0,
      comissaoProdutos: (d['comissaoProdutos'] as num?)?.toDouble() ?? 0,
      formaPagamento: d['formaPagamento'] ?? '',
      data: d['data'] != null ? (d['data'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barbeiroNome': barbeiroNome,
      'barbeiroId': barbeiroId,
      'servicos': servicos,
      'valor': valor,
      'comissaoProdutos': comissaoProdutos,
      'formaPagamento': formaPagamento,
      'data': FieldValue.serverTimestamp(),
    };
  }
}

