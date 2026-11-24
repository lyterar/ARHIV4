/// Работа с датами без времени (только год-месяц-день).

/// Отбрасывает время: 2026-11-24 15:30 → 2026-11-24 00:00.
DateTime dayOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Сдвиг на n дней. Через конструктор, а не Duration, чтобы
/// переход на летнее/зимнее время не съедал день.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String _two(int v) => v.toString().padLeft(2, '0');

/// Формат API NASA: YYYY-MM-DD.
String isoDay(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Формат для людей: 24.11.2026.
String ruDay(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// Короткий формат для подписей графика: 24.11.
String ruShort(DateTime d) => '${_two(d.day)}.${_two(d.month)}';

/// Дата и время для баннера актуальности: 24.11.2026 15:30.
String ruStamp(DateTime t) => '${ruDay(t)} ${_two(t.hour)}:${_two(t.minute)}';

final _isoRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Строгий разбор YYYY-MM-DD. Несуществующие даты (2026-02-30) → null.
DateTime? parseIsoDay(String s) {
  final m = _isoRe.firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final dt = DateTime(y, mo, d);
  // DateTime «переносит» лишние дни (30 февраля → 2 марта) — ловим это.
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  return dt;
}

/// Все дни от [start] до [end] включительно.
List<DateTime> daysBetween(DateTime start, DateTime end) {
  final out = <DateTime>[];
  for (var d = dayOnly(start); !d.isAfter(end); d = addDays(d, 1)) {
    out.add(d);
  }
  return out;
}

/// Режет период на куски не длиннее [maxDays] — NASA feed отдаёт максимум 7 дней за запрос.
/// 30 дней → 7 + 7 + 7 + 7 + 2.
List<(DateTime, DateTime)> splitRange(DateTime start, DateTime end, {int maxDays = 7}) {
  if (maxDays < 1) throw ArgumentError.value(maxDays, 'maxDays');
  final out = <(DateTime, DateTime)>[];
  var from = dayOnly(start);
  final last = dayOnly(end);
  while (!from.isAfter(last)) {
    var to = addDays(from, maxDays - 1);
    if (to.isAfter(last)) to = last;
    out.add((from, to));
    from = addDays(to, 1);
  }
  return out;
}
