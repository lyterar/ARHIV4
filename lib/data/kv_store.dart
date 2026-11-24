import 'package:shared_preferences/shared_preferences.dart';

/// Минимальное key-value хранилище. Интерфейс нужен, чтобы в тестах
/// подставлять MemoryStore вместо настоящего SharedPreferences.
abstract class KvStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Хранилище на SharedPreferences — переживает перезапуск приложения.
class PrefsStore implements KvStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Хранилище в памяти — для тестов. Один экземпляр на два «запуска»
/// репозитория имитирует перезапуск приложения.
class MemoryStore implements KvStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }
}
