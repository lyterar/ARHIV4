import 'package:flutter_test/flutter_test.dart';
import 'package:neo_tracker_mobile/data/feed_parser.dart';
import 'package:neo_tracker_mobile/data/neo_error.dart';

import 'fixtures/feed_sample.dart';

Matcher throwsNeo(NeoErrorKind kind) =>
    throwsA(isA<NeoError>().having((e) => e.kind, 'kind', kind));

void main() {
  group('parseFeed — корректный ответ', () {
    final res = parseFeed(feedSample);

    test('разбивает сближения по дням', () {
      expect(res.length, 2);
      expect(res[DateTime(2026, 11, 24)]!.length, 2);
      expect(res[DateTime(2026, 11, 23)]!.length, 1);
    });

    test('числа-строки превращаются в double', () {
      final a = res[DateTime(2026, 11, 23)]!.single;
      expect(a.speedKms, closeTo(19.485, 0.001));
      expect(a.distKm, closeTo(19781633.2, 0.01));
      expect(a.diamMinM, 24.0);
      expect(a.diamMaxM, 54.0);
      expect(a.hazardous, isFalse);
    });

    test('внутри дня сортирует от ближайшего к дальнему', () {
      final day = res[DateTime(2026, 11, 24)]!;
      expect(day.first.name, '465633 (2009 JR5)');
      expect(day.first.distKm! < day.last.distKm!, isTrue);
      expect(day.last.hazardous, isTrue);
    });
  });

  group('parseFeed — пропуски и мусор в полях', () {
    test('нет диаметра/скорости/опасности → null, а не 0', () {
      const body = '{"near_earth_objects":{"2026-01-01":[{"id":"1","name":"X"}]}}';
      final a = parseFeed(body)[DateTime(2026, 1, 1)]!.single;
      expect(a.diamMinM, isNull);
      expect(a.speedKms, isNull);
      expect(a.distKm, isNull);
      expect(a.hazardous, isNull);
    });

    test('отрицательные и нечисловые значения → null', () {
      const body = '{"near_earth_objects":{"2026-01-01":[{"id":"1","name":"X",'
          '"estimated_diameter":{"meters":{"estimated_diameter_min":-5,"estimated_diameter_max":"abc"}},'
          '"close_approach_data":[{"close_approach_date":"2026-01-01",'
          '"relative_velocity":{"kilometers_per_second":"NaN"},"miss_distance":{"kilometers":"-1"}}]}]}}';
      final a = parseFeed(body)[DateTime(2026, 1, 1)]!.single;
      expect(a.diamMinM, isNull);
      expect(a.diamMaxM, isNull);
      expect(a.speedKms, isNull);
      expect(a.distKm, isNull);
    });

    test('объект без id или имени пропускается', () {
      const body = '{"near_earth_objects":{"2026-01-01":[{"name":"без id"},{"id":"2","name":"  "},{"id":"3","name":"OK"}]}}';
      final list = parseFeed(body)[DateTime(2026, 1, 1)]!;
      expect(list.map((a) => a.id), ['3']);
    });

    test('берёт сближение именно за нужный день', () {
      const body = '{"near_earth_objects":{"2026-01-02":[{"id":"1","name":"X","close_approach_data":['
          '{"close_approach_date":"2026-01-01","miss_distance":{"kilometers":"1"}},'
          '{"close_approach_date":"2026-01-02","miss_distance":{"kilometers":"2"}}]}]}}';
      expect(parseFeed(body)[DateTime(2026, 1, 2)]!.single.distKm, 2);
    });
  });

  group('parseFeed — пустые и сломанные ответы', () {
    test('пустое тело → empty', () {
      expect(() => parseFeed('   '), throwsNeo(NeoErrorKind.empty));
    });

    test('не JSON → badJson', () {
      expect(() => parseFeed('<html>502</html>'), throwsNeo(NeoErrorKind.badJson));
    });

    test('JSON без near_earth_objects → badStructure', () {
      expect(() => parseFeed('{"error":"x"}'), throwsNeo(NeoErrorKind.badStructure));
    });

    test('корень-массив → badStructure', () {
      expect(() => parseFeed('[]'), throwsNeo(NeoErrorKind.badStructure));
    });

    test('кривой ключ даты → badStructure', () {
      expect(
        () => parseFeed('{"near_earth_objects":{"вчера":[]}}'),
        throwsNeo(NeoErrorKind.badStructure),
      );
    });

    test('пустой near_earth_objects → пустой словарь без ошибки', () {
      expect(parseFeed('{"near_earth_objects":{}}'), isEmpty);
    });

    test('пустой список за день — день есть, сближений 0', () {
      final res = parseFeed('{"near_earth_objects":{"2026-01-01":[]}}');
      expect(res[DateTime(2026, 1, 1)], isEmpty);
    });
  });
}
