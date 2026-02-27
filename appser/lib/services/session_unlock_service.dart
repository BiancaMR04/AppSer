import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/constants/session_defaults.dart';

class SessionUnlockService {
  SessionUnlockService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> ensureSessionUnlocks({required String uid}) async {
    final userRef = _firestore.collection(FirestorePaths.usersCollection).doc(uid);

    final snap = await userRef.get();
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null) return;

    final createdAtRaw = data['createdAt'];
    if (createdAtRaw == null) {
      await userRef.set(
        {'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return;
    }

    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    }

    if (createdAt == null) return;

    final daysSince = DateTime.now().difference(createdAt).inDays;

    bool shouldUnlockSession(int sessionIndex) {
      if (sessionIndex <= 1) return true;
      final requiredDays = (sessionIndex - 1) * 7;
      return daysSince >= requiredDays;
    }

    final Map<String, dynamic> updates = {};

    for (var sessionIndex = 0;
        sessionIndex < SessionDefaults.totalSessions;
        sessionIndex++) {
      final key = 'session$sessionIndex';
      final current = (data[key] as bool?) ??
          (SessionDefaults.defaultSessionStatus[key] ?? false);

      if (shouldUnlockSession(sessionIndex) && current != true) {
        updates[key] = true;
      }
    }

    if (updates.isEmpty) return;

    updates['sessionsLastAutoUnlockAt'] = FieldValue.serverTimestamp();

    await userRef.set(
      updates,
      SetOptions(merge: true),
    );
  }
}
