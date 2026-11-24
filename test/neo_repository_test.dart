import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neo_tracker_mobile/data/kv_store.dart';
import 'package:neo_tracker_mobile/data/neo_api.dart';
import 'package:neo_tracker_mobile/data/neo_cache.dart';
import 'package:neo_tracker_mobile/data/neo_error.dart';
import 'package:neo_tracker_mobile/data/neo_repository.dart';
import 'package:neo_tracker_mobile/logic/date_utils.dart';

/// Фейковый сервер NASA: за каждый день отдаёт [perDay] астероидов
/// (по умолчанию — номер дня месяца, чтобы данные различались).
String fakeFeed(Uri url, {int Function(DateTime)? perDay}) {
  final from = parseIsoDay(url.queryParameters['start_date']!)!;
  final to = parseIsoDay(url.queryParameters['end_date']!)!;
  final days = <String>[];
  for (final d in daysBetween(from, to)) {
    final n = (perDay ?? (x) => x.day)(d);
    final items = [
      for (var i = 0; i < n; i++)
        '{"id":"${d.day}-$i","name":"A$i","is_potentially_hazardous_asteroid":${i == 0},'
            '"close_approach_data":[{"close_approach_date":"${isoDay(d)}",'
            '"miss_distance":{"kilometers":"${(i + 1) * 1000000}"}}]}'
    ];
    days.add('"${isoDay(d)}":[${items.join(',')}]');
  }
  return '{"near_earth_objects":{${days.join(',')}}}';
}

final today = DateTime(2026, 11, 24, 15, 30);

NeoRepository repoWith(KvStore store, Future<http.Response> Function(http.Request) h) =>
    NeoRepository(
      api: NeoApi(client: MockClient(h)),
      cache: NeoCache(store),
      apiKey: () => 'k',
      now: () => today,
    );

Future<http.Response> online(http.Request r) async => http.Response(fakeFeed(r.url), 200);
Future<http.Response> offline(http.Request r) async => throw const SocketException('offline');

void main() {
  group('loadDay', () {
    test('онлайн: свежие данные, не из кэша', () async {
      final r = await repoWith(MemoryStore(), online).loadDay(DateTime(2026, 11, 3));
      expect(r.items.length, 3);
      expect(r.fromCache, isFalse);
      expect(r.fetchedAt, today);
    });

    test('после «перезапуска» без сети отдаёт кэш с датой актуальности', () async {
      final store = MemoryStore(); // общее хранилище = данные на диске
      await repoWith(store, online).loadDay(DateTime(2026, 11, 3));

      final r = await repoWith(store, offline).loadDay(DateTime(2026, 11, 3));
      expect(r.fromCache, isTrue);
      expect(r.items.length, 3);
      expect(r.fetchedAt, today);
      expect(r.warning, 'Нет подключения к интернету');
    });

    test('без сети и без кэша — понятная ошибка, не падение', () {
      expect(
        repoWith(MemoryStore(), offline).loadDay(DateTime(2026, 11, 3)),
        throwsA(isA<NeoError>().having((e) => e.kind, 'kind', NeoErrorKind.network)),
      );
    });

    test('битый ответ сервера не затирает кэш', () async {
      final store = MemoryStore();
      await repoWith(store, online).loadDay(DateTime(2026, 11, 3));
      final r = await repoWith(store, (_) async => http.Response('<html>', 200))
          .loadDay(DateTime(2026, 11, 3));
      expect(r.fromCache, isTrue);
      expect(r.items.length, 3);
    });

    test('повреждённый кэш игнорируется без падения', () async {
      final store = MemoryStore()..data['neo_cache_v1'] = '{не json';
      final r = await repoWith(store, online).loadDay(DateTime(2026, 11, 3));
      expect(r.items.length, 3);
    });
  });

  group('loadPeriod', () {
    test('месяц = 5 запросов, 30 дней, по возрастанию дат', () async {
      var calls = 0;
      final r = await repoWith(MemoryStore(), (req) async {
        calls++;
        return online(req);
      }).loadPeriod(30);
      expect(calls, 5);
      expect(r.stats.length, 30);
      expect(r.stats.first.day, DateTime(2026, 10, 26));
      expect(r.stats.last.day, DateTime(2026, 11, 24));
      expect(r.missing, isEmpty);
      expect(r.fromCache, isFalse);
      // день 24 → 24 сближения, опасный 1, ближайший 1 млн км
      expect(r.stats.last.count, 24);
      expect(r.stats.last.hazardous, 1);
      expect(r.stats.last.minDistKm, 1000000);
    });

    test('день без сближений в ответе учитывается как 0', () async {
      final r = await repoWith(MemoryStore(), (req) async {
        return http.Response(fakeFeed(req.url, perDay: (d) => d.day == 20 ? 0 : 2), 200);
      }).loadPeriod(7);
      final d20 = r.stats.firstWhere((s) => s.day == DateTime(2026, 11, 20));
      expect(d20.count, 0);
      expect(d20.minDistKm, isNull);
    });

    test('неделя офлайн после загрузки месяца берётся из кэша', () async {
      final store = MemoryStore();
      await repoWith(store, online).loadPeriod(30);
      final r = await repoWith(store, offline).loadPeriod(7);
      expect(r.stats.length, 7);
      expect(r.fromCache, isTrue);
      expect(r.oldestFetch, today);
    });

    test('частичный сбой: недостающие дни перечислены, остальное посчитано', () async {
      final store = MemoryStore();
      await repoWith(store, online).loadPeriod(7); // в кэше только последняя неделя
      final r = await repoWith(store, offline).loadPeriod(30);
      expect(r.stats.length, 7);
      expect(r.missing.length, 23);
      expect(r.fromCache, isTrue);
      expect(r.warning, isNotNull);
    });

    test('после 429 дальше не запрашивает', () async {
      var calls = 0;
      await expectLater(
        repoWith(MemoryStore(), (_) async {
          calls++;
          return http.Response('', 429);
        }).loadPeriod(30),
        throwsA(isA<NeoError>().having((e) => e.kind, 'kind', NeoErrorKind.rateLimit)),
      );
      expect(calls, 1);
    });

    test('ничего нет ни в сети, ни в кэше → ошибка', () {
      expect(repoWith(MemoryStore(), offline).loadPeriod(7), throwsA(isA<NeoError>()));
    });
  });
}
