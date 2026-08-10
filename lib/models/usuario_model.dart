import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String role;
  final String? diaPagamento;
  final Timestamp? ultimoPagamento;
  final bool ativo;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.role,
    this.diaPagamento,
    this.ultimoPagamento,
    this.ativo = true,
  });

  factory UsuarioModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UsuarioModel(
      id: doc.id,
      nome: d['nome'] ?? 'Sem nome',
      role: d['role'] ?? 'barbeiro',
      diaPagamento: d['diaPagamento'],
      ultimoPagamento: d['ultimoPagamento'],
      ativo: d['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'role': role,
      'diaPagamento': diaPagamento,
      'ultimoPagamento': ultimoPagamento,
      'ativo': ativo,
    };
  }
}