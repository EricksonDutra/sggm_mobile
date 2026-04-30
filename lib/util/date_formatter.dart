class DateFormatter {
  DateFormatter._();

  static DateTime? tryParse(String raw) {
    if (raw.trim().isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final partes = raw.split('T').first.split('-');
    if (partes.length == 3) {
      final y = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final d = int.tryParse(partes[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    return null;
  }

  static String fromDateTime(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  static String hora(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String fromIso(String raw) {
    final dt = tryParse(raw);
    return dt != null ? fromDateTime(dt) : raw;
  }

  static String dataHora(String raw) {
    final dt = tryParse(raw);
    if (dt == null) return raw;
    return '${fromDateTime(dt)} às ${hora(dt)}';
  }
}
