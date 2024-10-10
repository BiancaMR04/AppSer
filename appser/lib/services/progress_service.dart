import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _firstSessionStartKey = 'firstSessionStart';

  // Função para salvar a data da primeira sessão
  Future<void> setFirstSessionStartDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_firstSessionStartKey) == null) {
      // Só salva a data da primeira sessão se ainda não foi salva
      await prefs.setString(_firstSessionStartKey, DateTime.now().toIso8601String());
    }
  }

  // Função para obter a data da primeira sessão
  Future<DateTime?> getFirstSessionStartDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString(_firstSessionStartKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }
}
