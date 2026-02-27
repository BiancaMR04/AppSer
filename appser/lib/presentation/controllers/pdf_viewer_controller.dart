import '../../domain/repositories/pdf_viewer_repository.dart';

class PdfViewerController {
  PdfViewerController({required PdfViewerRepository repository})
      : _repository = repository;

  final PdfViewerRepository _repository;

  Future<String> downloadPdfToLocalPath({required String pdfPath}) {
    return _repository.downloadPdfToLocalPath(pdfPath: pdfPath);
  }

  Future<void> markPdfViewed({
    required String userId,
    required String fieldPath,
  }) {
    return _repository.markPdfViewed(userId: userId, fieldPath: fieldPath);
  }
}
