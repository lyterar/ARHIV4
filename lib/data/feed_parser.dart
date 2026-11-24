import 'dart:convert';

import '../logic/date_utils.dart';
import '../models/asteroid.dart';
import 'neo_error.dart';

/// Разбор ответа NASA NeoWs `/feed`.
///
/// Нужная часть ответа:
/// ```json
/// { "near_earth_objects": {
///     "2026-11-24": [ { "id": "...", "name": "...",
///        "is_potentially_hazardous_asteroid": false,
///        "estimated_diameter": { "meters": { "estimated_diameter_min": 12.1, "estimated_diameter_max": 27.0 } },
///        "close_approach_data": [ { "close_approach_date": "2026-11-24",
///            "relative_velocity": { "kilometers_per_second": "8.51" },
///            "miss_distance": { "kilometers": "4528113.12" } } ] } ] } }
/// ```
/// Возвращает словарь «день → список сближений».
/// Битый JSON или чужая структура → [NeoError]; битые отдельные поля → null.
Map<DateTime, List<Asteroid>> parseFeed(String body) {
  if (body.trim().isEmpty) {
    throw const NeoError(NeoErrorKind.empty, 'Сервер NASA вернул пустой ответ');
  }

  final Object? root;
  try {
    root = jsonDecode(body);
  } on FormatException {
    throw const NeoError(NeoErrorKind.badJson, 'Ответ NASA повреждён: это не JSON');
  }

  if (root is! Map<String, dynamic>) {
    throw const NeoError(NeoErrorKind.badStructure, 'Неожиданный формат ответа NASA');
  }
  final neo = root['near_earth_objects'];
  if (neo is! Map<String, dynamic>) {
    throw const NeoError(
      NeoErrorKind.badStructure,
      'В ответе NASA нет списка сближений (near_earth_objects)',
    );
  }

  final out = <DateTime, List<Asteroid>>{};
  for (final entry in neo.entries) {
    final day = parseIsoDay(entry.key);
    final list = entry.value;
    if (day == null || list is! List) {
      throw NeoError(NeoErrorKind.badStructure, 'Некорректная запись за дату «${entry.key}»');
    }
    final items = <Asteroid>[];
    for (final raw in list) {
      final a = _parseOne(raw, entry.key);
      if (a != null) items.add(a);
    }
    items.sort(_byDistance);
    out[day] = items;
  }
  return out;
}

/// Ближайшие — первыми; без расстояния — в конце.
int _byDistance(Asteroid a, Asteroid b) {
  final x = a.distKm, y = b.distKm;
  if (x == null && y == null) return 0;
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// Один объект. Без id или имени объект бесполезен — пропускаем его (null).
Asteroid? _parseOne(Object? raw, String dayKey) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['id'];
  final name = raw['name'];
  if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
    return null;
  }

  final meters = _path(raw, ['estimated_diameter', 'meters']);
  final approach = _approachFor(raw['close_approach_data'], dayKey);
  final haz = raw['is_potentially_hazardous_asteroid'];

  return Asteroid(
    id: id,
    name: name.trim(),
    diamMinM: _num(meters?['estimated_diameter_min']),
    diamMaxM: _num(meters?['estimated_diameter_max']),
    speedKms: _num(_path(approach, ['relative_velocity'])?['kilometers_per_second']),
    distKm: _num(_path(approach, ['miss_distance'])?['kilometers']),
    hazardous: haz is bool ? haz : null,
  );
}

/// Берём сближение именно за нужный день; если даты нет — первое из списка.
Map<String, dynamic>? _approachFor(Object? list, String dayKey) {
  if (list is! List) return null;
  Map<String, dynamic>? first;
  for (final x in list) {
    if (x is! Map<String, dynamic>) continue;
    first ??= x;
    if (x['close_approach_date'] == dayKey) return x;
  }
  return first;
}

Map<String, dynamic>? _path(Map<String, dynamic>? m, List<String> keys) {
  Object? cur = m;
  for (final k in keys) {
    if (cur is! Map<String, dynamic>) return null;
    cur = cur[k];
  }
  return cur is Map<String, dynamic> ? cur : null;
}

/// NASA присылает числа то числом, то строкой ("8.51"). Отрицательные, NaN, ∞ → null.
double? _num(Object? v) {
  double? d;
  if (v is num) {
    d = v.toDouble();
  } else if (v is String) {
    d = double.tryParse(v.trim());
  }
  if (d == null || d.isNaN || d.isInfinite || d < 0) return null;
  return d;
}
