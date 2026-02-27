import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfStorageDownloadDataSource {
  PdfStorageDownloadDataSource(this._storage);

  final FirebaseStorage _storage;

  Future<String> downloadPdfToLocalPath({required String pdfPath}) async {
    final ref = _storage.ref(pdfPath);
    final url = await ref.getDownloadURL();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/temp.pdf');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }

    throw Exception('Erro no download do PDF');
  }
}
