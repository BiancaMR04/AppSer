abstract class PdfViewerRepository {
  Future<String> downloadPdfToLocalPath({required String pdfPath});

  Future<void> markPdfViewed({
    required String userId,
    required String fieldPath,
  });
}
