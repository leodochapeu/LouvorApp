/// Portuguese date labels used in culto cards, forms and the date picker.
abstract final class DateFormatters {
  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const _weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  /// `24/08/2026`
  static String short(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// `domingo, 24 de agosto de 2026`
  static String long(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday, ${date.day} de $month de ${date.year}';
  }

  /// `YYYY-MM-DD` — the shape Postgres `date` columns expect.
  static String toIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Parses a Postgres `date` (`YYYY-MM-DD`) or timestamptz string.
  static DateTime fromIsoDate(String raw) {
    return DateTime.parse(raw);
  }
}
