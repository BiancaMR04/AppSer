import 'package:firebase_storage/firebase_storage.dart';

import '../../resources/docs/app_pdf_cache_manager.dart';

class PdfStorageDownloadDataSource {
  PdfStorageDownloadDataSource(this._storage);

  final FirebaseStorage _storage;

  Future<String> downloadPdfToLocalPath({required String pdfPath}) async {
    final ref = _storage.ref(pdfPath);
    final url = await ref.getDownloadURL();
    final file = await AppPdfCacheManager.instance.getPdfFile(
      pdfUrl: url,
      pdfPath: pdfPath,
    );
    return file.path;
  }
}
