class Formatters {
  /// Formata double para moeda, ex: 25.5 -> 25.50
  static String moeda(double valor) {
    return valor.toStringAsFixed(2);
  }

  /// Formata DateTime para data curta, ex: 05/12
  static String dataCurta(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}";
  }

  /// Formata DateTime para data e hora, ex: 05/12 às 14:30
  static String dataHora(DateTime data) {
    return "${dataCurta(data)} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  /// Formata DateTime para data longa com ano, ex: 05/12/2026
  static String dataLonga(DateTime data) {
    return "${dataCurta(data)}/${data.year}";
  }
}

