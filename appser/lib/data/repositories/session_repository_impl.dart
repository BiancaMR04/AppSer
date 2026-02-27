import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/session_defaults.dart';
import '../../domain/entities/session_status.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/user_sessions_firestore_datasource.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirebaseAuth _auth;
  final UserSessionsFirestoreDataSource _firestoreDataSource;

  SessionRepositoryImpl({
    required FirebaseAuth auth,
    required UserSessionsFirestoreDataSource firestoreDataSource,
  })  : _auth = auth,
        _firestoreDataSource = firestoreDataSource;

  @override
  Future<SessionStatus> fetchCurrentUserSessionStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const SessionStatus(SessionDefaults.defaultSessionStatus);
    }

    final map = await _firestoreDataSource.fetchSessionStatus(userId: uid);
    return SessionStatus(map);
  }
}
