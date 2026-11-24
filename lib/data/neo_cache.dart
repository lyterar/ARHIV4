import 'dart:convert';

import '../logic/date_utils.dart';
import '../models/asteroid.dart';
import 'kv_store.dart';

/// Сохранённые данные за один день + когда они были получены.
class CachedDay {
  const CachedDay(this.fetchedAt, this.items);

  final DateTime fetchedAt;
  final List<Asteroid> items;
}

/// Локальный кэш сближений по дням.
///
/// Всё лежит одной JSON-строкой под ключом [_key]:
/// `{"v":1,"days":{"2026-11-24":{"at":"2026-11-24T15:30:00.000","items":[...]}}}`
///
/// Один кэш обслуживает и экран поиска (список за день), и экраны аналитики
/// (из списков считаются DayStat). Поэтому неделя, загруженная с экрана
/// «Месяц», будет доступна офлайн и на экране «Неделя».
class NeoCache {
  NeoCache(this._store, {this.maxDays = 120});

  static const _key = 'neo_cache_v1';
  static const _version = 1;

  final KvStore _store;

  /// Сколько дней максимум храним (старые вытесняются).
  final int maxDays;

  Map<String, CachedDay>? _mem;

  /// Читает кэш. Повреждённый кэш не роняет приложение — считается пустым.
  Map<String, CachedDay> _load() {
    if (_mem != null) return _mem!;
    final raw = _store.read(_key);
    final out = <String, CachedDay>{};
    if (raw != null) {
      try {
        final root = jsonDecode(raw) as Map<String, dynamic>;
        if (root['v'] == _version) {
          final days = root['days'] as Map<String, dynamic>;
          days.forEach((k, v) {
            final m = v as Map<String, dynamic>;
            out[k] = CachedDay(
              DateTime.parse(m['at'] as String),
              (m['items'] as List)
                  .map((e) => Asteroid.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          });
        }
      } catch (_) {
        out.clear(); // битый кэш — начинаем с чистого листа
      }
    }
    return _mem = out;
  }

  CachedDay? day(DateTime d) => _load()[isoDay(d)];

  int get size => _load().length;

  /// Сохраняет свежие данные. Пишет только успешные ответы —
  /// ошибка сети никогда не затирает рабочий кэш.
  Future<void> putAll(Map<DateTime, List<Asteroid>> byDay, DateTime fetchedAt) async {
    final all = _load();
    byDay.forEach((d, items) => all[isoDay(d)] = CachedDay(fetchedAt, items));

    if (all.length > maxDays) {
      final keys = all.keys.toList()..sort(); // ISO-даты сортируются как строки
      for (final k in keys.take(all.length - maxDays)) {
        all.remove(k);
      }
    }
    await _save(all);
  }

  Future<void> clear() async {
    _mem = {};
    await _store.remove(_key);
  }

  Future<void> _save(Map<String, CachedDay> all) async {
    final json = jsonEncode({
      'v': _version,
      'days': all.map((k, c) => MapEntry(k, {
            'at': c.fetchedAt.toIso8601String(),
            'items': c.items.map((a) => a.toJson()).toList(),
          })),
    });
    await _store.write(_key, json);
  }
}
