import '../logic/date_utils.dart';
import '../models/asteroid.dart';
import '../models/day_stat.dart';
import 'feed_parser.dart';
import 'neo_api.dart';
import 'neo_cache.dart';
import 'neo_error.dart';

/// Результат для экрана поиска (один день).
class DayResult {
  const DayResult({
    required this.day,
    required this.items,
    required this.fetchedAt,
    this.fromCache = false,
    this.warning,
  });

  final DateTime day;
  final List<Asteroid> items;

  /// Когда данные были получены от NASA (для кэша — дата актуальности).
  final DateTime fetchedAt;
  final bool fromCache;

  /// Почему показан кэш (текст ошибки сети и т.п.).
  final String? warning;
}

/// Результат для экранов «Неделя» / «Месяц».
class PeriodResult {
  const PeriodResult({
    required this.start,
    required this.end,
    required this.stats,
    required this.missing,
    this.oldestFetch,
    this.fromCache = false,
    this.warning,
  });

  final DateTime start;
  final DateTime end;

  /// Сводки по дням, по возрастанию даты. Дни без данных сюда не входят.
  final List<DayStat> stats;

  /// Дни периода, по которым нет ни свежих, ни сохранённых данных.
  final List<DateTime> missing;

  /// Самая старая дата получения среди использованных дней — «данные актуальны на».
  final DateTime? oldestFetch;
  final bool fromCache;
  final String? warning;
}

/// Единая точка получения данных: сначала сеть, при сбое — кэш.
class NeoRepository {
  NeoRepository({
    required this.api,
    required this.cache,
    required this.apiKey,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final NeoApi api;
  final NeoCache cache;

  /// Функция, а не строка: ключ могут поменять в настройках во время работы.
  final String Function() apiKey;
  final DateTime Function() _now;

  DateTime get today => dayOnly(_now());

  /// Загружает и сохраняет в кэш один кусок периода (≤ 7 дней).
  /// Дни без сближений сохраняются как пустой список — это тоже данные.
  Future<void> _fetchChunk(DateTime from, DateTime to) async {
    final body = await api.fetchFeed(from, to, apiKey());
    final parsed = parseFeed(body);
    final byDay = <DateTime, List<Asteroid>>{};
    for (final d in daysBetween(from, to)) {
      byDay[d] = parsed[d] ?? const [];
    }
    await cache.putAll(byDay, _now());
  }

  /// Экран поиска: сближения за выбранный день.
  Future<DayResult> loadDay(DateTime day) async {
    final d = dayOnly(day);
    try {
      await _fetchChunk(d, d);
      final c = cache.day(d)!;
      return DayResult(day: d, items: c.items, fetchedAt: c.fetchedAt);
    } on NeoError catch (e) {
      final c = cache.day(d);
      if (c == null) rethrow; // показать нечего — экран покажет ошибку
      return DayResult(
        day: d,
        items: c.items,
        fetchedAt: c.fetchedAt,
        fromCache: true,
        warning: e.message,
      );
    }
  }

  /// Экраны сравнения: последние [days] дней, включая сегодня.
  ///
  /// Период режется на куски по 7 дней (ограничение NASA feed).
  /// Если кусок не загрузился — берём эти дни из кэша и продолжаем.
  /// После HTTP 429 дальше не стучимся, чтобы не жечь лимит.
  Future<PeriodResult> loadPeriod(int days) async {
    if (days < 1) throw ArgumentError.value(days, 'days');
    final end = today;
    final start = addDays(end, -(days - 1));

    NeoError? lastErr;
    var failed = false;
    for (final (from, to) in splitRange(start, end)) {
      if (lastErr?.kind == NeoErrorKind.rateLimit) {
        failed = true;
        continue;
      }
      try {
        await _fetchChunk(from, to);
      } on NeoError catch (e) {
        failed = true;
        lastErr = e;
      }
    }

    final stats = <DayStat>[];
    final missing = <DateTime>[];
    DateTime? oldest;
    for (final d in daysBetween(start, end)) {
      final c = cache.day(d);
      if (c == null) {
        missing.add(d);
        continue;
      }
      stats.add(DayStat.of(d, c.items));
      if (oldest == null || c.fetchedAt.isBefore(oldest)) oldest = c.fetchedAt;
    }

    if (stats.isEmpty && lastErr != null) throw lastErr;

    return PeriodResult(
      start: start,
      end: end,
      stats: stats,
      missing: missing,
      oldestFetch: oldest,
      fromCache: failed,
      warning: lastErr?.message,
    );
  }
}
