import 'date_utils.dart';

/// Проверки пользовательского ввода. Возвращают текст ошибки или null, если всё ок.
/// Вызываются ДО сетевого запроса — кривой ввод не тратит квоту API.

/// NeoWs хранит данные примерно с 1900 по 2200 год.
final DateTime minDate = DateTime(1900, 1, 1);
final DateTime maxDate = DateTime(2200, 12, 31);

String? validateDate(String input) {
  final s = input.trim();
  if (s.isEmpty) return 'Введите дату';
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    return 'Формат даты: ГГГГ-ММ-ДД';
  }
  final d = parseIsoDay(s);
  if (d == null) return 'Такой даты не существует';
  if (d.isBefore(minDate) || d.isAfter(maxDate)) {
    return 'Дата должна быть между 1900-01-01 и 2200-12-31';
  }
  return null;
}

final _keyRe = RegExp(r'^[A-Za-z0-9_]{8,64}$');

/// Пустой ключ допустим — тогда работает DEMO_KEY.
String? validateApiKey(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  if (!_keyRe.hasMatch(s)) {
    return 'Ключ: 8–64 символа, только латиница, цифры и _';
  }
  return null;
}
