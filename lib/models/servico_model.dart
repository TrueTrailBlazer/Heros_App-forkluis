class ServicoModel {
  final String? id;
  final String nomeServico;
  final double valor;

  ServicoModel({
    this.id,
    required this.nomeServico,
    required this.valor,
  });

  factory ServicoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ServicoModel(
      id: documentId,
      nomeServico: map['nomeServico'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomeServico': nomeServico,
      'valor': valor,
    };
  }
}