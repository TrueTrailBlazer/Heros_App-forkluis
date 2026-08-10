import 'package:cloud_firestore/cloud_firestore.dart';

class ServicoModel {
  final String id;
  final String nome;
  final double preco;
  final double comissao;

  ServicoModel({
    required this.id,
    required this.nome,
    required this.preco,
    this.comissao = 0,
  });

  factory ServicoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ServicoModel(
      id: doc.id,
      nome: d['nome'] ?? '',
      preco: (d['preco'] as num?)?.toDouble() ?? 0,
      comissao: (d['comissao'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'preco': preco,
      'comissao': comissao,
    };
  }
}
