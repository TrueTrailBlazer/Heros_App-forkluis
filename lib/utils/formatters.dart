import 'package:intl/intl.dart';

class Formatters {
  /// Formata double para moeda
  static String moeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor).trim();
  }

  /// Formata DateTime para data curta, ex: 05/12
  static String dataCurta(DateTime data) {
    return DateFormat('dd/MM', 'pt_BR').format(data);
  }

  /// Formata DateTime para data e hora, ex: 05/12 às 14:30
  static String dataHora(DateTime data) {
    return DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(data);
  }

  /// Formata DateTime para data longa com ano, ex: 05/12/2026
  static String dataLonga(DateTime data) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
  }
}

