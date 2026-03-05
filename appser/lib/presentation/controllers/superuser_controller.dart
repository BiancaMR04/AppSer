import 'package:appser/domain/repositories/superuser_report_repository.dart';
import 'package:appser/services/authetication_service.dart';

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
    return _reportRepository.exportReportToExcelFilePath(
      fileName: 'relatorio_mbrp.xlsx',
    );
  }

  Future<String> exportarParaCsv() async {
    return _reportRepository.exportReportToCsvFilePath(
      fileName: 'relatorio_mbrp.csv',
    );
  }

  Future<void> logout() => _authService.logout();
}
