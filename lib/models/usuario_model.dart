class UsuarioModel {
  final String uid;
  final String nome;
  final String role; // 'admin' ou 'barbeiro'
  final int? diaFechamento; // 1 a 7 (Segunda a Domingo)
  final String? horaFechamento; // Ex: "21:00"

  UsuarioModel({
    required this.uid,
    required this.nome,
    required this.role,
    this.diaFechamento,
    this.horaFechamento,
  });

  // Converte do Firebase para o App
  factory UsuarioModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UsuarioModel(
      uid: documentId,
      nome: map['nome'] ?? '',
      role: map['role'] ?? 'barbeiro',
      diaFechamento: map['diaFechamento'],
      horaFechamento: map['horaFechamento'],
    );
  }

  // Converte do App para o Firebase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'role': role,
      'diaFechamento': diaFechamento,
      'horaFechamento': horaFechamento,
    };
  }
}