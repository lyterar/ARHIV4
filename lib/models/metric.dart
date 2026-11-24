import 'day_stat.dart';

/// Показатель, динамику которого смотрим на экранах сравнения.
enum Metric {
  count('Сближения', 'шт.'),
  hazardous('Опасные', 'шт.'),
  minDist('Мин. расстояние', 'млн км');

  const Metric(this.label, this.unit);

  final String label;
  final String unit;

  /// Значение показателя за день; null — если посчитать нельзя.
  double? valueOf(DayStat s) {
    switch (this) {
      case Metric.count:
        return s.count.toDouble();
      case Metric.hazardous:
        return s.hazardous.toDouble();
      case Metric.minDist:
        final d = s.minDistKm;
        return d == null ? null : d / 1e6;
    }
  }
}
