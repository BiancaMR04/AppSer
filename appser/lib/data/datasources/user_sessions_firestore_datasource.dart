import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/constants/session_defaults.dart';

class UserSessionsFirestoreDataSource {
  final FirebaseFirestore _firestore;

  UserSessionsFirestoreDataSource(this._firestore);

  Future<Map<String, bool>> fetchSessionStatus({required String userId}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await _firestore
            .collection(FirestorePaths.usersCollection)
            .doc(userId)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        userDoc = await _firestore
            .collection(FirestorePaths.usersCollection)
            .doc(userId)
            .get();
      }

      if (!userDoc.exists) {
        return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
      }

      final data = userDoc.data();
      if (data == null) {
        return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
      }

      bool readBool(String key, bool defaultValue) {
        final value = data[key];
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          if (normalized == 'true') return true;
          if (normalized == 'false') return false;
          if (normalized == '1') return true;
          if (normalized == '0') return false;
        }
        return defaultValue;
      }

      DateTime? parseDate(dynamic raw) {
        if (raw is Timestamp) return raw.toDate();
        if (raw is DateTime) return raw;
        if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
        if (raw is String) return DateTime.tryParse(raw);
        return null;
      }

      final baseDate =
          parseDate(data['dataInicio']) ?? parseDate(data['createdAt']);

      int? daysSinceStart;
      if (baseDate != null) {
        // Regra por dia do calendário (meia-noite), sem depender de horário.
        final now = DateTime.now();
        final baseLocal = baseDate.toLocal();
        final today = DateTime(now.year, now.month, now.day);
        final baseDay = DateTime(baseLocal.year, baseLocal.month, baseLocal.day);
        daysSinceStart = today.difference(baseDay).inDays;
      }

      final status = <String, bool>{
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

      if (daysSinceStart != null && daysSinceStart < 0) {
        for (var sessionIndex = 0;
            sessionIndex < SessionDefaults.totalSessions;
            sessionIndex++) {
          status['session$sessionIndex'] = false;
        }
        return status;
      }

      // Auto-unlock: Sessão 2 após 7 dias, Sessão 3 após 14, etc.
      // Não depende de conseguir escrever no Firestore.
      if (daysSinceStart != null) {
        for (var sessionIndex = 0;
            sessionIndex < SessionDefaults.totalSessions;
            sessionIndex++) {
          final key = 'session$sessionIndex';
          final requiredDays = sessionIndex <= 1 ? 0 : (sessionIndex - 1) * 7;
          if (daysSinceStart >= requiredDays) {
            status[key] = true;
          }
        }
      }

      return status;
    } catch (_) {
      return Map<String, bool>.from(SessionDefaults.defaultSessionStatus);
    }
  }
}
