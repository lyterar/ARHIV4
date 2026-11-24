/// Форматирование чисел для экрана.

/// 1234567.8 → «1 234 568»; с [digits] знаками после запятой.
String fmtNum(double? v, {int digits = 0}) {
  if (v == null) return 'нет данных';
  final s = v.abs().toStringAsFixed(digits);
  final parts = s.split('.');
  final buf = StringBuffer();
  final intPart = parts[0];
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
    buf.write(intPart[i]);
  }
  final sign = v < 0 ? '−' : '';
  return parts.length > 1 ? '$sign$buf,${parts[1]}' : '$sign$buf';
}

/// Изменение со знаком: «+3», «−1,5».
String fmtSigned(double v, {int digits = 0}) => v > 0 ? '+${fmtNum(v, digits: digits)}' : fmtNum(v, digits: digits);
