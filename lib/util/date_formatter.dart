class DateFormatter {
  static String data(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  static String hora(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String dataHora(DateTime dt) => '${data(dt)}  ${hora(dt)}';

  /// Converte ISO string "2025-06-15T19:00:00" → "15/06/2025"
  static String fromIso(String iso) {
    final partes = iso.split('T')[0].split('-');
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }
}
