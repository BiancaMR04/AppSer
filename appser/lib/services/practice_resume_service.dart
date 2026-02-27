import 'package:shared_preferences/shared_preferences.dart';

class PracticeResumeService {
  static const String _sessionNumberKey = 'practice.resume.sessionNumber';
  static const String _itemIdKey = 'practice.resume.itemId';

  static Future<void> setTarget({
    required int sessionNumber,
    required String itemId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionNumberKey, sessionNumber);
      await prefs.setString(_itemIdKey, itemId);
    } catch (_) {
      // Best-effort: não quebra a navegação.
    }
  }

  static Future<({int sessionNumber, String itemId})?> loadTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionNumber = prefs.getInt(_sessionNumberKey);
      final itemId = prefs.getString(_itemIdKey);
      if (sessionNumber == null || itemId == null || itemId.trim().isEmpty) {
        return null;
      }
      return (sessionNumber: sessionNumber, itemId: itemId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionNumberKey);
      await prefs.remove(_itemIdKey);
    } catch (_) {
      // noop
    }
  }
}
