import 'kv_store.dart';
import 'neo_api.dart';

/// Настройки пользователя: личный ключ NASA API.
/// Ключ хранится только на устройстве и не попадает ни в репозиторий, ни в логи.
class Settings {
  Settings(this._store);

  static const _apiKey = 'api_key';

  final KvStore _store;

  /// Ключ, который реально уйдёт в запрос (пусто → DEMO_KEY).
  String get apiKey {
    final k = _store.read(_apiKey)?.trim() ?? '';
    return k.isEmpty ? demoKey : k;
  }

  /// Что ввёл пользователь (для поля в настройках).
  String get rawKey => _store.read(_apiKey) ?? '';

  bool get usesDemo => apiKey == demoKey;

  Future<void> setApiKey(String key) => _store.write(_apiKey, key.trim());
}
