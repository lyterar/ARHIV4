import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neo_tracker_mobile/data/neo_api.dart';
import 'package:neo_tracker_mobile/data/neo_error.dart';

Matcher throwsNeo(NeoErrorKind kind) =>
    throwsA(isA<NeoError>().having((e) => e.kind, 'kind', kind));

NeoApi apiWith(Future<http.Response> Function(http.Request) h) =>
    NeoApi(client: MockClient(h), timeout: const Duration(milliseconds: 200));

final d = DateTime(2026, 11, 24);

void main() {
  test('формирует запрос с датами и ключом; пустой ключ → DEMO_KEY', () async {
    late Uri seen;
    final api = apiWith((r) async {
      seen = r.url;
      return http.Response('{}', 200);
    });
    await api.fetchFeed(DateTime(2026, 11, 18), d, '  ');
    expect(seen.path, '/neo/rest/v1/feed');
    expect(seen.queryParameters['start_date'], '2026-11-18');
    expect(seen.queryParameters['end_date'], '2026-11-24');
    expect(seen.queryParameters['api_key'], 'DEMO_KEY');
  });

  test('HTTP 403 → auth', () {
    final api = apiWith((_) async => http.Response('forbidden', 403));
    expect(api.fetchFeed(d, d, 'k'), throwsNeo(NeoErrorKind.auth));
  });

  test('HTTP 429 → rateLimit, текст про DEMO_KEY', () {
    final api = apiWith((_) async => http.Response('', 429));
    expect(
      api.fetchFeed(d, d, ''),
      throwsA(isA<NeoError>()
          .having((e) => e.kind, 'kind', NeoErrorKind.rateLimit)
          .having((e) => e.message, 'message', contains('DEMO_KEY'))),
    );
  });

  test('HTTP 500 → server', () {
    final api = apiWith((_) async => http.Response('oops', 500));
    expect(api.fetchFeed(d, d, 'k'), throwsNeo(NeoErrorKind.server));
  });

  test('200 с пустым телом → empty', () {
    final api = apiWith((_) async => http.Response('  ', 200));
    expect(api.fetchFeed(d, d, 'k'), throwsNeo(NeoErrorKind.empty));
  });

  test('нет сети (SocketException) → network', () {
    final api = apiWith((_) async => throw const SocketException('Failed host lookup'));
    expect(api.fetchFeed(d, d, 'k'), throwsNeo(NeoErrorKind.network));
  });

  test('сервер молчит дольше тайм-аута → timeout', () {
    final api = apiWith((_) => Completer<http.Response>().future);
    expect(api.fetchFeed(d, d, 'k'), throwsNeo(NeoErrorKind.timeout));
  });

  test('ключ не попадает в текст ошибки', () async {
    final api = apiWith((_) async => http.Response('', 401));
    try {
      await api.fetchFeed(d, d, 'SECRET_KEY_123');
      fail('должна быть ошибка');
    } on NeoError catch (e) {
      expect(e.message, isNot(contains('SECRET_KEY_123')));
    }
  });
}
