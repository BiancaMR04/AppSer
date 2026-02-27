import 'package:appser/domain/repositories/superuser_report_repository.dart';
import 'package:appser/services/authetication_service.dart';
import 'package:share_plus/share_plus.dart';

class SuperuserController {
  SuperuserController({
    required SuperuserReportRepository reportRepository,
    required AutheticationService authService,
  })  : _reportRepository = reportRepository,
        _authService = authService;

  final SuperuserReportRepository _reportRepository;
  final AutheticationService _authService;

  Future<List<Map<String, dynamic>>> buscarUsuarios() {
    return _reportRepository.fetchUsersWithSessions();
  }

  Future<String> exportarParaExcel() async {
    final path = await _reportRepository.exportReportToExcelFilePath(
      fileName: 'relatorio_mbrp.xlsx',
    );
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Relatório MBRP em Excel',
    );
    return path;
  }

  Future<String> exportarParaCsv() async {
    final path = await _reportRepository.exportReportToCsvFilePath(
      fileName: 'relatorio_mbrp.csv',
    );
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Relatório MBRP (CSV)',
    );
    return path;
  }

  Future<void> logout() => _authService.logout();
}
