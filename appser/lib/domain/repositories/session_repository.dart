import '../entities/session_status.dart';

abstract class SessionRepository {
  Future<SessionStatus> fetchCurrentUserSessionStatus();
}
