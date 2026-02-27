abstract interface class SuperuserReportRepository {
  Future<List<Map<String, dynamic>>> fetchUsersWithSessions();

  /// Gera o relatório CSV (com novos campos/eventos) e devolve o caminho absoluto do arquivo.
  Future<String> exportReportToCsvFilePath({
    required String fileName,
  });

  /// Gera o relatório Excel e devolve o caminho absoluto do arquivo.
  Future<String> exportReportToExcelFilePath({
    required String fileName,
  });
}
