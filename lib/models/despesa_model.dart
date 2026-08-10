import 'package:cloud_firestore/cloud_firestore.dart';

class DespesaModel {
  final String id;
  final String tipo;
  final String descricao;
  final double valor;
  final DateTime data;

  DespesaModel({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  factory DespesaModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return DespesaModel(
      id: doc.id,
      tipo: d['tipo'] ?? '',
      descricao: d['descricao'] ?? '',
      valor: (d['valor'] as num?)?.toDouble() ?? 0,
      data: d['data'] != null ? (d['data'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': FieldValue.serverTimestamp(),
    };
  }
}

