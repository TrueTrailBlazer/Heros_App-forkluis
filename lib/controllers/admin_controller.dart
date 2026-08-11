import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController {
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
}
