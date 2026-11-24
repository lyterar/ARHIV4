import 'package:flutter_test/flutter_test.dart';
import 'package:neo_tracker_mobile/logic/validators.dart';

void main() {
  group('validateDate', () {
    test('корректная дата', () {
      expect(validateDate('2026-11-24'), isNull);
      expect(validateDate('  2026-11-24 '), isNull);
    });

    test('пустая строка', () {
      expect(validateDate(''), 'Введите дату');
      expect(validateDate('   '), 'Введите дату');
    });

    test('неверный формат', () {
      for (final s in ['24.11.2026', '2026/11/24', '2026-1-5', '20261124', 'abc']) {
        expect(validateDate(s), 'Формат даты: ГГГГ-ММ-ДД', reason: s);
      }
    });

    test('несуществующая дата', () {
      expect(validateDate('2026-02-30'), 'Такой даты не существует');
      expect(validateDate('2026-13-01'), 'Такой даты не существует');
      expect(validateDate('2025-02-29'), 'Такой даты не существует');
    });

    test('високосный год принимается', () {
      expect(validateDate('2024-02-29'), isNull);
    });

    test('вне диапазона NeoWs', () {
      expect(validateDate('1899-12-31'), isNotNull);
      expect(validateDate('2201-01-01'), isNotNull);
      expect(validateDate('1900-01-01'), isNull);
    });
  });

  group('validateApiKey', () {
    test('пустой ключ допустим (DEMO_KEY)', () {
      expect(validateApiKey(''), isNull);
    });

    test('обычный ключ и DEMO_KEY', () {
      expect(validateApiKey('abcDEF1234567890'), isNull);
      expect(validateApiKey('DEMO_KEY'), isNull);
    });

    test('короткий ключ, пробелы внутри, кириллица, спецсимволы', () {
      for (final k in ['abc', 'abc def ghi', 'ключключключ', '<ваш_ключ>', 'key-with-dash1']) {
        expect(validateApiKey(k), isNotNull, reason: k);
      }
    });
  });
}
