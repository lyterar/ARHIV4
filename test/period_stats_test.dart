import 'package:flutter_test/flutter_test.dart';
import 'package:neo_tracker_mobile/logic/period_stats.dart';

List<Point> pts(List<double> v) =>
    [for (var i = 0; i < v.length; i++) Point(DateTime(2026, 11, 1 + i), v[i])];

void main() {
  group('computeStats', () {
    test('минимум, максимум и их даты', () {
      final s = computeStats(pts([5, 2, 9, 4]))!;
      expect(s.min, 2);
      expect(s.minDay, DateTime(2026, 11, 2));
      expect(s.max, 9);
      expect(s.maxDay, DateTime(2026, 11, 3));
    });

    test('среднее', () {
      expect(computeStats(pts([1, 2, 3, 4]))!.avg, 2.5);
    });

    test('изменение в абсолютных единицах и процентах (рост)', () {
      final s = computeStats(pts([10, 7, 12, 15]))!;
      expect(s.first, 10);
      expect(s.last, 15);
      expect(s.absChange, 5);
      expect(s.pctChange, closeTo(50, 1e-9));
      expect(s.trend, Trend.up);
    });

    test('падение', () {
      final s = computeStats(pts([20, 25, 10]))!;
      expect(s.absChange, -10);
      expect(s.pctChange, closeTo(-50, 1e-9));
      expect(s.trend, Trend.down);
    });

    test('без изменений: первый и последний равны', () {
      final s = computeStats(pts([8, 3, 12, 8]))!;
      expect(s.absChange, 0);
      expect(s.pctChange, 0);
      expect(s.trend, Trend.flat);
    });

    test('изменение меньше 1 % считается «без изменений»', () {
      final s = computeStats(pts([1000, 1005]))!;
      expect(s.pctChange, closeTo(0.5, 1e-9));
      expect(s.trend, Trend.flat);
    });

    test('старт с нуля: процент не определён, тренд по знаку', () {
      final s = computeStats(pts([0, 3]))!;
      expect(s.pctChange, isNull);
      expect(s.absChange, 3);
      expect(s.trend, Trend.up);
    });

    test('одна точка: изменение 0, без изменений', () {
      final s = computeStats(pts([7]))!;
      expect(s.min, 7);
      expect(s.max, 7);
      expect(s.avg, 7);
      expect(s.absChange, 0);
      expect(s.trend, Trend.flat);
      expect(s.count, 1);
    });

    test('пустой набор данных → null, а не нули', () {
      expect(computeStats(const []), isNull);
    });

    test('дробные значения (расстояние в млн км)', () {
      final s = computeStats(pts([1.5, 0.75, 3.0]))!;
      expect(s.avg, closeTo(1.75, 1e-9));
      expect(s.pctChange, closeTo(100, 1e-9));
    });
  });

  group('trendOf', () {
    test('граница 1 %', () {
      expect(trendOf(1, 1.0), Trend.up);
      expect(trendOf(-1, -0.99), Trend.flat);
      expect(trendOf(-2, null), Trend.down);
      expect(trendOf(0, null), Trend.flat);
    });
  });
}
