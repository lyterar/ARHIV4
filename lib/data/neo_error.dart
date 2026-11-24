/// Виды ошибок — по ним UI решает, что показать пользователю.
enum NeoErrorKind {
  network,
  timeout,
  auth,
  rateLimit,
  server,
  badJson,
  badStructure,
  empty,
}

/// Единая ошибка приложения с понятным русским текстом.
/// Ключ API в текст ошибки никогда не попадает.
class NeoError implements Exception {
  const NeoError(this.kind, this.message, {this.status});

  final NeoErrorKind kind;
  final String message;

  /// HTTP-код, если ошибка пришла от сервера.
  final int? status;

  @override
  String toString() => 'NeoError($kind, $message)';
}
