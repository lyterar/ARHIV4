import 'package:flutter_test/flutter_test.dart';
import 'package:neo_tracker_mobile/logic/date_utils.dart';

void main() {
  test('isoDay / ruDay', () {
    expect(isoDay(DateTime(2026, 3, 5)), '2026-03-05');
    expect(ruDay(DateTime(2026, 3, 5)), '05.03.2026');
  });

  test('parseIsoDay отбрасывает несуществующие даты', () {
    expect(parseIsoDay('2026-11-24'), DateTime(2026, 11, 24));
    expect(parseIsoDay('2026-02-30'), isNull);
    expect(parseIsoDay('24-11-2026'), isNull);
  });

  test('30 дней режутся на 5 запросов: 7+7+7+7+2', () {
    final end = DateTime(2026, 11, 24);
    final start = addDays(end, -29);
    final parts = splitRange(start, end);
    expect(parts.length, 5);
    expect(parts.first.$1, DateTime(2026, 10, 26));
    expect(parts.first.$2, DateTime(2026, 11, 1));
    expect(parts.last.$1, DateTime(2026, 11, 23));
    expect(parts.last.$2, end);
    final total = parts.fold<int>(0, (n, p) => n + daysBetween(p.$1, p.$2).length);
    expect(total, 30);
  });

  test('неделя — один запрос', () {
    final end = DateTime(2026, 11, 24);
    expect(splitRange(addDays(end, -6), end), [(DateTime(2026, 11, 18), end)]);
  });

  test('addDays через границу месяца и года', () {
    expect(addDays(DateTime(2026, 12, 30), 3), DateTime(2027, 1, 2));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
  });
}
