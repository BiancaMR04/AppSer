import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/constants/session_defaults.dart';

class UserSessionsFirestoreDataSource {
  final FirebaseFirestore _firestore;

  UserSessionsFirestoreDataSource(this._firestore);

  Future<Map<String, bool>> fetchSessionStatus({required String userId}) async {
    try {
      final userDoc = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
      }

      bool readBool(String key, bool defaultValue) {
        // Mantém o comportamento atual: se o campo não existir ou o tipo for inválido,
        // o acesso/cast vai lançar e cair no catch, retornando o status padrão.
        return (userDoc[key] as bool?) ?? defaultValue;
      }

      return {
        'session0': readBool('session0', true),
        'session1': readBool('session1', true),
        'session2': readBool('session2', false),
        'session3': readBool('session3', false),
        'session4': readBool('session4', false),
        'session5': readBool('session5', false),
        'session6': readBool('session6', false),
        'session7': readBool('session7', false),
        'session8': readBool('session8', false),
      };
    } catch (_) {
      return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
    }
  }
}
