import '../../core/constants/session_defaults.dart';
import '../../domain/repositories/session_repository.dart';

class HomeController {
  final SessionRepository _sessionRepository;

  HomeController({required SessionRepository sessionRepository})
      : _sessionRepository = sessionRepository;

  Future<Map<String, bool>> fetchSessionStatus() async {
    final status = await _sessionRepository.fetchCurrentUserSessionStatus();
    // Garante que ninguém muta o map interno.
    final map = status.toMap();

    // Salvaguarda: se por algum motivo vier vazio, mantém default.
    if (map.isEmpty) {
      return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
    }

    return map;
  }
}
