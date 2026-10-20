/// Форматирует сумму в тенге: 12000 -> "12 000 ₸".
String formatMoney(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign$buffer ₸';
}

/// Разбирает ввод суммы. Пустое поле — 0, некорректный ввод или отрицательное число — null.
int? parseMoney(String raw) {
  final cleaned = raw.replaceAll(' ', '').replaceAll(',', '.').trim();
  if (cleaned.isEmpty) return 0;
  final value = num.tryParse(cleaned);
  if (value == null || value < 0) return null;
  return value.round();
}
