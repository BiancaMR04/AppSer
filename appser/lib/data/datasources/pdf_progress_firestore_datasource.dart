import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';

class PdfProgressFirestoreDataSource {
  PdfProgressFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> markPdfViewed({
    required String userId,
    required String fieldPath,
  }) {
    return _firestore
        .collection(FirestorePaths.progressCollection)
        .doc(userId)
        .update({fieldPath: true});
  }
}
