import 'package:shared_preferences/shared_preferences.dart';

class ActivityAutoAdvanceSettingsService {
  static const String _enabledKey = 'activity.autoAdvance.enabled';

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (_) {
      // Best-effort: a preferencia nao deve quebrar a tela.
    }
  }
}
