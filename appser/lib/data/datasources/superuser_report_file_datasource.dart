import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SuperuserReportFileDataSource {
  Future<String> writeBytesToDocuments({
    required String fileName,
    required List<int> bytes,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }
}
