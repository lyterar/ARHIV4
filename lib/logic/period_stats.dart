/// Статистика показателя за период — то, что выводится на экранах «Неделя» и «Месяц».

/// Направление тенденции.
enum Trend {
  up('Рост'),
  down('Падение'),
  flat('Без изменений');

  const Trend(this.label);
  final String label;
}

/// Одна точка графика: день и значение показателя.
class Point {
  const Point(this.day, this.value);

  final DateTime day;
  final double value;
}

class PeriodStats {
  const PeriodStats({
    required this.min,
    required this.max,
    required this.minDay,
    required this.maxDay,
    required this.avg,
    required this.first,
    required this.last,
    required this.absChange,
    required this.pctChange,
    required this.trend,
    required this.count,
  });

  final double min;
  final double max;

  /// В какой день был минимум / максимум (первое вхождение).
  final DateTime minDay;
  final DateTime maxDay;

  final double avg;

  /// Значение в первый и последний день периода — от них считается изменение.
  final double first;
  final double last;

  /// last − first, в единицах показателя.
  final double absChange;

  /// (last − first) / first × 100. null, если first == 0 — на ноль делить нельзя.
  final double? pctChange;

  final Trend trend;

  /// Сколько дней с данными попало в расчёт.
  final int count;
}

/// Порог «без изменений»: изменение меньше 1 % считаем шумом.
const flatPct = 1.0;

/// Считает статистику. Пустой набор → null (экран покажет «нет данных»,
/// а не нули, которые выглядели бы как настоящие значения).
///
/// Точки должны идти по возрастанию даты — первая точка = начало периода.
PeriodStats? computeStats(List<Point> points) {
  if (points.isEmpty) return null;

  var minP = points.first;
  var maxP = points.first;
  var sum = 0.0;
  for (final p in points) {
    if (p.value < minP.value) minP = p;
    if (p.value > maxP.value) maxP = p;
    sum += p.value;
  }

  final first = points.first.value;
  final last = points.last.value;
  final abs = last - first;
  final double? pct = first == 0 ? null : abs / first * 100;

  return PeriodStats(
    min: minP.value,
    max: maxP.value,
    minDay: minP.day,
    maxDay: maxP.day,
    avg: sum / points.length,
    first: first,
    last: last,
    absChange: abs,
    pctChange: pct,
    trend: trendOf(abs, pct),
    count: points.length,
  );
}

/// Рост / падение / без изменений.
/// Если процент посчитать нельзя (старт с нуля) — решаем по знаку абсолютного изменения.
Trend trendOf(double abs, double? pct) {
  if (abs == 0) return Trend.flat;
  if (pct != null && pct.abs() < flatPct) return Trend.flat;
  return abs > 0 ? Trend.up : Trend.down;
}
