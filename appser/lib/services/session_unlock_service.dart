import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/constants/session_defaults.dart';

class SessionUnlockService {
  SessionUnlockService(this._firestore);

  final FirebaseFirestore _firestore;

  bool _coerceBool(dynamic value, bool defaultValue) {
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

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> ensureSessionUnlocks({required String uid}) async {
    try {
      final userRef =
          _firestore.collection(FirestorePaths.usersCollection).doc(uid);

      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await userRef.get(const GetOptions(source: Source.server));
      } catch (_) {
        snap = await userRef.get();
      }
      if (!snap.exists) return;

      final data = snap.data();
      if (data == null) return;

      // Regra: desbloqueio por tempo desde o cadastro/início.
      // Preferimos createdAt; se não existir, usamos dataInicio.
      final base = _parseDate(data['createdAt']) ?? _parseDate(data['dataInicio']);
      if (base == null) return;

      // Considera apenas dia do calendário (meia-noite), para não depender do horário.
      final now = DateTime.now();
      final baseLocal = base.toLocal();
      final today = DateTime(now.year, now.month, now.day);
      final baseDay = DateTime(baseLocal.year, baseLocal.month, baseLocal.day);
      final rawDaysSince = today.difference(baseDay).inDays;
      final daysSince = rawDaysSince < 0 ? 0 : rawDaysSince;

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
        final current = _coerceBool(
          data[key],
          SessionDefaults.defaultSessionStatus[key] ?? false,
        );

        if (shouldUnlockSession(sessionIndex) && current != true) {
          updates[key] = true;
        }
      }

      if (updates.isEmpty) return;

      updates['sessionsLastAutoUnlockAt'] = FieldValue.serverTimestamp();

      // `update` garante que nunca cria um doc novo de usuário.
      await userRef.update(updates);
    } catch (_) {
      // Best-effort: não derruba a UI se Firestore falhar.
      return;
    }
  }
}
