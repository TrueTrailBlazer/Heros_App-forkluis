import 'package:cloud_firestore/cloud_firestore.dart';

class LancamentoModel {
  final String? id;
  final String barbeiroUid;
  final String barbeiroNome;
  final String servico;
  final double valor;
  final DateTime dataHora;
  final String statusCaixa; // 'aberto' ou 'fechado'

  LancamentoModel({
    this.id,
    required this.barbeiroUid,
    required this.barbeiroNome,
    required this.servico,
    required this.valor,
    required this.dataHora,
    this.statusCaixa = 'aberto',
  });

  factory LancamentoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LancamentoModel(
      id: documentId,
      barbeiroUid: map['barbeiroUid'] ?? '',
      barbeiroNome: map['barbeiroNome'] ?? '',
      servico: map['servico'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      dataHora: (map['dataHora'] as Timestamp).toDate(),
      statusCaixa: map['statusCaixa'] ?? 'aberto',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barbeiroUid': barbeiroUid,
      'barbeiroNome': barbeiroNome,
      'servico': servico,
      'valor': valor,
      'dataHora': Timestamp.fromDate(dataHora),
      'statusCaixa': statusCaixa,
    };
  }
}