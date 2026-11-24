import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../logic/date_utils.dart';
import 'neo_error.dart';

const demoKey = 'DEMO_KEY';

/// HTTP-клиент NASA NeoWs. Только транспорт: отправить запрос и вернуть тело.
/// Разбором занимается feed_parser, кэшем — neo_cache.
class NeoApi {
  NeoApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.baseUrl = 'https://api.nasa.gov/neo/rest/v1/feed',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final String baseUrl;

  /// GET /feed?start_date=..&end_date=..&api_key=..  (не больше 7 дней за раз).
  Future<String> fetchFeed(DateTime start, DateTime end, String apiKey) async {
    final key = apiKey.trim().isEmpty ? demoKey : apiKey.trim();
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'start_date': isoDay(start),
      'end_date': isoDay(end),
      'api_key': key,
    });

    final http.Response res;
    try {
      res = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw NeoError(
        NeoErrorKind.timeout,
        'NASA не ответила за ${timeout.inSeconds} с. Проверьте интернет и повторите.',
      );
    } on SocketException {
      throw const NeoError(NeoErrorKind.network, 'Нет подключения к интернету');
    } on http.ClientException {
      throw const NeoError(NeoErrorKind.network, 'Не удалось связаться с сервером NASA');
    } on Exception {
      // TLS-ошибки, обрыв соединения и прочее — тоже «сеть», а не падение приложения.
      throw const NeoError(NeoErrorKind.network, 'Ошибка соединения с сервером NASA');
    }

    final code = res.statusCode;
    if (code == 401 || code == 403) {
      throw NeoError(
        NeoErrorKind.auth,
        'NASA отклонила ключ API (HTTP $code). Проверьте ключ в настройках.',
        status: code,
      );
    }
    if (code == 429) {
      throw NeoError(
        NeoErrorKind.rateLimit,
        key == demoKey
            ? 'Лимит DEMO_KEY исчерпан (HTTP 429). Укажите свой ключ в настройках.'
            : 'Слишком много запросов (HTTP 429). Повторите позже.',
        status: code,
      );
    }
    if (code >= 400) {
      throw NeoError(NeoErrorKind.server, 'Сервер NASA вернул ошибку HTTP $code', status: code);
    }
    if (res.body.trim().isEmpty) {
      throw const NeoError(NeoErrorKind.empty, 'Сервер NASA вернул пустой ответ');
    }
    return res.body;
  }
}
