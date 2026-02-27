import 'package:excel/excel.dart';

class SuperuserReportExcelDataSource {
  /// Gera um arquivo Excel com base nas linhas já formatadas.
  ///
  /// Cada linha deve ser uma lista de [CellValue] (ex.: [TextCellValue]).
  List<int> buildExcelBytes({
    required String sheetName,
    required List<List<CellValue>> rows,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    for (final row in rows) {
      sheet.appendRow(row);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Erro ao gerar o arquivo Excel');
    }
    return bytes;
  }
}
