import '../../domain/repositories/pdf_viewer_repository.dart';
import '../datasources/pdf_progress_firestore_datasource.dart';
import '../datasources/pdf_storage_download_datasource.dart';

class PdfViewerRepositoryImpl implements PdfViewerRepository {
  PdfViewerRepositoryImpl({
    required PdfStorageDownloadDataSource downloadDataSource,
    required PdfProgressFirestoreDataSource progressDataSource,
  })  : _downloadDataSource = downloadDataSource,
        _progressDataSource = progressDataSource;

  final PdfStorageDownloadDataSource _downloadDataSource;
  final PdfProgressFirestoreDataSource _progressDataSource;

  @override
  Future<String> downloadPdfToLocalPath({required String pdfPath}) {
    return _downloadDataSource.downloadPdfToLocalPath(pdfPath: pdfPath);
  }

  @override
  Future<void> markPdfViewed({
    required String userId,
    required String fieldPath,
  }) {
    return _progressDataSource.markPdfViewed(
      userId: userId,
      fieldPath: fieldPath,
    );
  }
}
