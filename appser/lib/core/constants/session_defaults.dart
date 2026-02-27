/// Defaults e chaves de sessões usadas no app.
///
/// Mantém a mesma estrutura atual (session0..session8).
abstract final class SessionDefaults {
  static const int totalSessions = 9;

  static const Map<String, bool> defaultSessionStatus = {
    'session0': true,
    'session1': true,
    'session2': false,
    'session3': false,
    'session4': false,
    'session5': false,
    'session6': false,
    'session7': false,
    'session8': false,
  };
}
