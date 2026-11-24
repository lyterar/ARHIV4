import 'asteroid.dart';

/// Сводка за один день — из неё строятся графики на экранах «Неделя» и «Месяц».
class DayStat {
  const DayStat({
    required this.day,
    required this.count,
    required this.hazardous,
    this.minDistKm,
  });

  final DateTime day;

  /// Сколько сближений в этот день.
  final int count;

  /// Сколько из них потенциально опасных.
  final int hazardous;

  /// Минимальное расстояние промаха за день, км (null — нет данных).
  final double? minDistKm;

  factory DayStat.of(DateTime day, List<Asteroid> items) {
    double? minDist;
    for (final a in items) {
      final d = a.distKm;
      if (d != null && (minDist == null || d < minDist)) minDist = d;
    }
    return DayStat(
      day: day,
      count: items.length,
      hazardous: items.where((a) => a.hazardous == true).length,
      minDistKm: minDist,
    );
  }
}
